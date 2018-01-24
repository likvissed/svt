module Warehouse
  class Order < BaseWarehouse
    self.primary_key = :warehouse_order_id
    self.table_name = "#{table_name_prefix}orders"

    has_many :operations, as: :operationable, dependent: :destroy
    has_many :item_to_orders, dependent: :destroy
    has_many :inv_items, through: :item_to_orders, class_name: 'Invent::Item'
    has_many :items, through: :operations

    belongs_to :workplace, class_name: 'Invent::Workplace', optional: true
    belongs_to :creator, foreign_key: 'creator_id_tn', class_name: 'UserIss', optional: true
    belongs_to :consumer, foreign_key: 'consumer_id_tn', class_name: 'UserIss', optional: true
    belongs_to :validator, foreign_key: 'validator_id_tn', class_name: 'UserIss', optional: true

    validates :operation, :status, :creator_fio, :consumer_dept, presence: true
    validates :validator_fio, presence: true, if: -> { status == 'done' && operation == 'out' }
    validate :presence_consumer, if: -> { operations.any?(&:done?) }
    validate :at_least_one_operation
    validate :compare_nested_attrs, if: -> { item_to_orders.any? }
    validate :uniqueness_of_workplace, if: -> { item_to_orders.any? }
    validate :compare_consumer_dept, if: -> { item_to_orders.any? && errors.empty? }

    after_initialize :set_initial_status, if: -> { new_record? }
    before_validation :set_consumer, if: -> { consumer_tn.present? || consumer_fio.present? }
    before_validation :set_closed_time, if: -> { done? && status_changed? }
    after_validation :set_workplace, if: -> { errors.empty? && item_to_orders.any? }
    before_save :calculate_status
    before_update :prevent_update

    enum operation: { out: 1, in: 2 }
    enum status: { processing: 1, done: 2 }

    accepts_nested_attributes_for :operations, allow_destroy: true
    accepts_nested_attributes_for :item_to_orders, allow_destroy: true

    attr_accessor :consumer_tn

    def set_creator(user)
      self.creator_id_tn = user.id_tn
      self.creator_fio = user.fullname
    end

    def operations_to_string
      operations.map { |op| "#{op.item_type}: #{op.item_model}" }.join('; ')
    end

    def done?
      status == 'done'
    end

    protected

    def presence_consumer
      return if consumer_fio.present?

      errors.add(:consumer, :blank)
    end

    def at_least_one_operation
      return if operations.any?

      errors.add(:base, :at_least_one_operation)
    end

    def set_initial_status
      self.status ||= :processing
    end

    def calculate_status
      self.status = operations.any?(&:processing?) ? :processing : :done
    end

    def set_consumer
      if consumer_fio_changed? && !consumer_fio_changed?(from: nil, to: '')
        user = UserIss.find_by(fio: consumer_fio)
        if user
          self.consumer = user
        else
          errors.add(:consumer, :user_by_fio_not_found)
        end
      elsif consumer_tn
        user = UserIss.find_by(tn: consumer_tn)
        if user
          self.consumer_fio = user.fio
          self.consumer = user
        else
          errors.add(:consumer, :user_by_tn_not_found)
        end
      end
    end

    def set_closed_time
      self.closed_time = Time.zone.now
    end

    def set_workplace
      self.workplace_id = item_to_orders.first.inv_item.workplace_id
    end

    def compare_nested_attrs
      return if operations.size == item_to_orders.size

      errors.add(:base, :nested_arrs_not_equals)
    end

    def uniqueness_of_workplace
      item_id_arr = item_to_orders.map(&:invent_item_id)
      count_workplaces = Invent::Item.select(:item_id, :workplace_id).find(item_id_arr).uniq(&:workplace_id).length
      return if count_workplaces.zero? || count_workplaces == 1

      errors.add(:base, :uniq_workplace)
    end

    def compare_consumer_dept
      item_id = item_to_orders.first.invent_item_id
      division = Invent::Item.select(:item_id, :workplace_id).find(item_id).workplace.try(:workplace_count).try(:division)
      return if !division || division == consumer_dept

      errors.add(:base, :dept_does_not_match)
    end

    def prevent_update
      return true unless done? && !status_changed? || processing? && status_was == 'done'

      errors.add(:base, :cannot_update_done_order)
    end
  end
end

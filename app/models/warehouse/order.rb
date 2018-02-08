module Warehouse
  class Order < BaseWarehouse
    self.primary_key = :warehouse_order_id
    self.table_name = "#{table_name_prefix}orders"

    has_many :operations, as: :operationable, dependent: :destroy, inverse_of: :operationable
    has_many :item_to_orders, dependent: :destroy
    has_many :inv_items, through: :item_to_orders, class_name: 'Invent::Item'
    has_many :items, through: :operations

    belongs_to :workplace, class_name: 'Invent::Workplace', optional: true
    belongs_to :creator, foreign_key: 'creator_id_tn', class_name: 'UserIss', optional: true
    belongs_to :consumer, foreign_key: 'consumer_id_tn', class_name: 'UserIss', optional: true
    belongs_to :validator, foreign_key: 'validator_id_tn', class_name: 'UserIss', optional: true

    validates :operation, :status, :creator_fio, presence: true
    validates :consumer_dept, presence: true, if: -> { operation == 'in' }
    validates :validator_fio, presence: true, if: -> { done? && operation == 'out' }
    validates :workplace_id, presence: true, if: -> { operation == 'out' }
    validate :presence_consumer, if: -> { operations.any?(&:done?) }
    validate :at_least_one_operation
    validate :validate_in_order, if: -> { operation == 'in' }

    after_initialize :set_initial_status, if: -> { new_record? }
    before_validation :set_consumer, if: -> { consumer_tn.present? || consumer_fio.present? }
    before_validation :set_closed_time, if: -> { done? && status_changed? }
    before_validation :set_workplace, if: -> { errors.empty? && item_to_orders.any? && new_record? && operation == 'in' }
    before_validation :set_consumer_dept, if: -> { operation == 'out' }
    before_save :calculate_status
    before_update :prevent_update_done_order
    before_update :prevent_update_attributes
    before_destroy :prevent_destroy, prepend: true

    enum operation: { out: 1, in: 2 }
    enum status: { processing: 1, done: 2 }

    accepts_nested_attributes_for :operations, allow_destroy: true
    accepts_nested_attributes_for :item_to_orders, allow_destroy: true
    accepts_nested_attributes_for :inv_items, allow_destroy: false

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
      return if operations.any? { |op| !op._destroy }

      if workplace.present?
        errors.add(:base, :at_least_one_operation_for_workplace, workplace_id: workplace.workplace_id)
      else
        errors.add(:base, :at_least_one_operation)
      end
    end

    def validate_in_order
      presence_consumer if operations.any?(&:done?)
      check_operation_list
      uniqueness_of_workplace if item_to_orders.any?
      compare_consumer_dept if item_to_orders.any? && errors.empty?
      # Эта валидация должна быть самой последней
      compare_nested_arrs if item_to_orders.any? && errors.empty?
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

    def set_consumer_dept
      return unless workplace

      self.consumer_dept = workplace.workplace_count.division
    end

    def check_operation_list
      if workplace
        errors.add(:base, :cannot_have_operations_without_invent_num) if operations.any? { |op| !op.invent_item_id }
      else
        errors.add(:base, :cannot_have_operations_with_invent_num) if operations.any?(&:invent_item_id)
      end
    end

    def compare_nested_arrs
      return if operations.size == item_to_orders.size

      errors.add(:base, :nested_arrs_not_equals)
    end

    # Проверяет, чтобы техника ордера относилась только к одному рабочему месту
    def uniqueness_of_workplace
      item_id_arr = item_to_orders.map(&:invent_item_id)
      count_workplaces = Invent::Item.select(:item_id, :workplace_id).find(item_id_arr).map(&:workplace_id).uniq.compact.length
      return if count_workplaces.zero? || count_workplaces == 1

      errors.add(:base, :uniq_workplace)
    end

    # Сравнивает, чтобы вся техника была с одного отдела (указанного в поле consumer_dept)
    def compare_consumer_dept
      item_id = item_to_orders.first.invent_item_id
      division = Invent::Item.select(:item_id, :workplace_id).find(item_id).workplace.try(:workplace_count).try(:division)
      return if !division || division == consumer_dept

      errors.add(:base, :dept_does_not_match)
    end

    def prevent_update_done_order
      return true unless done? && !status_changed? || processing? && status_was == 'done'

      errors.add(:base, :cannot_update_done_order)
      throw(:abort)
    end

    def prevent_update_attributes
      errors.add(:workplace, :cannot_update) if workplace_id_changed?
      errors.add(:operation, :cannot_update) if operation_changed?
      errors.add(:consumer_dept, :cannot_update) if consumer_dept_changed?

      throw(:abort) if errors.any?
    end

    def prevent_destroy
      if done?
        errors.add(:base, :cannot_destroy_done)
        throw(:abort)
      elsif operations.any?(&:done?)
        errors.add(:base, :cannot_destroy_with_done_operations)
        throw(:abort)
      end
    end
  end
end

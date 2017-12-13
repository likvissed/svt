module Warehouse
  class Order < BaseWarehouse
    self.primary_key = :warehouse_order_id
    self.table_name = "#{table_name_prefix}orders"

    has_many :operations, as: :operationable, dependent: :destroy
    has_many :item_to_orders, dependent: :destroy
    has_many :inv_items, through: :item_to_orders, class_name: 'Invent::Item'

    belongs_to :workplace, class_name: 'Invent::Workplace', optional: true
    belongs_to :creator, foreign_key: 'creator_id_tn', class_name: 'UserIss', optional: true
    belongs_to :consumer, foreign_key: 'consumer_id_tn', class_name: 'UserIss', optional: true
    belongs_to :validator, foreign_key: 'validator_id_tn', class_name: 'UserIss', optional: true

    validates :consumer_dept, :consumer, presence: true
    validate :uniqueness_of_workplace
    validate :at_least_one_inv_item

    after_initialize :set_initial_status
    after_validation :set_workplace, unless: -> { errors.any? }

    enum operation: { out: 1, in: 2 }
    enum status: { processing: 1, done: 2 }

    accepts_nested_attributes_for :operations, allow_destroy: true
    accepts_nested_attributes_for :item_to_orders, allow_destroy: true

    def set_creator(current_user)
      self.creator_id_tn = current_user.id_tn
      self.creator_fio = current_user.fullname
    end

    protected

    def uniqueness_of_workplace
      item_id_arr = item_to_orders.map(&:invent_item_id)
      count_workplaces = Invent::Item.select(:item_id, :workplace_id).find(item_id_arr).uniq(&:workplace_id).length
      return if count_workplaces.zero? || count_workplaces == 1

      errors.add(:base, :uniq_workplace)
    end

    def at_least_one_inv_item
      return if item_to_orders.any?

      errors.add(:base, :at_least_one_inv_item)
    end

    def set_initial_status
      self.status = :processing
    end

    def set_workplace
      self.workplace_id = item_to_orders.first.inv_item.workplace_id
    end
  end
end

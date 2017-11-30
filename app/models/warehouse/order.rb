module Warehouse
  class Order < BaseWarehouse
    self.primary_key = :warehouse_order_id
    self.table_name = "#{table_name_prefix}orders"

    has_many :operations, as: :operationable, dependent: :destroy
    has_many :item_to_orders, dependent: :destroy
    has_many :items, through: :item_to_orders, class_name: 'Invent::Item'

    belongs_to :workplace, class_name: 'Invent::Workplace'
    belongs_to :creator, foreign_key: 'creator_id_tn', class_name: 'UserIss'
    belongs_to :consumer, foreign_key: 'consumer_id_tn', class_name: 'UserIss'
    belongs_to :validator, foreign_key: 'validator_id_tn', class_name: 'UserIss'
  end
end

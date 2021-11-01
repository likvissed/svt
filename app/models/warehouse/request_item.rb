module Warehouse
  class RequestItem < BaseWarehouse
    self.primary_key = :id
    self.table_name = "#{table_name_prefix}request_items"

    belongs_to :request, foreign_key: 'request_id', optional: true, inverse_of: :request_items
  end
end

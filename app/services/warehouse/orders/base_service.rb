module Warehouse
  module Orders
    class BaseService < ApplicationService
      def broadcast_orders
        ActionCable.server.broadcast 'orders', nil
      end
    end
  end
end
  
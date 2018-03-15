module Warehouse
  class OutOrdersChannel < ApplicationCable::Channel
    def subscribed
      stream_from 'out_orders'
    end
  end
end

module Warehouse
  class InOrdersChannel < ApplicationCable::Channel
    def subscribed
      stream_from 'in_orders'
    end
  end
end

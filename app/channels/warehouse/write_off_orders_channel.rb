module Warehouse
  class WriteOffOrdersChannel < ApplicationCable::Channel
    def subscribed
      stream_from 'write_off_orders'
    end
  end
end

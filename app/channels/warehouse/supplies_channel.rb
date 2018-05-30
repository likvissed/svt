module Warehouse
  class SuppliesChannel < ApplicationCable::Channel
    def subscribed
      stream_from 'supplies'
    end
  end
end

module Warehouse
  class ItemsChannel < ApplicationCable::Channel
    def subscribed
      stream_from 'items'
    end
  end
end

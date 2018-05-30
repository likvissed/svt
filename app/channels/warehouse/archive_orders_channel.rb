module Warehouse
  class ArchiveOrdersChannel < ApplicationCable::Channel
    def subscribed
      stream_from 'archive_orders'
    end
  end
end

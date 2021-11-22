module Warehouse
  class RequestsChannel < ApplicationCable::Channel
    def subscribed
      stream_from 'requests'
    end
  end
end

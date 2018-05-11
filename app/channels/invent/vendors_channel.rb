module Invent
  class VendorsChannel < ApplicationCable::Channel
    def subscribed
      stream_from 'vendors'
    end
  end
end

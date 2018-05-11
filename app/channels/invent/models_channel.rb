module Invent
  class ModelsChannel < ApplicationCable::Channel
    def subscribed
      stream_from 'models'
    end
  end
end

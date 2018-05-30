module Invent
  class WorkplacesChannel < ApplicationCable::Channel
    def subscribed
      stream_from 'workplaces'
    end
  end
end

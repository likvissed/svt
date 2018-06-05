module Invent
  class WorkplacesListChannel < ApplicationCable::Channel
    def subscribed
      stream_from 'workplaces_list'
    end
  end
end

class WorkplaceListChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'workplace_list'
  end
end
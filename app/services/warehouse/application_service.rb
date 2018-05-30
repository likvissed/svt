class Warehouse::ApplicationService < ApplicationService
  protected

  def broadcast_items(id = nil, type = nil)
    ActionCable.server.broadcast 'items', id
  end

  def broadcast_supplies
    ActionCable.server.broadcast 'supplies', nil
  end
end

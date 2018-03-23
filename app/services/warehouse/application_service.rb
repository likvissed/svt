class Warehouse::ApplicationService < ApplicationService
  protected

  def broadcast_items
    ActionCable.server.broadcast 'items', nil
  end

  def broadcast_supplies
    ActionCable.server.broadcast 'supplies', nil
  end
end

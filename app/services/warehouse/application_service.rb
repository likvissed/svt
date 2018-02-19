class Warehouse::ApplicationService < ApplicationService
  protected

  def broadcast_items
    ActionCable.server.broadcast 'items', nil
  end
end

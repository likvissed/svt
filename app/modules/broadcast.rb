module Broadcast
  def broadcast_archive_orders
    ActionCable.server.broadcast 'archive_orders', nil
  end

  def broadcast_in_orders
    ActionCable.server.broadcast 'in_orders', nil
  end

  def broadcast_items(id = nil, _type = nil)
    ActionCable.server.broadcast 'items', id
  end

  def broadcast_models
    ActionCable.server.broadcast 'models', nil
  end

  def broadcast_out_orders
    ActionCable.server.broadcast 'out_orders', nil
  end

  def broadcast_supplies
    ActionCable.server.broadcast 'supplies', nil
  end

  def broadcast_users
    ActionCable.server.broadcast 'users', nil
  end

  def broadcast_vendors
    ActionCable.server.broadcast 'vendors', nil
  end

  def broadcast_workplaces
    ActionCable.server.broadcast 'workplaces', nil
  end

  def broadcast_workplaces_list
    ActionCable.server.broadcast 'workplaces_list', nil
  end
end

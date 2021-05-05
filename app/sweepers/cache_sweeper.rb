class CacheSweeper < ActionController::Caching::Sweeper
  observe Invent::Workplace, Invent::Item, Warehouse::Item, Invent::Model

  def after_save(_record)
    expire_cache
  end

  def after_destroy(_record)
    expire_cache
  end

  private

  def expire_cache
    Rails.cache.delete_matched('views*')
  end
end

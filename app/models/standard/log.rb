module  Standard
  class Log < BaseStandard
    belongs_to :item, class_name: 'Invent::Item', foreign_key: 'item_id'

    enum event: { add: 0, change: 1, approve: 2 }
  end
end

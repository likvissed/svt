module  Standart
  class Log < BaseStandart
    belongs_to :inv_item, class_name: 'Invent::InvItem', foreign_key: 'item_id'
    belongs_to :user

    enum event: { add: 0, change: 1, approve: 2 }
  end
end

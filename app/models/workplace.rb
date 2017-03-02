class Workplace < Netadmin
  self.primary_key  = :workplace_id
  self.table_name   = :invent_workplace

  has_many    :inv_items
  belongs_to  :workplace_type
  belongs_to  :workplace_count
  belongs_to  :user_iss, foreign_key: 'id_tn', optional: true

  validates :id_tn, presence: true, numericality: { greater_than: 0, only_integer: true }

  accepts_nested_attributes_for :inv_items, allow_destroy: true, reject_if: proc { |attr| attr['type_id'].blank? }

  enum status: { 'Утверждено': 0, 'В ожидании проверки': 1, 'Отклонено': 2 }

end

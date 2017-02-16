class Workplace < Netadmin
  self.primary_key  = :workplace_id
  self.table_name   = :invent_workplace

  has_many    :inv_items
  belongs_to  :workplace_type
  belongs_to  :count_workplace
  belongs_to  :user_iss, foreign_key: 'id_tn', optional: true

  # validates :id_tn, presence: true, numericality: { greater_than: 0, only_integer: true }

  enum status: { 'Утверждено': 0, 'В ожидании проверки': 1, 'Отклонено': 2 }
end

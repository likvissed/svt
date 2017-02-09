class Workplace < Netadmin
  self.primary_key = :workplace_id
  self.table_name = :invent_workplace

  enum status: { 'Утверждено': 0, 'В ожидании проверки': 1, 'Отклонено': 2 }
end

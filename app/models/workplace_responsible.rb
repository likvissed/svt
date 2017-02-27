class WorkplaceResponsible < Netadmin
  self.table_name   = :invent_workplace_responsible
  self.primary_key  = :workplace_responsible_id

  belongs_to :workplace_count, inverse_of: :workplace_responsibles
  belongs_to :user_iss, foreign_key: 'id_tn', optional: true

  attr_accessor :tn
end
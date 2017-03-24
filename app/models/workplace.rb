class Workplace < Netadmin
  self.primary_key  = :workplace_id
  self.table_name   = :invent_workplace

  has_many    :inv_items
  belongs_to  :workplace_type
  belongs_to  :workplace_specialization
  belongs_to  :workplace_count
  belongs_to  :user_iss, foreign_key: 'id_tn', optional: true

  validates :id_tn, presence: true, numericality: { greater_than: 0, only_integer: true, message: 'не выбран' }
  validates :workplace_count_id, presence: true, numericality: { greater_than: 0, only_integer: true, message: 'не
указан' }
  validates :workplace_type_id, presence: true, numericality: { greater_than: 0, only_integer: true, message: 'не
выбран' }
  validates :workplace_specialization_id, presence: true, numericality: { greater_than: 0, only_integer: true,
message: 'не выбрано' }
  validates :location, presence: true
  validate  :at_least_one_pc
  validate  :compare_responsibles

  accepts_nested_attributes_for :inv_items, allow_destroy: true, reject_if: proc { |attr| attr['type_id'].to_i.zero? }

  enum status: { 'Утверждено': 0, 'В ожидании проверки': 1, 'Отклонено': 2 }

  # Удалить РМ, связанные экземпляры техники, значения их свойств, а также загруженные файлы.
  def destroy_from_***REMOVED***
    Workplace.transaction do
      begin
        self.destroy if self.inv_items.destroy_all
      rescue ActiveRecord::RecordNotDestroyed => e
        self.errors.add(:base, 'Не удалось удалить запись. Обратитесь к администратору.')
        raise ActiveRecord::Rollback
      end
    end
  end

  private

  # Проверка на наличие системного блока.
  def at_least_one_pc
    type_count = 0
    get_type
    inv_items.each { |item| type_count += 1 if item.type_id == @type.type_id }

    errors.add(:base, 'На одном рабочем месте может находиться только один системный блок.') if type_count > 1
    errors.add(:base, 'Необходимо создать системный блок') if type_count.zero?
  end

  # Проверка, совпадает табельный номер ответственного за РМ с ответственным за системный блок.
  def compare_responsibles
    get_type

    inv_items.each do |item|
      if item.type_id == @type.type_id
        # Получаем данные о системном блоке
        @host = HostIss.get_host(item.invent_num)
        if @host
          begin
            @user = UserIss.find(self.id_tn)

            errors.add(:base, 'Табельный номер ответственного за рабочее место не совпадает с табельным номер
ответственного за системный блок.') unless @host['tn'] == @user.tn
          rescue ActiveRecord::RecordNotFound
            errors.add(:id_tn, 'не найден в базе данных отдела кадров, обратитесь к администратору')
          end
        end

        break
      end
    end
  end

  # Создать переменную @type, если она не существует.
  def get_type
    @type = InvType.find_by(name: 'pc') unless @type
  end
end

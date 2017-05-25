module Inventory
  # Класс определяет, существует ли комната в указанном корпусе. Если нет - создает комнату.
  # name - номер комнаты
  # building_id - id корпуса
  class Room
    include ActiveModel::Validations

    attr_reader :data

    validate :building_exist?

    define_model_callbacks :run

    before_run :run_validations

    def initialize(name, building_id)
      @name = name
      @building_id = building_id
    end

    def run
      run_callbacks(:run) do
        create_room unless room

        true
      end
    rescue RuntimeError
      false
    end

    private

    def run_validations
      raise 'abort' unless valid?
    end

    # Проверка наличия указанного корпуса
    def building_exist?
      return if IssReferenceBuilding.where(building_id: @building_id).exists?

      raise 'abort'
    end

    # Определяем, существует ли комната.
    def room
      @data = IssReferenceRoom
                .where(name: @name)
                .where(building_id: @building_id)
                .first

      !@data.nil?
    end

    def create_room
      @data = IssReferenceRoom.create(building_id: @building_id, name: @name)
    end
  end
end

module Invent
  # Класс определяет, существует ли комната в указанном корпусе. Если нет - создает комнату.
  # name - номер комнаты
  # building_id - id корпуса
  class Room < ApplicationService
    attr_reader :data

    validate :building_exist?

    define_model_callbacks :run

    before_run :run_validations

    def initialize(name, building_id, room_category_id)
      @name = name
      @building_id = building_id
      @room_category_id = room_category_id
    end

    def run
      run_callbacks(:run) do
        create_room unless room
        change_room_category

        true
      end
    rescue RuntimeError => e
      Rails.logger.error e.inspect.red
      Rails.logger.error e.backtrace[0..5].inspect

      false
    end

    private

    def run_validations
      raise 'abort' unless valid?
    end

    # Проверка наличия указанного корпуса
    def building_exist?
      return if IssReferenceBuilding.where(building_id: @building_id).exists?

      raise "Площадка с ID #{@building_id} не найдена"
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
      @data = IssReferenceRoom.create(building_id: @building_id, name: @name, room_security_category: RoomSecurityCategory.find_by(category: 'Отсутствует'))
    end

    def change_room_category
      @data.update(security_category_id: @room_category_id)
    end
  end
end

module Inventory
  # Класс определяет, существует ли комната в указанном корпусе. Если нет - создаем комнату
  # name - номер комнаты
  # building_id - id корпуса
  class Room
    attr_reader :building_id, :data

    def initialize(name, building_id)
      @name = name
      @building_id = building_id
    end

    def run
      create_room unless room

      true
    rescue Exception => e
      Rails.logger.info e.inspect
      Rails.logger.info e.backtrace.inspect

      false
    end

    private

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

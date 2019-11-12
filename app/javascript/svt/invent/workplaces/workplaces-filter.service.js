import { app } from '../../app/app';

(function () {
  'use strict';

  app.service('WorkplacesFilter', WorkplacesFilter);

  WorkplacesFilter.$inject = ['Server', 'Error'];

  function WorkplacesFilter(Server, Error) {
    this.Server = Server;
    this.Error = Error;
    this.filters = {
      // флаг указывает, инициализированы ли фильтры
      init    : false,
      statuses: { '': 'Все статусы' },
      types   : [
        {
          workplace_type_id: '',
          short_description: 'Все типы'
        }
      ]
    };
    this.selectedTableFilters = {
      invent_num       : '',
      workplace_id     : '',
      workplace_type_id: this.filters.types[0].workplace_type_id,
      division         : '',
      status           : '',
      fullname         : '',
      building         : '',
      room             : ''
    };
  }

  /**
   * Заполнить фильтры данными.
   */
  WorkplacesFilter.prototype.set = function(data) {
    this.filters.divisions = data.divisions;
    Object.assign(this.filters.statuses, data.statuses);
    this.filters.types = this.filters.types.concat(data.types);
    this.filters.buildings = data.buildings;
    this.filters.init = true;
  };

  /**
   * Получить выбранные фильтры.
   */
  WorkplacesFilter.prototype.get = function() {
    let obj = angular.copy(this.selectedTableFilters);

    obj.workplace_count_id = obj.division.workplace_count_id;
    obj.location_building_id = obj.building.building_id;
    obj.location_room_id = obj.room.room_id;

    delete(obj.division);
    delete(obj.building);
    delete(obj.room);

    return obj;
  };

  /**
   * Загрузить комнаты выбранного корпуса.
   */
  WorkplacesFilter.prototype.loadRooms = function() {
    this.clearRooms();
    this.Server.Location.rooms(
      { building_id: this.selectedTableFilters.building.building_id },
      (data) => this.filters.rooms = data,
      (response, status) => this.Error.response(response, status)
    );
  };

  /**
   * Очистить список комнат.
   */
  WorkplacesFilter.prototype.clearRooms = function() {
    delete(this.filters.rooms);
  };
})();

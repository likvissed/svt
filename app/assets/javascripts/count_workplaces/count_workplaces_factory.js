(function () {
  'use strict';

  app
    .service('CountWorkplace', CountWorkplace);

  CountWorkplace.$inject = ['Server', 'Error'];

  /**
   * Сервис для создания/редактирования количества рабочих мест (РМ) отделов.
   *
   * @class Inv.CountWorkplace
   */
  function CountWorkplace(Server, Error) {
    this.Server   = Server;
    this.Error    = Error;

    // Шаблон данных
    this._templateValue = {
      count_workplace_id: null,
      division:           '',
      count_wp:           '',
      tn:                 '',
      phone:              '',
      time_start:         '',
      time_end:           ''
    };

    this._data = {
      method: 'POST',
      value: {}
    }
  }

  /**
   * Создать пустой объект-отдел.
   */
  CountWorkplace.prototype.newDivision = function () {
    this._data.method = 'POST';
    this._data.value  = angular.copy(this._templateValue);

    return this._data;
  };

  /**
   * Загрузить данные указанного отдела.
   *
   * @param id - id отдела в БД.
   */
  CountWorkplace.prototype.getDivision = function (id) {
    var self = this;

    return this.Server.CountWorkplace.get({ count_workplace_id: id }).$promise.then(function (data) {
      self._data.method           = 'PATCH';
      self._data.value            = angular.copy(data);
      self._data.value.time_start = new Date(angular.copy(data.time_start));
      self._data.value.time_end   = new Date(angular.copy(data.time_end));

      return self._data;
    });
  };

  /**
   * Очистить данные об отделе с РМ
   */
  CountWorkplace.prototype.clearData = function () {
    this._data.value = angular.copy(this._templateValue);
  };
})();
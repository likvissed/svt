app
  .service('WorkplaceCount', WorkplaceCount);

WorkplaceCount.$inject = ['Server', 'Error'];

/**
 * Сервис для управления доступом к созданию/редактированию РМ через ЛК.
 *
 * @class SVT.WorkplaceCount
 */
function WorkplaceCount(Server, Error) {
  this.Server = Server;
  this.Error = Error;

  // Шаблон данных
  this._templateValue = {
    workplace_count_id: null,
    division: '',
    time_start: '',
    time_end: '',
    users_attributes: []
  };

  // Шаблон объекта ответсвенного
  this._template_users_attributes = {
    id: null,
    tn: '',
    phone: ''
  };

  this._data = {
    method: 'POST',
    value: {}
  }
}

/**
 * Создать пустой объект-отдел.
 */
WorkplaceCount.prototype.newDivision = function () {
  this._data.method = 'POST';
  this._data.value = angular.copy(this._templateValue);

  return this._data;
};

/**
 * Загрузить данные указанного отдела.
 *
 * @param id - id отдела в БД.
 */
WorkplaceCount.prototype.getDivision = function (id) {
  var self = this;

  return this.Server.WorkplaceCount.get({ workplace_count_id: id }).$promise.then(function (data) {
    self._data.method = 'PUT';
    self._data.value = angular.copy(data);
    self._data.value.time_start = new Date(angular.copy(data.time_start));
    self._data.value.time_end = new Date(angular.copy(data.time_end));

    return self._data;
  });
};

/**
 * Очистить данные об отделе с РМ.
 */
WorkplaceCount.prototype.clearData = function () {
  this._data.value = angular.copy(this._templateValue);
};

/**
 * Добавить ответственного.
 */
WorkplaceCount.prototype.addResponsible = function () {
  this._data.value.users_attributes.push(angular.copy(this._template_users_attributes));
};

/**
 * Удалить ответственного.
 *
 * @param obj - удаляемый объект.
 */
WorkplaceCount.prototype.delResponsible = function (obj) {
  if (obj.id)
    obj._destroy = 1;
  else
    this._data.value.users_attributes.splice($.inArray(obj, this._data.value.users_attributes), 1);
};
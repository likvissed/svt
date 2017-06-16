app
  .service('Workplace', Workplace);

Workplace.$inject = ['$window', '$http', 'Server', 'Error', 'Item'];

/**
 * Сервис для редактирования(подтверждения или отклонения) РМ.
 *
 * @class SVT.Workplace
 */
function Workplace($window, $http, Server, Error, Item) {
  this.$window = $window;
  this.$http = $http;
  this.Server = Server;
  this.Error = Error;
  this.Item = Item;

  // ====================================== Данные с сервера =============================================================

  // Типы РМ
  this.wp_types = [{ workplace_type_id: -1, long_description: 'Выберите тип' }];
  // Направления работы на рабочих местах
  this.specs = [{ workplace_specialization_id: -1, short_description: 'Выберите вид' }];
  // Типы оборудования на РМ с необходимыми для заполнения свойствами
  this.eq_types = [{ type_id: -1, short_description: 'Выберите тип' }];
  // Список отделов, прикрепленных к пользователю
  this.divisions = [];
  // Список площадок и корпусов
  this.iss_locations = [{ site_id: -1, name: 'Выберите площадку' }];

// ====================================== Данные, которые отправяются на сервер ========================================

  // Копия объекта this.workplace, который отправится на сервер.
  this.workplaceCopy = null;

// ====================================== Шаблоны данных ===============================================================

  // Шаблон данных выбранного отдела
  this._templateDivision = {
    // Объект выбранного отдела массива this.divisions
    selected: null,
    // Список работников отдела
    users: [],
    //{ id_tn: -1, fio: 'Выберите ФИО' }
    // Список рабочих мест выбранного отдела
    workplaces: []
  };
  // Шаблон данных о рабочем месте (новом или редактируемом)
  this._templateWorkplace = {
    workplace_id: 0,
    // Id в таблице отделов
    workplace_count_id: 0,
    // Тип РМ
    workplace_type_id: -1,
    // Объект - тип РМ
    workplace_type: angular.copy(this.wp_types[0]),
    // Вид выполняемой работы
    workplace_specialization_id: -1,
    // Ответственный за РМ
    id_tn: '',
    // Площадка
    location_site_id: -1,
    // Объект - площадка
    location_site: angular.copy(this.iss_locations[0]),
    // Корпус
    location_building_id: -1,
    // Комната
    location_room_name: '',
    // Дефолтный статус РМ (2 - в ожидании проверки)
    status: 'pending_verification',
    // Состав РМ
    inv_items_attributes: []
  };

// =====================================================================================================================
}

/**
 * Добавить объекты, связанные с выбранным типом оборудования, моделями и т.д. (обратная операция _clearBeforeSend).
 */
Workplace.prototype._addObjects = function () {
  var self = this;

  // Находим объект с workplace_type_id
  this.workplace.workplace_type = $.grep(angular.copy(this.wp_types), function (el) {
    return self.workplace.workplace_type_id == el.workplace_type_id;
  })[0];

  this.workplace.location_site = $.grep(angular.copy(this.iss_locations), function (el) {
    return self.workplace.location_site_id == el.site_id;
  })[0];

  angular.forEach(this.workplace.inv_items_attributes, function (item) { self.Item.addProperties(item); })
};

/**
 * Очистить копию массива workplace от справочных данных для отправления на сервер.
 */
Workplace.prototype._delObjects = function () {
  var self = this;
  this.workplaceCopy = angular.copy(this.workplace);

  delete(this.workplaceCopy.workplace_type);
  delete(this.workplaceCopy.location_site);

  angular.forEach(this.workplaceCopy.inv_items_attributes, function (item) { self.Item.delProperties(item); });
};

/**
 * Получить данные о РМ.
 */
Workplace.prototype.init = function (id) {
  var self = this;

  return this.$http
    .get('/inventory/workplaces/' + id + '/edit.json')
    .success(function (data) {
      self.workplace = angular.copy(data.wp_data);

      angular.forEach(data.prop_data.iss_locations, function (value) {
        value.iss_reference_buildings = [{ building_id: -1, name: 'Выберите корпус' }].concat(value.iss_reference_buildings);
      });
      self.Item.setTypes(data.prop_data.eq_types);
      self.wp_types = angular.copy(self.wp_types.concat(data.prop_data.wp_types));
      self.specs = angular.copy(self.specs.concat(data.prop_data.specs));
      self.iss_locations = angular.copy(self.iss_locations.concat(data.prop_data.iss_locations));
      self.users = angular.copy(data.prop_data.users);
      self.statuses = angular.copy(data.prop_data.statuses);

      self._addObjects();
    })
    .error(function (response, status) {
      self.Error.response(response, status);
    });
};

/**
 * Установить начальное значение для корпуса при изменении площадки.
 *
 * @param type - Тип очищения: если building - очистить корпус и комнату, иначе - только комнату.
 */
Workplace.prototype.setDefaultLocation = function (type) {
  if (type == 'building')
    this.workplace.location_building_id = -1;

  this.workplace.location_room_name = '';
};

/**
 * Запросить скрипт для генерации отчета о конфигурации ПК.
 */
Workplace.prototype.downloadPcScript = function () {
  this.$window.open('/inventory/workplaces/pc_script', '_blank');
};

/**
 * Получить данные от системы Аудит по указанному инвентарному номеру.
 *
 * @param item
 */
Workplace.prototype.getAuditData = function (item) {
  var self = this;

  this.$http
    .get('/inventory/workplaces/pc_config_from_audit/' + item.invent_num)
    .success(function (data) {
      self.Item.setPcProperties(item, data);
    })
    .error(function (response, status) {
      self.Error.response(response, status);
    });
};

/**
 * Сохранить данные о РМ на сервере.
 */
Workplace.prototype.saveWorkplace = function () {
  var self = this;
  // this._clearBeforeSend();
  this._delObjects();

  var formData = new FormData();

  // Данные о создаваемом РМ
  formData.append('workplace', angular.toJson(this.workplaceCopy));
  // Прикрепленный файл, показывающий состав системного блока
  formData.append('pc_file', this.Item.getPcFile());

  if (this.workplaceCopy.workplace_id) {
    this.Server.Workplace.update(
      { workplace_id: self.workplace.workplace_id },
      formData,
      function success(response) {
        console.log('success');
        console.log(response);
      },
      function error(response) {
        console.log('error');
        console.log(response);
        self.Flash.alert(response);
      }
    );


    // return this.$http
    //   .put('/inventory/workplaces/' + this.workplace.workplace_id + '.json',
    //     formData,
    //     {
    //       headers: { 'Content-Type': undefined },
    //       transformRequest: angular.identity
    //     }
    //   )
    //   .success(function (response) {
    //     console.log('success');
    //     console.log(response);
    //   })
    //   .error(function (response) {
    //     console.log('error');
    //     console.log(response);
    //   })
  } else {
    // return this.$http
    //   .post(this._host + 'create_workplace',
    //     formData,
    //     {
    //       headers: { 'Content-Type': undefined },
    //       transformRequest: angular.identity
    //     }
    //   )
    //   .success(function (response) {
    //     self.getDivision('workplaces').push(response.workplace);
    //
    //     if (response.full_message)
    //       self.$dialogs.notify(response.full_message);
    //   })
    //   .error(function (response) {
    //     self.$dialogs.error(response.full_message);
    //   })
  }
};

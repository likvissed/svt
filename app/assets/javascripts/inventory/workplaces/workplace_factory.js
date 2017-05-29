app
  .service('Workplace', Workplace);

Workplace.$inject = ['$http', 'Server', 'Error'];

/**
 * Сервис для редактирования(подтверждения или отклонения) РМ.
 *
 * @class SVT.Workplace
 */
function Workplace($http, Server, Error) {
  this.$http = $http;
  this.Server = Server;
  this.Error = Error;

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
  // Файл конфигурации ПК, связанный с текущим РМ.
  this.pcFile = null;

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
  // Шаблон экземпляра техники, добавляемого к РМ
  this._templateItem = {
    id:             null,
    // item_id: null,
    type_id: 0,
    workplace_id: 0,
    location: '',
    invent_num: '',
    model_id: 0,
    item_model: '',
    inv_property_values_attributes: [],
    // По умолчанию показать пользователю "Выберите тип"
    type: this.eq_types[0],
    // Выбранная модель
    model: null
  };
  // Шаблон объекта значения свойства выбранного экземпляра техники
  this._templatePropertyValue = {
    id: null,
    property_id: 0,
    item_id: 0,
    property_list_id: 0,
    value: '',
    // Массив возможных значений отфильтрованных по модели и свойству
    filteredList: []
  };
  //
  this._templateSelectModel = [
    { model_id: -1, item_model: 'Выберите модель' },
    { model_id: 0, item_model: 'Ввести модель вручную...' }
  ];
  this._templateSelectProp = [
    // Для строки "Выберите тип"
    { property_list_id: -1, short_description: ''},
    // Для строки "Ввести вручную..."
    { property_list_id: 0, short_description: ''}
  ];

// =====================================================================================================================
}

Workplace.prototype._addBeforeEdit = function () {
  var
    self = this,
    // Наличие в списке оборудования системного блока, моноблока, ноутбука (true если существует)
    changeAuditData = false;

  // Находим объект с workplace_type_id
  this.workplace.workplace_type = $.grep(angular.copy(this.wp_types), function (el) {
    return self.workplace.workplace_type_id == el.workplace_type_id
  })[0];

  this.workplace.location_site = $.grep(angular.copy(this.iss_locations), function (el) {
    return self.workplace.location_site_id == el.site_id
  })[0];

  $.each(this.workplace.inv_items_attributes, function (item_index, item_val) {
    var self_item = this;

    // Проходим по массиву eq_types, сравнивая type_id.
    $.each(self.eq_types, function (eq_index, eq_value) {
      if (item_val.type_id == eq_value.type_id) {
        self_item.type = angular.copy(eq_value);

        // Если длина массивов inv_property_values_attributes и inv_properties отличается, значит текущий
        // экземпляр техники имеет несколько значений для некоторых свойств (например, несколько жестких
        // дисков для системного блока). Необходимо создать копии соответсвующих элементов массива
        // inv_properties и поместить их в этот же массив. Иначе пользователь увидит, например, только один
        // жесткий диск.
        if (self_item.inv_property_values_attributes.length != self_item.type.inv_properties.length) {

        }
      }
    });
  });
};

Workplace.prototype.init = function (id) {
  var self = this;

  return this.$http
    .get('/inventory/workplaces/' + id + '/edit.json')
    .success(function (data) {
      self.workplace = angular.copy(data.wp_data);

      $.each(data.prop_data.iss_locations, function (index, value) {
        this.iss_reference_buildings = [{ building_id: -1, name: 'Выберите корпус' }].concat(this.iss_reference_buildings);
      });
      self.eq_types = angular.copy(self.eq_types.concat(data.prop_data.eq_types));
      self.wp_types = angular.copy(self.wp_types.concat(data.prop_data.wp_types));
      self.specs = angular.copy(self.specs.concat(data.prop_data.specs));
      self.iss_locations = angular.copy(self.iss_locations.concat(data.prop_data.iss_locations));
      self.users = angular.copy(data.prop_data.users);

      self._addBeforeEdit();
    })
    .error(function (response, status) {
      self.Error.response(response, status);
    });
};


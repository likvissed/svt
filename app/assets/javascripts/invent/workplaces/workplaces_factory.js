(function () {
  'use strict';

  app
    .service('Workplace', Workplace);

  Workplace.$inject = ['$window', '$http', '$timeout', 'Server', 'Flash', 'Error', 'Item', 'PropertyValue'];

  /**
   * Сервис для редактирования(подтверждения или отклонения) РМ.
   *
   * @class SVT.Workplace
   */
  function Workplace($window, $http, $timeout, Server, Flash, Error, Item, PropertyValue) {
    this.$window = $window;
    this.$http = $http;
    this.$timeout = $timeout;
    this.Server = Server;
    this.Flash = Flash;
    this.Error = Error;
    this.Item = Item;
    this.PropertyValue = PropertyValue;

    // ====================================== Данные с сервера =============================================================

    // Поле select, предлагающее выбрать тип оборудования
    this.selectWpType = { workplace_type_id: -1, long_description: 'Выберите тип' };
    // Поле select, предлагающее выбрать вид деятельности
    this.selectWpSpec = { workplace_specialization_id: -1, short_description: 'Выберите вид' };
    // Список отделов
    this.divisions = [];
    // Поле select, предлагающее выбрать площадку
    this.selectIssLocation = { site_id: -1, name: 'Выберите площадку' };
    // Поле select, предлагающее выбрать корпус
    this.selectIssBuilding = { building_id: -1, name: 'Выберите корпус' };

// ====================================== Данные, которые отправяются на сервер ========================================

    // Копия объекта this.workplace, который отправится на сервер.
    this.workplaceCopy = null;

// ====================================== Шаблоны данных ===============================================================

    // Шаблон данных о рабочем месте (новом или редактируемом)
    this._templateWorkplace = {
      // Показывает, нужно ли при создании/редактировании РМ использовать проверки на состав РМ
      enabled_filters: true,
      workplace_id: 0,
      // Id в таблице отделов
      workplace_count_id: 0,
      // Тип РМ
      workplace_type_id: this.selectWpType.workplace_type_id,
      // Объект - тип РМ
      workplace_type: this.selectWpType,
      // Вид выполняемой работы
      workplace_specialization_id: this.selectWpSpec.workplace_specialization_id,
      // Ответственный за РМ
      id_tn: '',
      // Площадка
      location_site_id: this.selectIssLocation.site_id,
      // Объект - площадка
      location_site: this.selectIssLocation,
      // Корпус
      location_building_id: this.selectIssBuilding.building_id,
      // Комната
      location_room_name: '',
      // Дефолтный статус РМ (2 - в ожидании проверки)
      status: 'pending_verification',
      // Состав РМ
      inv_items_attributes: []
    };

// =====================================================================================================================

    this.additional = this.Item.getAdditional();
  }

  /**
   * Добавить объекты, связанные с выбранным типом оборудования, моделями и т.д. (обратная операция _clearBeforeSend).
   */
  Workplace.prototype._addObjects = function () {
    var self = this;

    // Находим объект с workplace_type_id
    this.workplace.workplace_type = this.wp_types.find(function (el) {
      return self.workplace.workplace_type_id == el.workplace_type_id;
    });

    this.workplace.location_site = this.iss_locations.find(function (el) {
      return self.workplace.location_site_id == el.site_id;
    });

    angular.forEach(this.workplace.inv_items_attributes, function (item) { self.Item.addProperties(item); });
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
   * Добавить шаблон оборудования к РМ.
   */
  Workplace.prototype._addNewItem = function () {
    this.workplace.inv_items_attributes.push(this.Item.getTemplateItem());
    this.additional.visibleCount ++;
  };

  /**
   * Установить новый активный экземпляр техники в табах.
   */
  Workplace.prototype._setFirstActiveTab = function () {
    var
      self = this,
      visibleArr = [];

    visibleArr = this.workplace.inv_items_attributes.filter(function (el) { if (!el._destroy) return true; });
    this.$timeout(function () {
      self.additional.activeTab = self.workplace.inv_items_attributes.indexOf(visibleArr[0]);
    }, 0);
  };

  /**
   * Установка параметров, полученных с сервера.
   *
   * @param data - полученные с сервера данные
   */
  Workplace.prototype._setProperties = function (data) {
    var self = this;

    // По умолчанию фильтры всегда включены
    this.workplace.enabled_filters = true;

    angular.forEach(data.prop_data.iss_locations, function (value) {
      value.iss_reference_buildings = [self.selectIssBuilding].concat(value.iss_reference_buildings);
    });
    this.Item.setTypes(data.prop_data.eq_types);

    // Типы РМ
    this.wp_types = [self.selectWpType].concat(data.prop_data.wp_types);
    // Направления работы на рабочих местах
    this.specs = [self.selectWpSpec].concat(data.prop_data.specs);
    // Список площадок и корпусов
    this.iss_locations = [self.selectIssLocation].concat(data.prop_data.iss_locations);

    this.statuses = data.prop_data.statuses;
    this.divisions = data.divisions;

    this.additional.fileKey = parseInt(data.prop_data.pc_config_key);
    this.additional.pcAttrs = angular.copy(data.prop_data.file_depending);
    this.additional.singleItems = angular.copy(data.prop_data.single_pc_items);
    this.additional.pcTypes = angular.copy(data.prop_data.type_with_files);
    this.additional.secretExceptions = angular.copy(data.prop_data.secret_exceptions);
  };

  /**
   * Получить данные о РМ.
   */
  Workplace.prototype.init = function (id) {
    var self = this;

    if (id) {
      return this.Server.Invent.Workplace.edit({ id: id },
        function (data) {
          self.workplace = angular.copy(data.wp_data);
          self.users = data.prop_data.users;

          self._setProperties(data);
          self._addObjects();

          self.workplace.division = self.divisions.find(function (el) {
            if (el.workplace_count_id == self.workplace.workplace_count_id) { return true; }
          });
        }, function (response, status) {
          self.Error.response(response, status);
        }).$promise;
    } else {
      return this.Server.Invent.Workplace.new(
        function (data) {
          self.workplace = angular.copy(self._templateWorkplace);
          self.users = [];

          self._setProperties(data);

          self.workplace.division = angular.copy(self.divisions[0]);
        }, function (response, status) {
          self.Error.response(response, status);
        }).$promise;
    }
  };

  /**
   * Загрузить список работников отдела.
   */
  Workplace.prototype.loadUsers = function () {
    var self = this;

    if (!this.workplace.division)
      return false;

    this.workplace.workplace_count_id = this.workplace.division.workplace_count_id;

    return this.Server.UserIss.usersFromDivision(
      { division: this.workplace.division.division },
      function (data) {
        self.users = angular.copy(data);
      },
      function (response, status) {
        self.Error.response(response, status);
      }).$promise;
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
    this.$window.open('/invent/workplaces/pc_script', '_blank');
  };

  /**
   * Получить данные от системы Аудит по указанному инвентарному номеру.
   *
   * @param item
   */
  Workplace.prototype.getAuditData = function (item) {
    var self = this;

    this.Server.Invent.Workplace.pcConfigFromAudit(
      { invent_num: item.invent_num },
      function (data) {
        self.Item.setPcProperties(item, data);
      },
      function (response, status) {
        self.Error.response(response, status);
      });
  };

  /**
   * Отправить файл на сервер для расшифровки. Возвращает расшифрованные данные в виде строки.
   *
   * @param file - загружаемый файл
   */
  Workplace.prototype.matchUploadFile = function (file) {
    var
      self = this,
      formData = new FormData();

    formData.append('pc_file', file);



    return this.$http
      .post('/invent/workplaces/pc_config_from_user/',
        formData,
        {
          headers: { 'Content-Type': undefined },
          transformRequest: angular.identity
        }
      )
      .success(function (response) {})
      .error(function (response, status) {
        self.Error.response(response, status);
      })
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
      this.Server.Invent.Workplace.update(
        { workplace_id: self.workplace.workplace_id },
        formData,
        function success(response) {
          self.$window.location.href = response.location;
        },
        function error(response, status) {
          self.Error.response(response, status);
        });
    } else {
      this.Server.Invent.Workplace.save(formData,
        function (response) {
          self.$window.location.href = response.location;
        },
        function (response, status) {
          self.Error.response(response, status);
        });
    }
  };

  /**
   * Создать новое оборудования, установить начальные значения для данного типа.
   */
  Workplace.prototype.createItem = function (selectedType) {
    var self = this;

    // Создать шаблон нового оборудования на рабочем месте для заполнения данными.
    self._addNewItem();

    var
      // Получаем индекс созданного элемента
      length = self.workplace.inv_items_attributes.length - 1,
      // Созданный элемент
      item = self.workplace.inv_items_attributes[length];

    self.workplace.inv_items_attributes[length].type = angular.copy(selectedType);
    self.Item.setItemDefaultMetadata(item);

    if (item.type_id != 0) {
      // Установить метаданные для модели
      self.Item.setModelDefaultMetadata(item, 'new');

      // Заполнить начальными данными массив inv_property_values_attributes.
      angular.forEach(item.type.inv_properties, function (prop_value, prop_index) {
        self.Item.addNewPropertyValue(item);
        self.PropertyValue.setPropertyValue(item, prop_index, 'property_id', prop_value.property_id);
        self.Item.createFilteredList(item, prop_index, prop_value);
        self.Item.setInitPropertyListId(item, prop_index);
      });
    }

    // Сделать созданный элемент активным в табах.
    self.$timeout(function () {
      self.additional.activeTab = length;
    }, 0);
  };

  /**
   * Удалить элемент из массива inv_items_attributes.
   *
   * @param item - удаляемый элемент
   */
  Workplace.prototype.delItem = function (item) {
    // Если удаляется ПК и т.п., очистить параметры объекта additional
    if (this.Item.pcValidationPassed(item.type.name)) {
      this.Item.clearPcAdditionalData(item);
    }

    if (item.id) {
      item._destroy = 1;
      item.workplace_id = null;

      this.setFirstActiveTab(item);
    } else {
      this.setFirstActiveTab(item);
      this.workplace.inv_items_attributes.splice($.inArray(item, this.workplace.inv_items_attributes), 1);
      this.Item.clearPcMetadata(item);
    }

    this.additional.visibleCount --;
  };

  /**
   * Установить новый активный экземпляр техники в табах взависимости от удаляемого элемента. Если удаляется активный
   * элемент - установить активным самый первый элемент, не помеченный флагом _destroy.
   *
   * @param item - удаляемый экземпляр техники (необязательный параметр). Если задан - то новый активный элемент будет
   * установлен только в том случае, если удаляется активный экземпляр техники.
   */
  Workplace.prototype.setFirstActiveTab = function (item) {
    if (item) {
      if (this.workplace.inv_items_attributes.indexOf(item) == this.additional.activeTab) {
        this._setFirstActiveTab();
      }
    } else {
      this._setFirstActiveTab();
    }
  };

  /**
   * Проверка различных условий для текущего типа оборудования. Например, для одного РМ возможно наличие только
   * одного системного блока.
   *
   * @param type - объект-тип оборудования.
   */
  Workplace.prototype.validateType = function (type) {
    var self = this;

    // Проверка, выбрал ли пользователь тип
    if (type.type_id == -1) {
      this.Flash.alert('Необходимо выбрать тип создаваемого устройства.');

      return false;
    }

    if (self.Item.typeValidationPassed(type.name)) {
      var countPc = 0;

      // Считаем количество СБ/моноблоков/ноутбуков на текущем РМ.
      $.each(this.workplace.inv_items_attributes, function (index, value) {
        if (self.Item.typeValidationPassed(value.type.name) && !value._destroy)
          countPc ++;
      });

      if (countPc >= 1) {
        this.Flash.alert('Одно рабочее место может содержать только один из указанных видов техники: системный блок, моноблок, ноутбук, планшет.');

        return false;
      }
    }

    return true;
  };
})();

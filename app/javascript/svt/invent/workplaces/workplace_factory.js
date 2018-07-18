(function() {
  'use strict';

  app
    .service('Workplace', Workplace);

  Workplace.$inject = ['$window', '$http', '$timeout', 'Server', 'Flash', 'Error', 'WorkplaceItem', 'PropertyValue'];

  /**
   * Сервис для редактирования(подтверждения или отклонения) РМ.
   *
   * @class SVT.Workplace
   */
  function Workplace($window, $http, $timeout, Server, Flash, Error, WorkplaceItem, PropertyValue) {
    this.$window = $window;
    this.$http = $http;
    this.$timeout = $timeout;
    this.Server = Server;
    this.Flash = Flash;
    this.Error = Error;
    this.Item = WorkplaceItem;
    this.PropertyValue = PropertyValue;

    // Поле select, предлагающее выбрать тип оборудования
    this.selectWpType = { workplace_type_id: null, long_description: 'Выберите тип' };
    // Поле select, предлагающее выбрать вид деятельности
    this.selectWpSpec = { workplace_specialization_id: null, short_description: 'Выберите вид' };
    // Список отделов
    this.divisions = [];
    // Поле select, предлагающее выбрать площадку
    this.selectIssLocation = { site_id: null, name: 'Выберите площадку' };
    // Поле select, предлагающее выбрать корпус
    this.selectIssBuilding = { building_id: null, name: 'Выберите корпус' };
    // Копия объекта this.workplace, который отправится на сервер.
    this.workplaceCopy = null;
    this.additional = this.Item.getAdditional();
  }

  /**
   * Добавить объекты, связанные с выбранным типом оборудования, моделями и т.д. (обратная операция _delObjects).
   */
  Workplace.prototype._addObjects = function() {
    // Находим объект с workplace_type_id
    this.workplace.workplace_type = this.wp_types.find((el) => {
      return this.workplace.workplace_type_id == el.workplace_type_id;
    });

    this.workplace.location_site = this.iss_locations.find((el) => {
      return this.workplace.location_site_id == el.site_id;
    });

    this.workplace.items_attributes.forEach((item) => this.Item.addProperties(item));
  };

  /**
   * Очистить копию массива workplace от справочных данных для отправления на сервер.
   */
  Workplace.prototype._delObjects = function() {
    this.workplaceCopy = angular.copy(this.workplace);

    delete(this.workplaceCopy.workplace_type);
    delete(this.workplaceCopy.location_site);
    delete(this.workplaceCopy.division);

    this.workplaceCopy.items_attributes.forEach((item) => this.Item.delProperties(item));
  };

  /**
   * Добавить шаблон оборудования к РМ.
   */
  Workplace.prototype._addItemTemplate = function() {
    this.workplace.items_attributes.push(this.Item.getTemplateItem());
  };

  /**
   * Установить новый активный экземпляр техники в табах.
   *
   * @param index - индекс таба (от 0)
   */
  Workplace.prototype._setActiveTab = function(index) {
    this.$timeout(() => this.additional.activeTab = index, 0);
  };

  /**
   * Установка параметров, полученных с сервера.
   *
   * @param data - полученные с сервера данные
   */
  Workplace.prototype._setProperties = function(data) {
    // По умолчанию фильтры всегда включены
    this.workplace.disabled_filters = false;

    data.prop_data.iss_locations.forEach((value) => value.iss_reference_buildings.unshift(this.selectIssBuilding));
    this.Item.setTypes(data.prop_data.eq_types);

    // Типы РМ
    this.wp_types = [this.selectWpType].concat(data.prop_data.wp_types);
    // Направления работы на рабочих местах
    this.specs = [this.selectWpSpec].concat(data.prop_data.specs);
    // Список площадок и корпусов
    this.iss_locations = [this.selectIssLocation].concat(data.prop_data.iss_locations);

    this.statuses = data.prop_data.statuses;
    this.divisions = data.prop_data.divisions;

    this.additional.pcAttrs = data.prop_data.file_depending;
    this.additional.singleItems = data.prop_data.single_pc_items;
    this.additional.pcTypes = data.prop_data.type_with_files;
    this.additional.secretExceptions = data.prop_data.secret_exceptions;
  };

  /**
   * Установить шаблоны объектов техники и свойств техники.
   */
  Workplace.prototype._setTemplates = function(data) {
    this.Item.setTemplate(data.item);
    this.PropertyValue.setTemplate(data.property_value);
  };

  /**
   * Получить данные о РМ.
   */
  Workplace.prototype.init = function(id) {
    if (id) {
      return this.Server.Invent.Workplace.edit({ id: id },
        (data) => {
          this.workplace = data.wp_data;
          this.users = data.prop_data.users;

          this._setProperties(data);
          this._addObjects();
          this._setTemplates(data);

          this.workplace.division = this.divisions.find((el) => {
            if (el.workplace_count_id == this.workplace.workplace_count_id) { return true; }
          });
        }, (response, status) => {
          this.Error.response(response, status);
        }).$promise;
    } else {
      return this.Server.Invent.Workplace.new(
        (data) => {
          this.workplace = data.workplace;
          this.users = [];

          this._setProperties(data);
          this._addObjects();
          this._setTemplates(data);

          this.workplace.division = this.divisions[0];
        }, (response, status) => {
          this.Error.response(response, status);
        }).$promise;
    }
  };

  /**
   * Загрузить список работников отдела.
   */
  Workplace.prototype.loadUsers = function() {
    if (!this.workplace.division) { return false; }

    this.workplace.workplace_count_id = this.workplace.division.workplace_count_id;

    return this.Server.UserIss.usersFromDivision(
      { division: this.workplace.division.division },
      (data) => this.users = angular.copy(data),
      (response, status) => this.Error.response(response, status)
    ).$promise;
  };

  /**
   * Установить начальное значение для корпуса при изменении площадки.
   *
   * @param type - Тип очищения: если building - очистить корпус и комнату, иначе - только комнату.
   */
  Workplace.prototype.setDefaultLocation = function(type) {
    if (type == 'building') {
      this.workplace.location_building_id = null;
    }

    this.workplace.location_room_name = '';
  };

  /**
   * Запросить скрипт для генерации отчета о конфигурации ПК.
   */
  Workplace.prototype.downloadPcScript = function() {
    this.$window.open('/invent/workplaces/pc_script', '_blank');
  };

  /**
   * Получить данные от системы Аудит по указанному инвентарному номеру.
   *
   * @param item
   */
  Workplace.prototype.getAuditData = function(item) {
    this.Server.Invent.Workplace.pcConfigFromAudit(
      { invent_num: item.invent_num },
      (data) => this.Item.setPcProperties(item, data),
      (response, status) => this.Error.response(response, status)
    );
  };

  /**
   * Отправить файл на сервер для расшифровки. Возвращает расшифрованные данные в виде строки.
   *
   * @param file - загружаемый файл
   */
  Workplace.prototype.matchUploadFile = function(file) {
    let formData = new FormData();

    formData.append('pc_file', file);

    return this.Server.Invent.Workplace.pcConfigFromUser(
      formData,
      (response) => {},
      (response, status) => this.Error.response(response, status)
    ).$promise;
  };

  /**
   * Сохранить данные о РМ на сервере.
   */
  Workplace.prototype.saveWorkplace = function() {
    this._delObjects();

    if (this.workplaceCopy.workplace_id) {
      this.Server.Invent.Workplace.update(
        { workplace_id: this.workplace.workplace_id },
        { workplace: this.workplaceCopy },
        (response) => this.$window.location.href = response.location,
        (response, status) => this.Error.response(response, status)
      );
    } else {
      this.Server.Invent.Workplace.save(
        { workplace: this.workplaceCopy },
        (response) => this.$window.location.href = response.location,
        (response, status) => this.Error.response(response, status)
      );
    }
  };

  /**
   * Удалить РМ
   */
  Workplace.prototype.destroyWorkplace = function() {
    this.Server.Invent.Workplace.hardDelete(
      { workplace_id: this.workplace.workplace_id },
      (response) => this.$window.location.href = response.location,
      (response, status) => this.Error.response(response, status)
    );
  }

  /**
   * Создать новое оборудования, установить начальные значения для данного типа.
   *
   * @param selectedType - тип создаваемого устройства
   */
  Workplace.prototype.createItem = function(selectedType) {
    this._addItemTemplate();

    let
      // Получаем индекс созданного элемента
      length = this.workplace.items_attributes.length - 1,
      // Созданный элемент
      item = this.workplace.items_attributes[length];

    this.Item.setType(item, selectedType);

    if (item.type_id != 0) {
      this.Item.setModel(item);

      // Заполнить начальными данными массив property_values_attributes.
      item.type.properties.forEach((prop_value, prop_index) => {
        this.Item.addNewPropertyValue(item);
        this.PropertyValue.setPropertyValue(item, prop_index, 'property_id', prop_value.property_id);
        this.Item.createFilteredList(item, prop_index, prop_value);
        this.Item.setInitPropertyListId(item, prop_index);
      });
    }

    // Сделать созданный элемент активным в табах.
    this._setActiveTab(length);
  };

  /**
   * Добавить существующее оборудование к РМ.
   *
   * @param selectedItem - выбранное оборудование
   */
  Workplace.prototype.addExistingItem = function(selectedItem) {
    this.Server.Invent.Item.edit(
      { item_id: selectedItem.item_id },
      (response) => {
        this._addItemTemplate();

        let
          // Получаем индекс созданного элемента
          length = this.workplace.items_attributes.length - 1,
          // Созданный элемент
          item = this.workplace.items_attributes[length];

        this.Item.addProperties(response);
        this.Item.setItemAttributes(item, response, this.workplace.workplace_id);

        // Сделать созданный элемент активным в табах.
        this._setActiveTab(length);
      },
      (response, status) => this.Error.response(response, status)
    );
  };

  /**
   * Удалить элемент из массива items_attributes.
   *
   * @param item - удаляемый элемент
   */
  Workplace.prototype.delItem = function(item) {
    this.setFirstActiveTab(item);
    this.workplace.items_attributes.splice(this.workplace.items_attributes.indexOf(item), 1);
  };

  /**
   * Установить новый активный экземпляр техники в табах взависимости от удаляемого элемента.
   *
   * @param item - удаляемый экземпляр техники (необязательный параметр). Если задан - то новый активный элемент будет
   * установлен только в том случае, если удаляется активный экземпляр техники.
   */
  Workplace.prototype.setFirstActiveTab = function(item) {
    if (item && this.workplace.items_attributes.indexOf(item) != this.additional.activeTab) {
      return;
    }

    let index = this.additional.activeTab == 0 ? 1 : 0;
    this._setActiveTab(index);
  };

  /**
   * Проверка различных условий для текущего типа оборудования. Например, для одного РМ возможно наличие только
   * одного системного блока.
   *
   * @param type - объект-тип оборудования.
   */
  Workplace.prototype.validateType = function(type) {
    // Проверка, выбрал ли пользователь тип
    if (type.type_id == 0) {
      this.Flash.alert('Необходимо выбрать тип создаваемого устройства.');

      return false;
    }

    if (this.Item.isUniqType(type.name)) {
      let countPc = 0;

      // Считаем количество СБ/моноблоков/ноутбуков на текущем РМ.
      this.workplace.items_attributes.forEach((item) => {
        if (this.Item.isUniqType(item.type.name)) {
          countPc ++;
        }
      });

      if (countPc >= 1) {
        this.Flash.alert('Одно рабочее место может содержать только один из указанных видов техники: системный блок, моноблок, ноутбук, планшет.');

        return false;
      }
    }

    return true;
  };
})();

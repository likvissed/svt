import { app } from '../../app/app';

(function() {
  'use strict';

  app
    .service('Workplace', Workplace);

  Workplace.$inject = ['$window', '$http', '$timeout', 'Server', 'Flash', 'Error', 'WorkplaceItem', 'PropertyValue', 'InventItem'];

  /**
   * Сервис для редактирования(подтверждения или отклонения) РМ.
   *
   * @class SVT.Workplace
   */
  function Workplace($window, $http, $timeout, Server, Flash, Error, WorkplaceItem, PropertyValue, InventItem) {
    this.$window = $window;
    this.$http = $http;
    this.$timeout = $timeout;
    this.Server = Server;
    this.Flash = Flash;
    this.Error = Error;
    this.Item = WorkplaceItem;
    this.InventItem = InventItem;
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
    this.selectIssBuilding = { building_id: null, long_name: 'Выберите корпус' };
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

    // Назначение объекта расположения
    this.workplace.location_obj = {};

    this.workplace.location_obj.site = this.workplace.location_site_id ? (
      this.iss_locations.find((el) => {
        return this.workplace.location_site_id == el.site_id;
      })
    ) : (
      ''
    );

    this.workplace.location_obj.building = this.workplace.location_building_id ? (
      this.workplace.location_obj.site.iss_reference_buildings.find((el) => {
        return this.workplace.location_building_id == el.building_id;
      })
    ) : (
      ''
    );

    this.workplace.location_obj.room = this.workplace.location_room_id ? (
      this.workplace.location_obj.building.iss_reference_rooms.find((el) => {
        return this.workplace.location_room_id == el.room_id;
      })
    ) : (
      ''
    );
    if (this.workplace.location_obj.room) {
      this.findNameCategory();
    }

    this.workplace.items_attributes.forEach((item) => {
      this.Item.getTypesItem(item);
      this.Item.addProperties(item);
    });
  };

  /**
   * Очистить копию массива workplace от справочных данных для отправления на сервер.
   */
  Workplace.prototype._delObjects = function() {
    this.workplaceCopy = angular.copy(this.workplace);

    delete(this.workplaceCopy.workplace_type);
    delete(this.workplaceCopy.division);
    delete(this.workplaceCopy.location_obj);

    this.workplaceCopy.items_attributes.forEach((item) => this.Item.delProperties(item));
  };

  /**
   * Добавить шаблон оборудования к РМ.
   */
  Workplace.prototype._addItemTemplate = function() {
    let
      newItem = this.Item.getTemplateItem(),
      length = this.workplace.items_attributes.length,
      lastEl = this.workplace.items_attributes[length-1];

    newItem.tabIndex = lastEl ? lastEl.tabIndex + 1 : 0;

    this.workplace.items_attributes.push(newItem);
  };

  /**
   * Установить новый активный экземпляр техники в табах.
   *
   * @param index - индекс таба (от 0)
   */
  Workplace.prototype._setActiveTab = function(index) {
    this.$timeout(() => this.additional.activeTab = index, 0);
    this.InventItem.setItem(this.workplace.items_attributes[index]);
  };

  /**
   * Установка параметров, полученных с сервера.
   *
   * @param data - полученные с сервера данные
   */
  Workplace.prototype._setProperties = function(data) {
    // По умолчанию фильтры всегда включены
    this.workplace.disabled_filters = false;
    if (this.workplace.freezing_time) {
      this.workplace.freezing_time = new Date(this.workplace.freezing_time);
    }

    data.prop_data.iss_locations.forEach((value) => value.iss_reference_buildings.unshift(this.selectIssBuilding));
    this.Item.setTypes(data.prop_data.eq_types);
    this.Item.setPriorities(data.prop_data.priorities);

    // Типы РМ
    this.wp_types = [this.selectWpType].concat(data.prop_data.wp_types);
    // Направления работы на рабочих местах
    this.specs = [this.selectWpSpec].concat(data.prop_data.specs);
    // Список площадок и корпусов
    this.iss_locations = [this.selectIssLocation].concat(data.prop_data.iss_locations);

    // Категории секретности комнат
    this.rooms_security_categories = data.prop_data.rooms_security_categories;
    this.findBlankCategory();

    // Сообщение в справке для защищаемых помещений
    this.message_for_security_category = data.prop_data.message_for_security_category;

    this.statuses = data.prop_data.statuses;
    this.divisions = data.prop_data.divisions;

    this.Item.setAdditional('pcAttrs', data.prop_data.file_depending);
    this.Item.setAdditional('singleItems', data.prop_data.single_pc_items);
    this.Item.setAdditional('pcTypes', data.prop_data.type_with_files);
    this.Item.setAdditional('secretExceptions', data.prop_data.secret_exceptions);
    this.Item.setAdditional('statusesForChangeItem', data.prop_data.move_item_types);
    this.Item.setAdditional('dateProperties', data.prop_data.date_props);

    this.workplace.items_attributes.forEach((item, index) => item.tabIndex = index);
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

          this._setTemplates(data);
          this._setProperties(data);
          this._addObjects();

          this.workplace.division = this.divisions.find((el) => {
            if (el.workplace_count_id == this.workplace.workplace_count_id) { return true; }
          });

          if (this.workplace.location_room) {
            this.workplace.room_category_id = this.workplace.location_room.security_category_id;
          }

          this.changeSecurityCategory();
        }, (response, status) => {
          this.Error.response(response, status);
        }).$promise;
    } else {
      return this.Server.Invent.Workplace.new(
        (data) => {
          this.workplace = data.workplace;
          this.users = [];

          this._setTemplates(data);
          this._setProperties(data);
          this._addObjects();

          this.workplace.division = this.divisions[0];

          this.workplace.room_category_id = this.workplace.no_secrecy.id;
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

    this.workplace.location_obj.building = this.workplace.location_obj.site.iss_reference_buildings.find((el) => {
      return this.workplace.location_building_id == el.building_id;
    })

    this.workplace.location_room_id = '';
    this.workplace.location_obj.room = '';
    this.workplace.room_category_id = '';
  };

  /**
   * Запросить скрипт для генерации отчета о конфигурации ПК.
   */
  Workplace.prototype.downloadPcScript = function() {
    this.$window.open('/invent/workplaces/pc_script', '_blank');
  };

  /**
   * Сохранить данные о РМ на сервере.
   */
  Workplace.prototype.saveWorkplace = function() {
    this._delObjects();

    this.formDataResult.append('workplace', JSON.stringify(this.workplaceCopy));

    if (this.workplaceCopy.workplace_id) {
      this.formDataResult.append('workplace_id', this.workplace.workplace_id);

      this.Server.Invent.Workplace.update(this.formDataResult,
        (response) => this.$window.location.href = response.location,
        (response, status) => this.Error.response(response, status)
      );
    } else {
      this.Server.Invent.Workplace.save(this.formDataResult,
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
  };

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
    item.priorities = this.Item.getPriorities();

    item.barcode_item_attributes = {};

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

        this.Item.getTypesItem(response.item);
        this.Item.addProperties(response.item);
        this.Item.setItemAttributes(item, response.item, this.workplace.workplace_id);
        item.priorities = this.Item.getPriorities();
        item.status = 'prepared_to_swap';

        // Присвоить штрих-код, если техника с другого РМ
        item.barcode_item_attributes = response.item.barcode_item_attributes;

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
   * Установить новый активный экземпляр техники в табах взависимости от удаляемого элемента. Если удаляется активный
   * таб и он последний в списке техники - установить новый активный таб.
   *
   * @param item.
   */
  Workplace.prototype.setFirstActiveTab = function(item) {
    // Если удаляется неактивный таб, ничего не делать
    if (item && item != this.InventItem.data.item || this.workplace.items_attributes.length == 0) { return false; }

    // Если удаляется активный там и он последний в списке, установить активным первый таб
    if (this.workplace.items_attributes.slice(-1).pop() == item) {
      let index = this.workplace.items_attributes[0].tabIndex;
      this._setActiveTab(index);
    }
  };

  /**
   * Проверка различных условий для текущего типа оборудования. Например, для одного РМ возможно наличие только
   * одного системного блока.
   *
   * @param type - объект-тип оборудования.
   */
  Workplace.prototype.validateType = function(type) {
    // Проверка, выбрал ли пользователь тип
    if (!type.type_id) {
      this.Flash.alert('Необходимо выбрать тип создаваемого устройства.');

      return false;
    }

    return true;
  };

  /**
   * Найти объект для категории "Отсутствует"
   */
  Workplace.prototype.findBlankCategory = function() {
    this.workplace.no_secrecy = this.rooms_security_categories.find((el) => el.category == 'Отсутствует')
  };

  /**
   * Найти и назначить наименование выбранной комнаты
   */
  Workplace.prototype.findNameCategory = function() {
    let current_category = this.rooms_security_categories.find((el) => el.id == this.workplace.location_obj.room.security_category_id);

    this.workplace.room_category_name = current_category.category
  };

  /**
   * Изменить значение секретности комнаты
   */
  Workplace.prototype.changeSecurityCategory = function() {
    this.workplace.room_category = this.rooms_security_categories.find((el) => el.id == this.workplace.room_category_id);
  };
})();

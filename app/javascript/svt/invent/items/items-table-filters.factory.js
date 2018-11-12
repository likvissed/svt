import { app } from '../../app/app';

(function() {
  app
    .service('InventItemsTableFiltersFactory', InventItemsTableFiltersFactory);

  function InventItemsTableFiltersFactory() {
    let
      _defaultProp = {
        property_id: '',
        long_description: 'Выберите свойство'
      },
      _defaultPropList = {
        property_list_id: '',
        short_description: 'Выберите значение'
      },
      _propertyTemplate = {
        property_id: '',
        property_value: '',
        property_list_id: '',
        exact: false,
        property_to_type: _defaultProp
      },
      // Фильтры с вариантом выбора значений
      _filters = {
        types: [
          {
            type_id: '',
            short_description: 'Все типы'
          }
        ],
        properties: [_defaultProp],
        statuses: { '': 'Все статусы' },
        priorities: { '': 'Все приоритеты' },
        buildings: [],
        rooms: []
      },
      // Данные, которые будут отправлены на сервер
      _selected = {
        item_id: '',
        type_id: _filters.types[0].type_id,
        invent_num: '',
        responsible: '',
        item_model: '',
        status: Object.keys(_filters.statuses)[0],
        priority: Object.keys(_filters.priorities)[0],
        building: '',
        room: '',
        properties: []
      };

    function _addProperty() {
      _selected.properties.push(angular.copy(_propertyTemplate));
    }

    function _setDefaultValueForPropertyList() {
      _filters.properties.forEach((prop) => {
        if (!prop.property) { return true; }

        prop.property.property_lists.unshift(_defaultPropList);
      });
    }

    return {
      /**
       * Получить объекты фильтров
       */
      getFilters: function() {
        return _filters;
      },
      /**
       * Получить выбранные фильтры
       */
      getSelected: function() {
        return _selected;
      },
      /**
       * Получить фильтры для отправки на сервер
       */
      getFiltersToSend: function() {
        let obj = angular.copy(_selected);

        obj.location_building_id = obj.building.building_id;
        obj.location_room_id = obj.room.room_id;

        delete obj.building;
        delete obj.room;

        obj.properties.forEach((prop) => {
          prop.property_id = prop.property_to_type.property_id;
          delete prop.property;
        });

        return obj;
      },
      /**
       * Заполнить фильтры данными.
       */
      setPossibleValues: function(data, with_properties = false) {
        angular.forEach(_filters, function(arr, key) {
          if (!data.hasOwnProperty(key)) { return true; }

          if (Array.isArray(this[key])) {
            this[key] = this[key].concat(data[key]);
          } else {
            this[key] = Object.assign(this[key], data[key]);
          }
        }, _filters);

        if (with_properties) {
          _addProperty();
          _setDefaultValueForPropertyList();
        }
      },
      /**
       * Добавить фильтр по типу.
       */
      addProperty: _addProperty,
      /**
       * Удалить фильтр по его индексу.
       *
       * @param index
       */
      delProperty: function(index) {
        _selected.properties.splice(index, 1);
      },
      /**
       * Очистить фильтр комнат.
       */
      clearRooms: function() {
        _filters.rooms = [];
      },
      /**
       * Очистить данные фильтра.
       *
       * @param filter
       */
      clearValueForSelectedProperty: function(filter) {
        filter.property_list_id = _propertyTemplate.property_list_id;
        filter.property_value = _propertyTemplate.property_value;
      },
      /**
       * Сбросить фильтр в значения по умолчанию.
       *
       * @param index
       */
      setDefaultState: function(index) {
        _selected.properties[index] = angular.copy(_propertyTemplate);

      }
    }
  }
})();

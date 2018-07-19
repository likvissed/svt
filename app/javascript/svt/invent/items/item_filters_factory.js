import { app } from '../../app/app';

(function() {
  app
    .service('InventItemFiltersFactory', InventItemFiltersFactory);

  function InventItemFiltersFactory() {
    let
      _propertyTemplate = {
        property_id: 0,
        property_value: '',
        exact: false
      },
      // Фильтры с вариантом выбора значений
      _filters = {
        types: [
          {
            type_id: 0,
            short_description: 'Все типы'
          }
        ],
        properties: [
          {
            property_id: 0,
            long_description: 'Выберите свойство'
          }
        ],
        statuses: { all: 'Все статусы' }
      },
      // Данные, которые будут отправлены на сервер
      _selected = {
        item_id: '',
        type_id: _filters.types[0].type_id,
        invent_num: '',
        responsible: '',
        item_model: '',
        status: Object.keys(_filters.statuses)[0],
        properties: []
      };

    function _addProperty() {
      _selected.properties.push(angular.copy(_propertyTemplate));
    }

    return {
      /**
       * Получить объекты фильтров
       */
      getFilters: function() {
        return _filters;
      },
      getSelected: function() {
        return _selected;
      },
      /**
       * Заполнить фильтры данными
       */
      setPossibleValues: function(data) {
        angular.forEach(_filters, function(arr, key) {
          if (!data.hasOwnProperty(key)) { return true; }

          if (Array.isArray(this[key])) {
            this[key] = this[key].concat(data[key]);
          } else {
            this[key] = Object.assign(this[key], data[key]);
          }
        }, _filters);

        _addProperty();
      },
      /**
       * Добавить фильтр по типу
       */
      addProperty: _addProperty,
      delProperty: function(index) {
        _selected.properties.splice(index, 1);
      }
    }
  };
})();

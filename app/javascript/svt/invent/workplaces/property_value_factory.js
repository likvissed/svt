import { app } from '../../app/app';

(function() {
  'use strict';

  app
    .factory('PropertyValue', PropertyValue);

  function PropertyValue() {
    let
      // Шаблон объекта значения свойства выбранного экземпляра техники
      templatePropertyValue = {
        // id: null,
        // property_id: 0,
        // item_id: 0,
        // property_list_id: 0,
        // value: '',
        // // Массив возможных значений отфильтрованных по модели и свойству
        // filteredList: []
      },
      templateSelectProp = [
        // Для строки "Выберите тип"
        { property_list_id: -1, short_description: ''},
        // Для строки "Ввести вручную..."
        { property_list_id: 0, short_description: ''}
      ];

    return {
      /**
       * Установить шаблон объекта свойства техники.
       */
      setTemplate: function(data) {
        templatePropertyValue = data;
        data['filteredList'] = [];
      },
      /**
       * Получить объект-шаблон property_value.
       */
      getTemplatePropertyValue: function() { return angular.copy(templatePropertyValue); },
      /**
       * Проверить тип указанного свойства. (Вернуть true, если тип 'list')
       *
       * @param prop - объект property
       */
      isPropList: function(prop) { return prop.property_type == 'list'; },
      /**
       * Проверить тип указанного свойства. (Вернуть true, если тип 'list_plus')
       *
       * @param prop - объект property
       */
      isPropListPlus: function(prop) { return prop.property_type == 'list_plus'; },
      /**
       * Получить элемент массива property_values_attributes.
       *
       * @param item - экземпляр техники
       * @param prop_index - индекс элемента в массиве property_values_attributes
       * @param name - имя ключа
       */
      getPropertyValue: function(item, prop_index, name) {
        return item.property_values_attributes[prop_index][name];
      },
      /**
       * Добавить данные к элементу массива items_attributes.
       *
       * @param item
       * @param prop_index - индекс элемента в массиве property_values_attributes
       * @param name - имя ключа
       * @param value - значение
       */
      setPropertyValue: function(item, prop_index, name, value) {
        item.property_values_attributes[prop_index][name] = value;
      },
      /**
       * Возвращает переданный массив с дополненым начальным элементом. Этот начальный элемент предлагает пользователю
       * выбрать значение из указанного свойства. Например "Выберите диагональ экрана"
       *
       * @param name - краткое описание (short_description) свойства из массива properties
       * @param listFlag - необязательный параметр. Устанавливать true для типов list_plus
       */
      getTemplateSelectProp: function(name, listFlag) {
        var arr = angular.copy(templateSelectProp);

        // arr[0].short_description = 'Выберите ' + name.toLowerCase();
        arr[0].short_description = 'Выбрать из списка';
        listFlag ? arr[1].short_description = 'Ввести ' + name.toLowerCase() + ' вручную...' : arr.pop();

        return arr;
      },
      /**
       * Создать копию объекта значения свойства начиная с указанного index (использовать для свойства multiple).
       *
       * @param item - экземпляр техники
       * @param index - индекс элемента, в который необходимо вставить копию предыдущего элемента.
       */
      copyAttr: function(item, index) {
        item.property_values_attributes.splice(index, 0, angular.copy(item.property_values_attributes[index - 1]));
      }
    }
  }
})();

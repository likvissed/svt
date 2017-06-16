app
  .factory('PropertyValue', PropertyValue);

function PropertyValue() {

  var
    // Шаблон объекта значения свойства выбранного экземпляра техники
    templatePropertyValue = {
      id: null,
      property_id: 0,
      item_id: 0,
      property_list_id: 0,
      value: '',
      // Массив возможных значений отфильтрованных по модели и свойству
      filteredList: []
    },
    templateSelectProp = [
      // Для строки "Выберите тип"
      { property_list_id: -1, short_description: ''},
      // Для строки "Ввести вручную..."
      { property_list_id: 0, short_description: ''}
    ];

  return {
    /**
     * Получить объект-шаблон property_value.
     */
    getTemplatePropertyValue: function () { return templatePropertyValue; },
    /**
     * Проверить тип указанного свойства. (Вернуть true, если тип 'list')
     *
     * @param prop - объект property
     */
    isPropList: function (prop) { return prop.property_type == 'list'; },
    /**
     * Проверить тип указанного свойства. (Вернуть true, если тип 'list_plus')
     *
     * @param prop - объект property
     */
    isPropListPlus: function (prop) { return prop.property_type == 'list_plus'; },
    /**
     * Получить элемент массива inv_property_values_attributes.
     *
     * @param item
     * @param prop_index
     * @param name
     */
    getPropertyValue: function (item, prop_index, name) {
      return item.inv_property_values_attributes[prop_index][name];
    },
    /**
     * Добавить данные к элементу массива inv_items_attributes.
     *
     * @param item
     * @param prop_index - индекс элемента в массиве inv_property_values_attributes
     * @param name - имя ключа
     * @param value - значение
     */
    setPropertyValue: function (item, prop_index, name, value) {
      item.inv_property_values_attributes[prop_index][name] = value;
    },
    /**
     * Возвращает переданный массив с дополненым начальным элементом. Этот начальный элемент предлагает пользователю
     * выбрать значение из указанного свойства. Например "Выберите диагональ экрана"
     *
     * @param name - краткое описание (short_description) свойства из массива inv_properties
     * @param listFlag - необязательный параметр. Устанавливать true для типов list_plus
     */
    getTemplateSelectProp: function (name, listFlag) {
      var arr = angular.copy(templateSelectProp);

      arr[0].short_description = 'Выберите ' + name.toLowerCase();
      listFlag ? arr[1].short_description = 'Ввести ' + name.toLowerCase() + ' вручную...' : arr.pop();

      return arr;
    },
    /**
     * Создать копию свойства начиная с указанного index (использовать для свойства multiple).
     *
     * @param item - экземпляр техники
     * @param index - индекс элемента, в который необходимо вставить копию предыдущего элемента.
     */
    copyAttr: function (item, index) {
      item.inv_property_values_attributes.splice(index, 0, angular.copy(item.inv_property_values_attributes[index - 1]));
    }
  }
}
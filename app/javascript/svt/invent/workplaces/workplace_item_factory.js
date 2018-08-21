import { app } from '../../app/app';

(function() {
  'use strict';

  app.factory('WorkplaceItem', WorkplaceItem);

  WorkplaceItem.$inject = ['$filter', 'PropertyValue', 'Server', 'Flash', 'Error'];

  function WorkplaceItem($filter, PropertyValue, Server, Flash, Error) {
    let
      // Типы оборудования
      eqTypes,
      // Поле select, предлагающее выбрать тип оборудования
      selectEqType = { type_id: null, short_description: 'Выберите тип' },
      // Приоритет
      priorities = {
        // '': 'Выберите приоритет'
      },
      // Шаблон экземпляра техники, добавляемого к РМ
      templateItem = {
        // id: null,
        // // item_id: null,
        // type_id: 0,
        // workplace_id: 0,
        // location: '',
        // invent_num: '',
        // serial_num: '',
        // model_id: 0,
        // item_model: '',
        // property_values_attributes: [],
        // // По умолчанию показать пользователю "Выберите тип"
        // type: selectEqType,
        // // Выбранная модель
        // model: null,
        // status: 'in_workplace'
      },
      // Начальные данные для select тэга модели.
      templateSelectModel = [
        { model_id: -1, item_model: 'Выберите модель' },
        { model_id: 0, item_model: 'Ввести модель вручную...' }
      ],
      // Дополнительные данные
      additional = {
        // Активный таб
        activeTab: 0,
        // Типы ПК, для которых необходимы параметры pcAttrs.
        pcTypes: [],
        // Параметра СБ/моноблока/ноутбука, которые загружаются от Аудита или из файла конфигурации ПК.
        pcAttrs: [],
        // Список типов оборудования, которые не могут встречаться дважды или пересекаться между собой в рамках одного рабочего места.
        singleItems: [],
        // Разрешенные форматы загружаемого файла.
        fileFormats: [''],
        // Доп. описание модели
        model_descr: 'Под моделью понимается совокупность наименования производителя указанного вами оборудования (обычно самая большая надпись на корпусе), а также наименования конкретного вида оборудования. Например, Zalman Z3, Samsung S23C350 и т.п.',
        // Статусы обозначающие перемещение техники
        statusesForChangeItem: ['prepared_to_swap', 'waiting_bring', 'waiting_take']
      };

    /**
     * Установить объект model и model_id к указанному item. Создать полный массив models, из которого пользователь будет выбирать модель.
     *
     * @param item
     */
    function _setModel(item) {
      if (!item.type.models.length) { return; }

      // Добавить к моделям запись "Выберите модель" и "Другое"
      item.type.models = templateSelectModel.concat(item.type.models);

      if (item.id) {
        var model = item.type.models.find((el) => el.model_id == item.model_id);
        item.model = model || templateSelectModel[1];
      } else {
        item.model = item.type.models[0];
        item.model_id = item.model.model_id;
      }
    }
    /**
     * Создать копию тех свойств properties, которые встречаются дважды в указанном экземпляре техники.
     *
     * @param item - экземпляр техники
     */
    function _cloneProperties(item) {
      // Объект, содержащий количество значений для каждого свойства.
      // Ключ - property_id свойства
      // Значение - количество вхождений в массив property_values_attributes
      let counterObj = {};

      // Заполняем объект counterObj
      item.property_values_attributes.forEach((prop_val_value) => {
        counterObj[prop_val_value.property_id] = (counterObj[prop_val_value.property_id] || 0) + 1
      });

      // Для каждого свойства, значение которого встречается больше одного раза, создать копию этого
      // свойства и добавить в массив, который эти свойства и хранит.
      angular.forEach(counterObj, function(counter_value, counter_key) {
        if (counter_value <= 1) { return true; }

        for (let i = 1; i < counter_value; i ++) {
          let
            // Копия объекта с совпадающим property_id
            tmpProp = null,
            // Индекс в совпавшего элемента массива
            tmpIndex = null;

          item.type.properties.forEach(function(prop_val, prop_index) {
            if (counter_key != prop_val.property_id) { return true; }

            tmpProp = prop_val;
            tmpIndex = prop_index;
            return false;
          });

          if (tmpProp && tmpIndex)
            item.type.properties.splice(tmpIndex + 1, 0, tmpProp);
        }
      });
    }

    /**
     * Очистить аттрибут value элементов массива property_values_attributes и удалить повторяющиеся свойства из
     * property_values_attributes и properties.
     *
     * @param item - элемент массива property_values_attributes
     */
    function _clearPropertyValues(item) {
      let
        // Объект, необходимый для "запоминания" первого экземпляра свойства с типом multiple = true (Например,
        // первый жесткий диск из списка жестких дисков).
        virtualObj = {
          // Индекс элемента (если 0, первый элемент экземпляра свойства с типом multiple = true)
          index: 0,
          // property_id свойства элемента.
          property_id: 0
        },
        // Копия массива ivn_properties
        copiedProp = [],
        // Копия массива property_values_attributes
        copiedPropVal = [],
        // Для свойств multiple эта переменная содержит копию элемента массива item.type.properties
        tmpProp,
        // Для свойств multiple эта переменная содержит копию элемента массива item.property_values_attributes
        tmpPropValue;

      // Очистить массив properties
      item.property_values_attributes.forEach(function(value, index) {
        if (item.type.properties[index].multiple) {
          // Поля, помеченных на удаление.
          if (value._destroy) {
            copiedProp.push(angular.copy(item.type.properties[index]));
            copiedPropVal.push(value);

            return true;
          }

          // Если property_id совпадают значит это уже не первый элемент, который мы встретили. Значит его нужно
          // будет либо удалить из массива, либо скрыть, установив _destroy = 1
          // Если не совпадают - значит это первый элемент текущего экземпляра свойства. Для него необходимо
          // создать копию, а сам элемент скрыть.
          if (virtualObj.property_id == value.property_id) {
            virtualObj.index ++;
          } else {
            virtualObj.property_id = angular.copy(value.property_id);
            virtualObj.index = 0
          }

          if (value.id) {
            tmpProp = angular.copy(item.type.properties[index]);
            tmpProp._destroy = 1;

            value._destroy = 1;

            copiedProp.push(tmpProp);
            copiedPropVal.push(value);

            // Если virtualObj.index == 0, значит этот элемент первый в массиве. Значит создадим копию этого
            // элемента, чтобы вывести пользователю для заполнения, а сам элемент скроем. Остальные элементы
            // массива будут только скрыты с флагом _destroy = 1.
            if (!virtualObj.index) {
              tmpPropValue = PropertyValue.getTemplatePropertyValue();
              tmpPropValue.property_id = tmpProp.property_id;

              copiedProp.push(angular.copy(item.type.properties[index]));
              copiedPropVal.push(tmpPropValue);
            }
          } else {
            if (virtualObj.index) {
              return true;
            } else {
              value.value = '';

              copiedProp.push(angular.copy(item.type.properties[index]));
              copiedPropVal.push(angular.copy(value));
            }
          }
        } else {
          value.value = '';

          copiedProp.push(angular.copy(item.type.properties[index]));
          copiedPropVal.push(angular.copy(value));
        }
      });

      item.type.properties = angular.copy(copiedProp);
      item.property_values_attributes = angular.copy(copiedPropVal);
    }

    /**
     * Создать массив filteredList на основании выбранной модели и типа оборудования. filteredList - массив возможных
     * значений для конкретного свойства с типом list и list_plus.
     *
     * @param item - изменяемый объект массива property_values_attributes
     * @param prop_index - индекс массива property_list
     * @param prop_value - элемент массива property_list
     */
    function _createFilteredList(item, prop_index, prop_value) {
      if (!(PropertyValue.isPropList(prop_value) || PropertyValue.isPropListPlus(prop_value)))
        return false;

      // Массив данных с сервера для конкретного свойства
      let filteredList = $filter('inventPropList')(prop_value.property_lists, item.model_id);

      // Для модели, введенной вручную, позволить пользователю вводить данные свойства вручную.
      if (!item.model_id || item.model_id == -1 || filteredList.length != 1)
        filteredList = PropertyValue
          .getTemplateSelectProp(prop_value.short_description, PropertyValue.isPropListPlus(prop_value))
          .concat(filteredList);

      PropertyValue.setPropertyValue(item, prop_index, 'filteredList', filteredList);
    }

    /**
     * Установить значения свойств (CPU, HDD, ...) для ПК.
     *
     * @param item - изменяемый объект
     * @param data - объект данных { cpu: [], hdd: [], mb: [], ... }
     */
    function _setPcProperties(item, data) {
      let
        // Индекс объекта prop_obj
        prop_index,
        // Объект массива properties
        prop_obj;

      _clearPropertyValues(item);

      // Цикл по полученным данным
      angular.forEach(data, function(audit_arr, key) {
        if (!audit_arr) { return true; }

        prop_index = item.type.properties.findIndex((prop) => !prop._destroy && prop.name == key)
        prop_obj = item.type.properties[prop_index];

        if (!prop_obj) { return true; }

        if (prop_obj.multiple) {
          // Запоминаем prop_index, для использования внутри цикла audit_arr
          let new_index = prop_index;

          audit_arr.forEach(function(audit_value, index) {
            // Для первого элемента просто заполнить поле value
            if (index == 0) {
              PropertyValue.setPropertyValue(item, new_index, 'value', audit_value);
              return true;
            }

            // Меняем индекс, чтобы новые элементы появлялись после предыдущих, а не перед ними
            new_index ++;

            // Создать копию объекта property
            item.type.properties.splice(new_index, 0, prop_obj);
            PropertyValue.copyAttr(item, new_index);
            PropertyValue.setPropertyValue(item, new_index, 'value', audit_value);
          })
        } else {
          PropertyValue.setPropertyValue(item, prop_index, 'value', audit_arr[0]);
        }
      });
    }

    /**
     * Установить начальное значение поля с типом list и list_plus после выбора модели.
     *
     * @param item
     * @param prop_index - индекс элемента в массиве property_values_attributes
     */
    function _setInitPropertyListId (item, prop_index) {
      if (item.property_values_attributes[prop_index].filteredList.length > 0) {
        item.property_values_attributes[prop_index].property_list_id = item.property_values_attributes[prop_index].filteredList[0].property_list_id;
      } else {
        item.property_values_attributes[prop_index].property_list_id = 0;
      }
    }

    return {
      /**
       * Установить шаблон объекта техники.
       */
      setTemplate: function(data) {
        templateItem = data;
        templateItem['type'] = selectEqType;
        templateItem['model'] = null;
      },
      /**
       * Получить шаблонный объект экземпляра техники.
       */
      getTemplateItem: function() { return angular.copy(templateItem); },
      /**
       * Установить значение указанного параметра объекта additional.
       *
       * @param name - имя параметра
       * @param value - устанавливаемое значение
       */
      setAdditional: function(name, value) { additional[name] = value; },
      /**
       * Получить объект, содержащий дополнительные параметры.
       */
      getAdditional: function() { return additional; },
      /**
       * Записать массив типов техники.
       *
       * @param types - добавляемый массив типов.
       */
      setTypes: function(types) { eqTypes = [selectEqType].concat(types); },
      /**
       * Получить массив типов техники.
       */
      getTypes: function() { return eqTypes },
      /**
       * Записать объект с приоритетами исполнения техники
       */
      setPriorities: function(data) { angular.extend(priorities, data); },
      /**
       * Получить объект с приоритетами исполнения техники
       */
      getPriorities: function() { return priorities; },
      /**
       * Добавить вспомогательные объекты к указанному объекту item.
       *
       * @param item - экземпляр техники
       */
      addProperties: function(item) {
        let eq_value = eqTypes.find((type) => type.type_id == item.type_id);

        if (!eq_value) { return false; }

        item.priorities = this.getPriorities();
        item.type = angular.copy(eq_value);
        // Если длина массивов property_values_attributes и properties отличается, значит текущий
        // экземпляр техники имеет несколько значений для некоторых свойств (например, несколько жестких
        // дисков для системного блока). Необходимо создать копии соответсвующих элементов массива
        // properties и поместить их в этот же массив. Иначе пользователь увидит, например, только один
        // жесткий диск.
        if (item.property_values_attributes.length != item.type.properties.length) {
          _cloneProperties(item);
        }

        _setModel(item);

        // Создаем массив filteredList
        item.type.properties.forEach((prop, index) => _createFilteredList(item, index, prop));
      },
      /**
       * Удалить вспомогательные объекты из указанного объекта item.
       *
       * @param item - экземпляр техники
       */
      delProperties: function(item) {
        delete(item.type);
        delete(item.model);

        item.property_values_attributes.forEach((prop_val) => delete(prop_val.filteredList));
      },
      /**
       * Создать массив filteredList на основании выбранной модели и типа оборудования.
       */
      createFilteredList: _createFilteredList,
      /**
       * Очистить аттрибут value элементов массива property_values_attributes и удалить повторяющиеся свойства из
       * property_values_attributes и properties.
       */
      clearPropertyValues: _clearPropertyValues,
      /**
       * Установить значения свойств (CPU, HDD, ...) для ПК.
       */
      setPcProperties: _setPcProperties,
      /**
       * Проверить наличие значения в массиве singleItems.
       *
       * value - проверяемое значение
       */
      isUniqType: function(value) {
        return additional.singleItems.includes(value);
      },
      /**
       * Проверить тип загруженного файла.
       *
       * @param file - объект-файл
       */
      isValidFile: function(file) {
        return additional.fileFormats.includes(file.type);
      },
      /**
       * Проверить наличие значения в массиве pcTypes.
       *
       * @param value - проверяемое значение
       */
      isPc: function(value) {
        return additional.pcTypes.includes(value);
      },
      /**
       * Распарсить загруженный файл, найти в нем все параметры, необходимые для ПК.
       *
       * @param item - объект техники, для которого пользователь загружает файл.
       * @param data - данные, прочитанные из файла (их возвращает сервер).
       */
      matchDataFromUploadedFile: function(item, data) {
        let
          res,
          error = false,
          matchedObj = {};

        res = data.replace(/ +/g, ' ');
        matchedObj.video = res.match(/\[video\]\s+(.*)\s+\[mb\]/m);
        matchedObj.mb = res.match(/\[mb\]\s+(.*)\s+\[cpu\]/m);
        matchedObj.cpu = res.match(/\[cpu\]\s+(.*)\s+\[ram\]/m);
        matchedObj.ram = res.match(/\[ram\]\s+(.*)\s+\[hdd\]/m);
        matchedObj.hdd = res.match(/\[hdd\]\s+(.*)/m);

        additional.pcAttrs.forEach(function(attr_value) {
          if (!matchedObj[attr_value]) {
            error = true;
            return false;
          }

          if (matchedObj[attr_value]) {
            matchedObj[attr_value] = matchedObj[attr_value][1].split(';');

            // Удаление лишних пробелов
            matchedObj[attr_value].forEach(function(matched_value, matched_index) {
              matchedObj[attr_value][matched_index] = matched_value.trim();
            });
          }
        });

        if (error) {
          return false;
        } else {
          _setPcProperties(item, matchedObj);
          return true;
        }
      },
      /**
       * Записать в модель workplace.items данные о выбранной модели выбранного типа оборудования.
       *
       * @param item - экземпляр техники.
       */
      changeModel: function(item) {
        item.model_id = item.model.model_id;
        // Изменить начальные данные для всех элемнетов массива property_values_attributes.
        item.type.properties.forEach(function(prop_value, prop_index) {
          _createFilteredList(item, prop_index, prop_value);
          _setInitPropertyListId(item, prop_index);
        });
      },
      /**
       * Для указанного объекта item установить тип техники.
       *
       * @param item - изменяемый объект массива items_attributes.
       * @param type - тип техники
       */
      setType: function(item, type) {
        item.type = type;
        item.type_id = item.type.type_id;
      },
      /**
       * Установить объект model и model_id к указанному item. Создать полный массив models, из которого пользователь будет выбирать модель.
       */
      setModel: _setModel,
      /**
       * Добавить новый элемент к массиву property_values_attributes элемента item.
       *
       * @param item
       */
      addNewPropertyValue: function(item) {
        item.property_values_attributes.push(PropertyValue.getTemplatePropertyValue());
      },
      setInitPropertyListId: _setInitPropertyListId,
      /**
       * Заполнить созданный элемент массива items_attributes указанными данными.
       *
       * @param item
       * @param data - данные для заполнения объекта item
       * @param workplace_id - ID рабочего места
       */
      setItemAttributes: function(item, data, workplace_id) {
        Object.keys(templateItem).forEach(function(key) { item[key] = data[key]; });

        item.workplace_id = workplace_id;
      },
      /**
       * Удалить технику из БД
       */
      destroyItem: function(item) {
        return Server.Invent.Item.delete(
          { item_id: item.id },
          (response) => Flash.notice(response.full_message),
          (response, status) => Error.response(response, status)
        ).$promise;
      }
    };
  }
})();

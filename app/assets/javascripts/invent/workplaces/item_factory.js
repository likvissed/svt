(function () {
  'use strict';

  app
    .factory('Item', Item);

  Item.$inject = ['$filter', 'PropertyValue'];

  function Item($filter, PropertyValue) {
    var
      // Типы оборудования
      eqTypes,
      // Поле select, предлагающее выбрать тип оборудования
      selectEqType = { type_id: -1, short_description: 'Выберите тип' },
      // Шаблон экземпляра техники, добавляемого к РМ
      templateItem = {
        id: null,
        // item_id: null,
        type_id: 0,
        workplace_id: 0,
        location: '',
        invent_num: '',
        model_id: 0,
        item_model: '',
        inv_property_values_attributes: [],
        // По умолчанию показать пользователю "Выберите тип"
        type: selectEqType,
        // Выбранная модель
        model: null
      },
      // Файл конфигурации ПК, связанный с текущим РМ.
      pcFile = null,
      // Начальные данные для select тэга модели.
      templateSelectModel = [
        { model_id: -1, item_model: 'Выберите модель' },
        { model_id: 0, item_model: 'Ввести модель вручную...' }
      ],
      // Дополнительные данные
      additional = {
        // Ключ
        fileKey: null,
        // Активный таб
        activeTab: 0,
        // Если true - получены корректные данные от аудита, либо загружен (подготовлен для загрузки) файл, либо файл
        // уже загружен
        auditData: false,
        // Инвентарный номер, связанный с данными, полученными от аудита.
        invent_num: '',
        // Число видимых пользователю экземпляров техники для текущего РМ.
        visibleCount: 0,
        // Типы ПК, для которых необходимы параметры pcAttrs.
        pcTypes: [],
        // Параметра СБ/моноблока/ноутбука, которые загружаются от Аудита или из файла конфигурации ПК.
        pcAttrs: [],
        // Список типов оборудования, которые не могут встречаться дважды или пересекаться между собой в рамках одного рабочего места.
        singleItems: [],
        // Разрешенные форматы загружаемого файла.
        fileFormats: [''],
        // Доп. описание модели
        model_descr: 'Под моделью понимается совокупность наименования производителя указанного вами оборудования (обычно самая большая надпись на корпусе), а также наименования конкретного вида оборудования. Например, Zalman Z3, Samsung S23C350 и т.п.'
      };

    /**
     * Создать копию тех свойств inv_properties, которые встречаются дважды в указанном экземпляре техники.
     *
     * @param item - экземпляр техники
     */
    function _cloneProperties(item) {
      // Объект, содержащий количество значений для каждого свойства.
      // Ключ - property_id свойства
      // Значение - количество вхождений в массив inv_property_values_attributes
      var counterObj = {};

      // Заполняем объект counterObj
      angular.forEach(item.inv_property_values_attributes, function (prop_val_value) {
        counterObj[prop_val_value.property_id] = (counterObj[prop_val_value.property_id] || 0) + 1
      });

      // Для каждого свойства, значение которого встречается больше одного раза, создать копию этого
      // свойства и добавить в массив, который эти свойства и хранит.
      angular.forEach(counterObj, function (counter_value, counter_key) {
        if (counter_value <= 1) { return true; }

        for (var i = 1; i < counter_value; i ++) {
          var
            // Копия объекта с совпадающим property_id
            tmpProp  = null,
            // Индекс в совпавшего элемента массива
            tmpIndex = null;

          angular.forEach(item.type.inv_properties, function (prop_val, prop_index) {
            if (counter_key != prop_val.property_id) { return true; }

            tmpProp = prop_val;
            tmpIndex = prop_index;
            return false;
          });

          if (tmpProp && tmpIndex)
            item.type.inv_properties.splice(tmpIndex + 1, 0, tmpProp);
        }
      });
    }

    /**
     * Создать массив filteredList на основании выбранной модели и типа оборудования. filteredList - массив возможных
     * значений для конкретного свойства с типом list и list_plus.
     *
     * @param item - изменяемый объект массива inv_property_values_attributes
     * @param prop_index - индекс массива inv_property_list
     * @param prop_value - элемент массива inv_property_list
     */
    function _createFilteredList(item, prop_index, prop_value) {
      if (!(PropertyValue.isPropList(prop_value) || PropertyValue.isPropListPlus(prop_value)))
        return false;

      // Массив данных с сервера для конкретного свойства
      var filteredList = $filter('inventPropList')(prop_value.inv_property_lists, item.model_id);

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
      // Цикл по полученным данным
      angular.forEach(data, function (audit_arr, key) {
        if (!audit_arr)
          return true;

        // Цикл по массиву inv_properties
        // prop_obj - Объект property массива inv_properties
        // index - Индекс объекта property
        // angular.forEach(item.type.inv_properties, function (prop_obj, prop_index) {
        $.each(item.type.inv_properties, function (prop_index, prop_obj) {
          // Пропускаем элементы массива, которые помечены на удаление.
          if (prop_obj._destroy) { return true; }
          if (prop_obj.name != key) { return true; }

          // Если имеется совпадение по имени свойства, запоминаем необходимые параметры

          // Для свойств с флагом multiple = true
          if (prop_obj.multiple) {
            // Запоминаем prop_index, для использования внутри цикла audit_arr
            var new_index = angular.copy(prop_index);

            angular.forEach(audit_arr, function (audit_value, index) {
              // Для первого элемента просто заполнить поле value
              if (index == 0) {
                PropertyValue.setPropertyValue(item, new_index, 'value', audit_value);
                return;
              }

              // Меняем индекс, чтобы новые элементы появлялись после предыдущих, а не перед ними
              new_index ++;

              item.type.inv_properties.splice(new_index, 0, prop_obj);
              PropertyValue.copyAttr(item, new_index);
              PropertyValue.setPropertyValue(item, new_index, 'value', audit_value);
            })

          } else {
            PropertyValue.setPropertyValue(item, prop_index, 'value', audit_arr[0]);
          }

          return false;
        });
      });

      additional.auditData = true;
    }

    /**
     * Для указанного объекта item установить начальные связанные с ним параметры модели.
     *
     * @param item - изменяемый объект массива inv_items_attributes
     */
    function _setDefaultModelMetadata(item) {
      // Если массив моделей не пустой (модели существуют)
      if (item.type.inv_models[0]) {
        // Добавить к моделям запись "Выберите модель" и "Другое"
        item.type.inv_models = angular.copy(this.templateSelectModel.concat(item.type.inv_models));

        item.model = angular.copy(item.type.inv_models[0]);
        item.model_id = angular.copy(item.model.model_id);
      } else {
        item.model = null;
        item.model_id = null;
      }
    }

    /**
     * Установить начальное значение поля с типом list и list_plus после выбора модели.
     *
     * @param item
     * @param prop_index - индекс элемента в массиве inv_property_values_attributes
     */
    function _setInitPropertyListId (item, prop_index) {
      if (item.inv_property_values_attributes[prop_index].filteredList.length > 0) {
        item.inv_property_values_attributes[prop_index].property_list_id = item.inv_property_values_attributes[prop_index].filteredList[0].property_list_id;
      } else {
        item.inv_property_values_attributes[prop_index].property_list_id = 0;
      }
    }

    return {
      /**
       * Получить шаблонный объект экземпляра техники.
       */
      getTemplateItem: function () { return angular.copy(templateItem); },
      /**
       * Установить значение для объекта pcFile.
       *
       * @param file - загруженный файл
       */
      setPcFile: function (file) { pcFile = file },
      /**
       * Получить загруженный файл.
       */
      getPcFile: function () { return pcFile },
      /**
       * Установить значение указанного параметра объекта additional.
       *
       * @param name - имя параметра
       * @param value - устанавливаемое значение
       */
      setAdditional: function (name, value) { additional[name] = value; },
      /**
       * Получить объект, содержащий дополнительные параметры.
       */
      getAdditional: function () { return additional; },
      /**
       * Записать массив типов техники.
       *
       * @param types - добавляемый массив типов.
       */
      setTypes: function (types) { eqTypes = [selectEqType].concat(types); },
      /**
       * Получить массив типов техники.
       */
      getTypes: function () { return eqTypes },
      /**
       * Добавить вспомогательные объекты к указанному объекту item.
       *
       * @param item - экземпляр техники
       */
      addProperties: function (item) {
        angular.forEach(eqTypes, function (eq_value) {
          if (item.type_id != eq_value.type_id) { return true; }

          item.type = angular.copy(eq_value);

          // Если длина массивов inv_property_values_attributes и inv_properties отличается, значит текущий
          // экземпляр техники имеет несколько значений для некоторых свойств (например, несколько жестких
          // дисков для системного блока). Необходимо создать копии соответсвующих элементов массива
          // inv_properties и поместить их в этот же массив. Иначе пользователь увидит, например, только один
          // жесткий диск.
          if (item.inv_property_values_attributes.length != item.type.inv_properties.length) {
            _cloneProperties(item);
          }

          // Для типов техники "Системный блок", "Моноблок" и "Ноутбук" необходимо проверить, заданы ли параметры.
          if ($filter('contains')(additional.pcTypes, item.type.name)) {
            // Запоминаем инвентарный номер
            additional.invent_num = angular.copy(item.invent_num);
            // Устанавливаем флаг наличия СБ/Моноблока/Монитора
            additional.auditData = true;
          }

          // Добавить к моделям запись "Выберите модель" и "Другое", если для данного типа оборудования задан список моделей.
          if (item.type.inv_models.length)
            item.type.inv_models = templateSelectModel.concat(item.type.inv_models);

          // Если model_id задан, находим соответствующий объект model из массива inv_models.
          if (item.model_id) {
            angular.forEach(item.type.inv_models, function (model_value) {
              if (item.model_id != model_value.model_id) { return true; }

              item.model = angular.copy(model_value);
              return false;
            });
          } else {
            item.model = angular.copy(templateSelectModel[1]);
          }

          // Создаем массив filteredList
          angular.forEach(item.type.inv_properties, function (prop, index) {
            _createFilteredList(item, index, prop);
          });

          return false;
        });
      },
      /**
       * Удалить вспомогательные объекты из указанного объекта item.
       *
       * @param item - экземпляр техники
       */
      delProperties: function (item) {
        delete(item.type);
        delete(item.model);

        if (item.destroy_property_values) {
          item.inv_property_values_attributes = item.inv_property_values_attributes.concat(item.destroy_property_values);
          delete(item.destroy_property_values);
        }

        angular.forEach(item.inv_property_values_attributes, function (prop_val) { delete(prop_val.filteredList) });
      },
      /**
       * Создать массив filteredList на основании выбранной модели и типа оборудования.
       *
       * @param item - изменяемый объект массива inv_property_values_attributes
       * @param prop_index - индекс массива inv_property_list
       * @param prop_value - элемент массива inv_property_list
       */
      createFilteredList: _createFilteredList,
      /**
       * Очистить value элементов массива inv_property_values_attributes и удалить повторяющиеся свойства из
       * inv_property_values_attributes и inv_properties.
       *
       * @param item - элемент массива inv_property_values_attributes
       */
      clearPropertyValues: function (item) {
        var
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
          // Копия массива inv_property_values_attributes
          copiedPropVal = [];

        // Очистить массив inv_properties
        angular.forEach(item.inv_property_values_attributes, function (value, index) {
          var
            // Для свойств multiple эта переменная содержит копию элемента массива item.type.inv_properties
            tmpProp,
            // Для свойств multiple эта переменная содержит копию элемента массива item.inv_property_values_attributes
            tmpPropValue;

          if (item.type.inv_properties[index].multiple) {
            // Поля, помеченных на удаление, и поля с типом 'config_file' не изменять.
            if (value._destroy) {
              copiedProp.push(angular.copy(item.type.inv_properties[index]));
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
              tmpProp = angular.copy(item.type.inv_properties[index]);
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

                copiedProp.push(angular.copy(item.type.inv_properties[index]));
                copiedPropVal.push(tmpPropValue);
              }
            } else {
              if (virtualObj.index) {
                return true;
              } else {
                value.value = '';

                copiedProp.push(angular.copy(item.type.inv_properties[index]));
                copiedPropVal.push(angular.copy(value));
              }
            }
          } else {
            value.value = '';

            copiedProp.push(angular.copy(item.type.inv_properties[index]));
            copiedPropVal.push(angular.copy(value));
          }
        });

        item.type.inv_properties = angular.copy(copiedProp);
        item.inv_property_values_attributes = angular.copy(copiedPropVal);
      },
      /**
       * Удалить данные о системном блоке (удалить загруженный файл, сбросить флаг, запрещающий менять инвентарный и т.д.).
       * Важно! Метод должен быть запущен до того, как изменится type_id указанного item.
       *
       * item - изменяемый объект РМ.
       */
      clearPcMetadata: function (item) {
        // Находим тип оборудования, который был до изменения (до вызова метода changeEqType в контроллере).
        // (Только для тех случаев, если до изменения был тип 'pc', 'allin1' или 'notebook')
        angular.forEach(eqTypes, function (value) {
          if (item.type_id != value.type_id) { return true; }
          if (!$filter('contains')(additional.pcTypes, value.name)) { return true; }

          additional.auditData = false;
          pcFile = null;

          // Ищем индекс элемента в массива inv_property_values_attributes с типом config_file для очистики поля value.
          var prop_index = null;
          angular.forEach(item.type.inv_properties, function (el, index) {
            if (el.name == 'config_file') {
              prop_index = index;

              return false;
            }
          });

          if (prop_index != null)
            PropertyValue.setPropertyValue(item, prop_index, 'value', '');

          return false;
        });
      },
      setPcProperties: _setPcProperties,
      /**
       * Проверить наличие значения в массиве singleItems.
       *
       * value - проверяемое значение
       */
      typeValidationPassed: function (value) {
        return $filter('contains')(additional.singleItems, value);
      },
      /**
       * Проверить тип загруженного файла.
       *
       * @param file - объект-файл
       */
      fileValidationPassed: function (file) {
        return $filter('contains')(additional.fileFormats, file.type);
      },
      /**
       * Проверить наличие значения в массиве pcTypes.
       *
       * @param value - проверяемое значение
       */
      pcValidationPassed: function (value) {
        return $filter('contains')(additional.pcTypes, value);
      },
      /**
       * Очистить параметры массива additional, связанные с ПК.
       */
      clearPcAdditionalData: function () {
        additional.invent_num = '';
        additional.auditData = false;
        pcFile = null;
      },
      /**
       * Установить имя файла в качестве значения для свойства 'config_file'.
       *
       * @param item - объект item
       * @param filename - имя файла
       */
      setFileName: function (item, filename) {
        angular.forEach(item.type.inv_properties, function (prop, index) {
          if (prop.name == 'config_file') {
            PropertyValue.setPropertyValue(item, index, 'value', filename);

            return false;
          }
        });
      },
      /**
       * Распарсить загруженный файл, найти в нем все параметры, необходимые для ПК.
       *
       * @param item - объект техники, для которого пользователь загружает файл.
       * @param data - данные, прочитанные из файла (их возвращает сервер).
       */
      matchDataFromUploadedFile: function (item, data) {
        var
          res,
          error = false,
          matchedObj = {};

        res = data.replace(/ +/g, ' ');
        matchedObj.video = res.match(/\[video\]\s+(.*)\s+\[mb\]/m);
        matchedObj.mb = res.match(/\[mb\]\s+(.*)\s+\[cpu\]/m);
        matchedObj.cpu = res.match(/\[cpu\]\s+(.*)\s+\[ram\]/m);
        matchedObj.ram = res.match(/\[ram\]\s+(.*)\s+\[hdd\]/m);
        matchedObj.hdd = res.match(/\[hdd\]\s+(.*)/m);

        angular.forEach(additional.pcAttrs, function (attr_value) {
          if (!matchedObj[attr_value]) {
            error = true;
            return false;
          }

          if (matchedObj[attr_value]) {
            matchedObj[attr_value] = matchedObj[attr_value][1].split(';');

            // Удаление лишних пробелов
            angular.forEach(matchedObj[attr_value], function (matched_value, matched_index) {
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
       * Записать в модель workplace.inv_items данные о выбранной модели выбранного типа оборудования.
       *
       * @param item - экземпляр техники.
       */
      changeModel: function (item) {
        item.model_id = item.model.model_id;
        // Изменить начальные данные для всех элемнетов массива inv_property_values_attributes.
        angular.forEach(item.type.inv_properties, function (prop_value, prop_index) {
          _createFilteredList(item, prop_index, prop_value);
          _setInitPropertyListId(item, prop_index);
        });
      },
      /**
       * Для указанного объекта item установить связанные с ним параметры типа оборудования.
       *
       * @param item - изменяемый объект массива inv_items_attributes.
       */
      setItemDefaultMetadata: function (item) {
        item.type_id = angular.copy(item.type.type_id);

        // if (!item.destroy_property_values && !flag) {
        //     item.destroy_property_values = $.grep(item.inv_property_values_attributes, function (el) { if (el.id) return true; });
        //     $.each(item.destroy_property_values, function (index, value) {
        //         this._destroy = 1;
        //     });
        // }
      },
      /**
       * Для указанного объекта item установить начальные связанные с ним параметры модели.
       *
       * @param item - изменяемый объект массива inv_items_attributes
       * @param flag - флаг (необязательный параметр). Если 'new' - установить начальное значение модели.
       */
      setModelDefaultMetadata: function (item, flag) {
        if (flag == 'new') {
          // Если массив моделей не пустой (модели существуют)
          if (item.type.inv_models[0]) {
            // Добавить к моделям запись "Выберите модель" и "Другое"
            item.type.inv_models = angular.copy(templateSelectModel.concat(item.type.inv_models));

            item.model = angular.copy(item.type.inv_models[0]);
            item.model_id = angular.copy(item.model.model_id);
          } else {
            item.model = null;
            item.model_id = null;
          }
        } else {
          item.model_id = item.model.model_id;
        }
      },
      /**
       * Добавить новый элемент к массиву inv_property_values_attributes элемента item.
       *
       * @param item
       */
      addNewPropertyValue: function (item) {
        item.inv_property_values_attributes.push(PropertyValue.getTemplatePropertyValue());
      },
      setInitPropertyListId: _setInitPropertyListId
    };
  }
})();

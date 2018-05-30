(function () {
  'use strict';

  app.service('Model', Model);

  Model.$inject = ['Server', 'TablePaginator', 'Config', 'Flash', 'Error'];

  function Model(Server, TablePaginator, Config, Flash, Error) {
    this.Server = Server;
    this.TablePaginator = TablePaginator;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;

    this.toSelect = {
      type: {
        type_id: null,
        short_description: 'Выберите тип'
      },
      vendor: {
        vendor_id: null,
        vendor_name: 'Выберите вендора'
      },
      attr: {
        property_list_id: null,
        short_description: 'Выберите аттрибут'
      }
    };
  }

  Model.prototype._initTypes = function(data) {
    this.types = [];
    this.types = this.types.concat(data.types);
  };

  Model.prototype._initModel = function(data) {
    var self = this;

    this.model = data.model;
    this.model.type = this.model.type_id ? data.types.find(function(el) { return el.type_id == self.model.type_id; }) : this.toSelect.type;
    this.model.model_property_lists_attributes = data.model.model_property_lists_attributes || [];
    if (this.model.type.properties) { this._associateProperties() };
  };

  /**
   * Уравнять массивы properties и model_property_lists_attributes.
   */
  Model.prototype._associateProperties = function() {
    var self = this;

    if (this.model.model_property_lists_attributes.length == this.model.type.properties.length) { return true; }

    this.model.type.properties.forEach(function(prop) {
      if (self.model.model_property_lists_attributes.find(function(el) { return el.property_id == prop.property_id; })) { return true; }

      self.model.model_property_lists_attributes.push(self._getModelPropList(prop));
    });
  };

  /**
   * Получить объект model_property_list указанного свойства.
   *
   * @param prop
   */
  Model.prototype._getModelPropList = function(prop) {
    var obj;

    obj = angular.copy(this.model_property_list_template);
    obj.property_id = prop.property_id;

    return obj;
  };

  /**
   * Для выбранного типа оборудования установить объекты массива model_property_lists_attributes в начальные состояния.
   */
  Model.prototype.setModelPropertyListAttributes = function() {
    var
      self = this,
      obj;

    this.model.model_property_lists_attributes = this.model.type.properties.map(function(el) { return self._getModelPropList(el); });
  };

  /**
   * Инициализировать объект model.
   */
  Model.prototype.initData = function(data) {
    this.model_property_list_template = angular.copy(data.model_property_list);

    this._initTypes(data);
    this._initModel(data);
  };

  /**
   * Получить объект для отправки на сервер.
   */
  Model.prototype.getObjectToSend = function() {
    var obj = angular.copy(this.model)

    delete(obj.type);

    return obj;
  }
})();
import { app } from '../../app/app';
import { FormValidationController } from '../../shared/functions/form-validation';

(function() {
  'use strict';

  app.controller('EditModelCtrl', EditModelCtrl);

  EditModelCtrl.$inject = ['$uibModalInstance', 'Model', 'Vendors', 'Server', 'Flash', 'Error'];

  function EditModelCtrl($uibModalInstance, Model, Vendors, Server, Flash, Error) {
    this.setFormName('model');

    this.$uibModalInstance = $uibModalInstance;
    this.Model = Model;
    this.Server = Server;
    this.Flash = Flash;
    this.Error = Error;

    this.model = Model.model;
    this.types = Model.types;
    this.vendors = angular.copy(Vendors.vendors);

    this._createModelPropertyListGetterSetter();
    this._addInitialValues();
  }

  // Унаследовать методы класса FormValidationController
  EditModelCtrl.prototype = Object.create(FormValidationController.prototype);
  EditModelCtrl.prototype.constructor = EditModelCtrl;

  EditModelCtrl.prototype._createModelPropertyListGetterSetter = function() {
    let model_prop_list;

    this.model.createModelPropertyListGetterSetter = (property) => {
      property.modelPropertyListGetterSetter = (property_list_id) => {
        model_prop_list = this.model.model_property_lists_attributes.find((attr) => {
          return attr.property_id == property.property_id;
        });

        if (angular.isDefined(property_list_id)) {
          model_prop_list.property_list_id = property_list_id;
        }

        return model_prop_list ? model_prop_list.property_list_id : null;
      };

      return property.modelPropertyListGetterSetter;
    }
  };

  /**
   * Установить начальные значения на списки.
   */
  EditModelCtrl.prototype._addInitialValues = function() {
    this.types.unshift(angular.copy(this.Model.toSelect.type));
    this.vendors.unshift(this.Model.toSelect.vendor);

    this.types.forEach((type) => {
      if (!type.properties) { return true; }

      type.properties.forEach((prop) => {
        if (!prop.property_lists) { return true; }

        prop.property_lists.unshift(angular.copy(this.Model.toSelect.attr));
      });
    });
  };

  /**
   * Установить массив model_property_lists, который зависит от выбранного типа техники.
   */
  EditModelCtrl.prototype.setModelPropertyList = function() {
    this.model.type_id = this.model.type.type_id;
    this.Model.setModelPropertyListAttributes();
  };

  /**
   * Создать модель.
   */
  EditModelCtrl.prototype.ok = function() {
    let model = this.Model.getObjectToSend();

    if (this.model.model_id) {
      this.Server.Invent.Model.update(
        { model_id: this.model.model_id },
        { model: model },
        (response) => {
          this.Flash.notice(response.full_message);
          this.$uibModalInstance.close();
        },
        (response, status) => {
          this.Error.response(response, status);
          this.errorResponse(response);
        }
      )
    } else {
      this.Server.Invent.Model.save(
        { model: model },
        (response) => {
          this.Flash.notice(response.full_message);
          this.$uibModalInstance.close();
        },
        (response, status) => {
          this.Error.response(response, status);
          this.errorResponse(response);
        }
      );
    }
  };

  /**
   * Закрыть модальное окно.
   */
  EditModelCtrl.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };
})();

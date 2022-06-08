import { app } from '../../app/app';

(function () {
  'use strict';

  app
    .controller('EditInventBinderCtrl', EditInventBinderCtrl);

    EditInventBinderCtrl.$inject = ['Flash', 'Error', 'Server', 'item', '$uibModalInstance', 'WorkplaceItem'];

  function EditInventBinderCtrl(Flash, Error, Server, item, $uibModalInstance, WorkplaceItem) {
    this.WorkplaceItem = WorkplaceItem;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;
    this.$uibModalInstance = $uibModalInstance;

    this.item = item;
  }

  EditInventBinderCtrl.prototype.onSave = function() {
    this._onPrepareBinders();

    this.Server.Invent.Item.update(
      { item_id: this.item.item_id },
      { item: this._getObjectToSend() },
      (response) => {
        this.Flash.notice(response.full_message);
        this.$uibModalInstance.close();
      },
      (response, status) => {
        this.Error.response(response, status);
      }
    );
  };

  EditInventBinderCtrl.prototype.validate = function() {
    let sign_null = this.item.binders.find((el) => {
      return el.sign_id === null;
    })

    if (sign_null) {
      return false;
    } else {
      return true;
    }
  };

  EditInventBinderCtrl.prototype._getObjectToSend = function() {
    let obj = angular.copy(this.item);
    this.WorkplaceItem.delProperties(obj);

    return obj;
  };

  EditInventBinderCtrl.prototype._onPrepareBinders = function() {
    // Переобразовать для обновления привязки признаков
    this.item.binders_attributes = this.item.binders;
    // Свойства техники не нужны при обновлении признаков
    this.item.property_values_attributes = [];

    // Назначить id invent_item
    this.item.binders_attributes.forEach((value) => value.invent_item_id = this.item.item_id);
  };

  EditInventBinderCtrl.prototype.onClose = function() {
    this.$uibModalInstance.dismiss();
  };
})();

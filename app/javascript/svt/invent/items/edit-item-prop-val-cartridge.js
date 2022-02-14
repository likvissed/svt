import { app } from '../../app/app';

(function () {
  'use strict';

  app.controller('EditItemPropValCartridgeCtrl', EditItemPropValCartridgeCtrl);

  EditItemPropValCartridgeCtrl.$inject = ['item', '$uibModalInstance', 'Server', 'Error', 'Flash'];

  function EditItemPropValCartridgeCtrl(item, $uibModalInstance, Server, Error, Flash) {
    this.$uibModalInstance = $uibModalInstance;
    this.Server = Server;
    this.Error = Error;
    this.Flash = Flash;
    this.item = item;

    // Объект для добавления картриджа на склад и сразу на текущее РМ к технике, с уже присвоенным штрих-кодом
    this.cartridge = {
      item_id          : this.item.item_id,
      name_model       : '',
      countGetterSetter: (newCount) => {
        if (angular.isDefined(newCount)) {
          this.cartridge.count = Math.abs(newCount);
        }

        return Math.abs(this.cartridge.count);
      },
      count: 0
    }
  }

  EditItemPropValCartridgeCtrl.prototype.save = function() {
    if (!this.cartridge.name_model) {
      this.Flash.alert('Необходимо ввести наименование модели картриджа');

      return false;
    }
    if (this.cartridge.count <= 0 || this.cartridge.count > 5) {
      this.Flash.alert('Количество должно быть больше нуля и меньше 6');

      return false;
    }

    let confirm_str = 'Вы действительно хотите создать технику на складе и перенести на текущее РМ? Удалить картридж или отменить исполнение будет невозможно';
    if (!confirm(confirm_str)) { return false; }

    return this.Server.Invent.Item.addCartridge(
      { cartridge: this.cartridge },
      () => this.$uibModalInstance.close(),
      (response, status) => {
        this.Error.response(response, status);
      }
    ).$promise;
  };

  EditItemPropValCartridgeCtrl.prototype.close = function() {
    this.$uibModalInstance.dismiss();
  };
})();

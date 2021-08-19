import { app } from '../../app/app';

(function() {
  'use strict';

  app.controller('EditInventItemCtrl', EditInventItemCtrl);

  EditInventItemCtrl.$inject = ['$uibModal', 'InventItem', 'WorkplaceItem', 'Config', 'Flash', 'Server', 'Error'];

  function EditInventItemCtrl($uibModal, InventItem, WorkplaceItem, Config, Flash, Server, Error) {
    this.$uibModal = $uibModal;
    this.Item = InventItem;
    this.WorkplaceItem = WorkplaceItem;
    this.Config = Config;
    this.Flash = Flash;
    this.Server = Server;
    this.Error = Error;

    this.item_o = InventItem.data;
    this.additional = WorkplaceItem.getAdditional();
  }

  /**
   * Отправить запрос в Аудит для получения конфигурации оборудования.
   */
  EditInventItemCtrl.prototype.getAuditData = function() {
    if (this.item_o.item.invent_num) {
      this.Item.getAuditData();
    } else {
      this.Flash.alert('Сначала необходимо ввести инвентарный номер');
    }
  };

  /**
   * Запустить диалоговое окно "Ввод данных вручную".
   */
  EditInventItemCtrl.prototype.runManuallyPcDialog = function() {
    this.$uibModal.open({
      animation: this.Config.global.modalAnimation,

      templateUrl : 'manuallyPcDialog.slim',
      controller  : 'ManuallyPcDialogCtrl',
      controllerAs: 'manually',
      size        : 'md',
      backdrop    : 'static',
      resolve     : {

        item: () => this.item_o.item
      }
    });
  };

  /**
   * Записать в модель workplace.items данные о выбранной модели выбранного типа оборудования.
   */
  EditInventItemCtrl.prototype.changeItemModel = function() {
    this.WorkplaceItem.changeModel(this.item_o.item);
  };

  /**
   * Заполнить конфигурацию ПК дефолтными данными.
   */
  EditInventItemCtrl.prototype.FillWithDefaultData = function() {
    this.Item.fillPcWithDefaultData();
  };

  /**
   * Отметить, что штрих-код переклеен на правильный
   */
  EditInventItemCtrl.prototype.assignInvalidBarcodeAsTrue = function() {
    let confirm_str = 'Вы действительно хотите отметить штрих-код как переклеенный?';

    if (!confirm(confirm_str)) { return false; }

    return this.Server.Invent.Item.assignInvalidBarcodeAsTrue(
      { item_id: this.item_o.item.id },
      () => (this.item_o.item.invalid_barcode.actual = true),
      (response, status) => this.Error.response(response, status)
    ).$promise;
  };
})();

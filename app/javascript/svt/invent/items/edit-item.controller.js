import { app } from '../../app/app';

(function() {
  'use strict';

  app.controller('EditInventItemCtrl', EditInventItemCtrl);

  EditInventItemCtrl.$inject = ['$uibModal', 'InventItem', 'WorkplaceItem', 'Config', 'Flash'];

  function EditInventItemCtrl($uibModal, InventItem, WorkplaceItem, Config, Flash) {
    // this.additional = WorkplaceItem.getAdditional();
    this.$uibModal = $uibModal;
    this.Item = InventItem;
    this.WorkplaceItem = WorkplaceItem;
    this.Config = Config;
    this.Flash = Flash;

    this.item_o = InventItem.data;
    this.additional = WorkplaceItem.getAdditional();
  };

  /**
   * Отправить запрос в Аудит для получения конфигурации оборудования.
   *
   * @param item
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
      templateUrl: 'manuallyPcDialog.slim',
      controller: 'ManuallyPcDialogCtrl',
      controllerAs: 'manually',
      size: 'md',
      backdrop: 'static',
      resolve: {
        item: () => this.item_o.item
      }
    });
  };

  /**
   * Записать в модель workplace.items данные о выбранной модели выбранного типа оборудования.
   *
   * @param item - экземпляр техники, у которого изменили модель
   */
  EditInventItemCtrl.prototype.changeItemModel = function() {
    this.WorkplaceItem.changeModel(this.item_o.item);
  };
})();

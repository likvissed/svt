import { app } from '../../app/app';

(function() {
  'use strict';

  app.controller('ManuallyPcDialogCtrl', ManuallyPcDialogCtrl);

  ManuallyPcDialogCtrl.$inject = ['$uibModalInstance', 'Flash', 'Workplace', 'WorkplaceItem', 'InventItem', 'item'];

    /**
   * Ввод данных о составе СБ, Моноблока, Ноутбука вручную.
   *
   * @class SVT.WorkplaceEditCtrl
   */
  function ManuallyPcDialogCtrl($uibModalInstance, Flash, Workplace, WorkplaceItem, InventItem, item) {
    this.$uibModalInstance = $uibModalInstance;
    this.Flash = Flash;
    this.Workplace = Workplace;
    this.WorkplaceItem = WorkplaceItem;
    this.InventItem = InventItem;
    this.item = item;
  }

  /**
   * Скачать скрипт.
   */
  ManuallyPcDialogCtrl.prototype.downloadPcScript = function() {
    this.Workplace.downloadPcScript();
  };

  /**
   * Закрыть модальное окно.
   */
  ManuallyPcDialogCtrl.prototype.close = function() {
    this.$uibModalInstance.close();
  };

  /**
   * Загрузить файл для декодирования.
   *
   * @param file
   */
  ManuallyPcDialogCtrl.prototype.setPcFile = function(file) {
    if (!this.WorkplaceItem.isValidFile(file)) {
      this.Flash.alert('Необходимо загрузить текстовый файл, полученный в результате работы скачанной вами программы');

      return false;
    }

    this.InventItem.matchUploadFile(file).then(
      (response) => {
        if (!this.WorkplaceItem.matchDataFromUploadedFile(this.item, response.data)) {
          this.Flash.alert('Не удалось обработать данные. Убедитесь в том, что вы загружаете файл, созданный скачанной программой. Если ошибка не исчезает, обратитесь к администратору (т.***REMOVED***)');

          return false;
        }

        this.Flash.notice(response.full_message);
        this.$uibModalInstance.close();
      }
    );
  };
})();

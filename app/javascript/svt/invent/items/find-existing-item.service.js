import { app } from '../../app/app';

(function() {
  'use strict';

  app
    .service('FindExistingItemService', FindExistingItemService);

    FindExistingItemService.$inject = ['Server', 'Error'];

  function FindExistingItemService(Server, Error) {
    this.Server = Server;
    this.Error = Error;
  }

  /**
   * Загрузить занятую Б/У технику указанного типа.
   *
   * @param type_id - тип загружаемой техники
   * @param invent_num - инвентарный номер
   * @param item_id
   * @param division - отдел
   */
  FindExistingItemService.prototype.loadBusyItems = function(type_id, invent_num, item_barcode, division) {
    return this.Server.Invent.Item.busy(
      {
        type_id   : type_id,
        invent_num: invent_num,
        barcodes  : item_barcode,
        division  : division
      },
      (response) => {
        this.items = response.items;
        this.selectedItem = this.items.length == 1 ? this.items[0] : null;
      },
      (response, status) => this.Error.response(response, status)
    ).$promise;
  };

  /**
   * Удалить объект выбранной техники.
   */
  FindExistingItemService.prototype.clearSelectedItem = function() {
    this.selectedItem = null;
  };
})();

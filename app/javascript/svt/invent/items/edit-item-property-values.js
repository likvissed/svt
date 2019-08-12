import { app } from '../../app/app';

(function () {
  'use strict';

  app
    .controller('EditItemPropertyValuesCtrl', EditItemPropertyValuesCtrl);

    EditItemPropertyValuesCtrl.$inject = ['InventItem'];

  function EditItemPropertyValuesCtrl(InventItem) {
    this.data = InventItem.data;
  }


})();

import { app } from '../../app/app';

(function() {
'use strict';

app.controller('EditWorkplaceCountsController', EditWorkplaceCountsController);

EditWorkplaceCountsController.$inject = ['$uibModalInstance', 'dept'];

function EditWorkplaceCountsController($uibModalInstance, dept) {
  // this.$uibModalInstance = $uibModalInstance;
  this.dept = dept;

}
EditWorkplaceCountsController.prototype.save = function() {
  console.log('save');
}

EditWorkplaceCountsController.prototype.close = function() {
  console.log('close');
}

})();

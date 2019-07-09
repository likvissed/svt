

import { app } from '../../app/app';
import { FormValidationController } from '../../shared/functions/form-validation';

// (function() {
// 'use strict';

app.controller('EditWorkplaceCountsController', EditWorkplaceCountsController);

EditWorkplaceCountsController.$inject = ['$uibModalInstance', 'dept', '$http', 'Error'];

function EditWorkplaceCountsController($uibModalInstance, dept, $http, Error) {
  this.setFormName('dept');
  this.$http = $http;
  this.Error = Error;
  this.$uibModalInstance = $uibModalInstance;
  this.dept = dept;
  this.date = { // Открыть календарь для выбора даты
    DatePickerStart: false,
    DatePickerEnd: false,
  };
}
// Унаследовать методы класса FormValidationController
EditWorkplaceCountsController.prototype = Object.create(FormValidationController.prototype);

EditWorkplaceCountsController.prototype.save = function () {
  if (this.dept.workplace_count_id) {
    //  < update >
    this.$http.put(`/invent/workplace_counts/${this.dept.workplace_count_id}.json`, {
      workplace_count: this.dept,
    }).then(
      () => {
        this.$uibModalInstance.close();
      },
      (response, status) => {
        this.Error.response(response, status);
        this.errorResponse(response);
      },
    );
  } else {
    //  < create >
    this.$http.post('/invent/workplace_counts.json', {
      workplace_count: this.dept,
    }).then(
      () => {
        this.$uibModalInstance.close();
      },
      (response, status) => {
        this.Error.response(response, status);
        this.errorResponse(response);
      },
    );
  }
};

EditWorkplaceCountsController.prototype.close = function () {
  this.$uibModalInstance.dismiss();
};

// Добавить нового ответственного для отдела
EditWorkplaceCountsController.prototype.addResponsible = function () {
  const addUser = {
    id: '',
    id_tn: '',
    tn: '',
    fullname: '',
    phone: '',
    role_id: '',
  };
  this.dept.users_attributes.push(addUser);
};

// Удалить ответственного
EditWorkplaceCountsController.prototype.deleteResponsible = function (index) {
  // удалить один элемент массива, начиная с index
  this.dept.users_attributes.splice(index, 1);
};

// })();

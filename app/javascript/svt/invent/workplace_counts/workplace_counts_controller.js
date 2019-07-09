
import { app } from '../../app/app';

// (function () {
// 'use strict';

app.controller('WorkplaceCountsController', WorkplaceCountsController);

WorkplaceCountsController.$inject = ['$http', 'TablePaginator', 'Config', '$uibModal', 'Error'];

function WorkplaceCountsController($http, TablePaginator, Config, $uibModal, Error) {
  this.$http = $http;
  this.Error = Error;
  this.TablePaginator = TablePaginator;
  this.Config = Config;
  this.pagination = TablePaginator.config();
  this.loadWorkplaceCounts();
  this.$uibModal = $uibModal;
}

// Загрузить список отделов  < index >
WorkplaceCountsController.prototype.loadWorkplaceCounts = function () {
  this.$http.get('/invent/workplace_counts.json', {
    params: {
      start: this.TablePaginator.startNum(),
      length: this.Config.global.uibPaginationConfig.itemsPerPage,
      filters: this.filters,
    },
  }).then(
    data => this.successCallback(data),
    data => this.errorCallback(data),
  );
};

WorkplaceCountsController.prototype.successCallback = function (response) {
  this.divisions = response.data.array;
  this.TablePaginator.setData(response.data);
};

WorkplaceCountsController.prototype.errorCallback = function (response) {
  this.Error.response(response, response.status);
};

// Загрузить данные отделов  < edit >
WorkplaceCountsController.prototype.editWorkplaceCounts = function (workplaceCountId) {
  this.$http.get(`/invent/workplace_counts/${workplaceCountId}/edit.json`).then(
    data => this.openEditWorkplaceCounts(data.data),
    data => this.errorCallback(data),
  );
};

// Открыть модальное окно на редактирование
WorkplaceCountsController.prototype.openEditWorkplaceCounts = function (dept) {
  const division = dept;
  division.time_start = dept.time_start ? new Date(dept.time_start) : '';
  division.time_end = dept.time_end ? new Date(dept.time_end) : '';
  this.$uibModal.open({
    templateUrl: 'EditWorkplaceCounts.slim',
    controller: 'EditWorkplaceCountsController',
    controllerAs: 'edit',
    size: 'md',
    backdrop: 'static',
    resolve: {
      dept: () => division,
    },
  }).closed.then(() => this.loadWorkplaceCounts());
};

// Открыть модальное окно на добавление  < new >
WorkplaceCountsController.prototype.newEditWorkplaceCounts = function () {
  this.$http.get('/invent/workplace_counts/new').then(
    data => this.openEditWorkplaceCounts(data.data),
    data => this.errorCallback(data),
  );
};

// Удалить отдел  < destroy >
WorkplaceCountsController.prototype.deleteDept = function (dept) {
  // const question = confirm(`Вы действительно хотите удалить отдел «${dept.division}»?`);
  const question = `Вы действительно хотите удалить отдел «${dept.division}»?`;

  if (confirm(question)) {
    this.$http.delete(`/invent/workplace_counts/ ${dept.workplace_count_id}.json`, {
      workplace_count: dept.workplace_count_id,
    }).then(
      () => {
        this.loadWorkplaceCounts();
      },
      response => this.errorCallback(response),
    );
  }
};

// Поиск
WorkplaceCountsController.prototype.search = function () {
  this.loadWorkplaceCounts();
};

// })();

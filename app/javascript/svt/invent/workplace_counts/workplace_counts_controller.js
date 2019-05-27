
import { app } from '../../app/app';

(function() {
'use strict';

app.controller('WorkplaceCountsController', WorkplaceCountsController);

WorkplaceCountsController.$inject = ['$http', 'TablePaginator', 'Config', '$uibModal'];

function WorkplaceCountsController($http, TablePaginator, Config, $uibModal) {
  this.$http = $http;
  this.TablePaginator = TablePaginator;
  this.Config = Config;
  this.divisions;
  this.pagination = TablePaginator.config();
  this.loadWorkplaceCounts();
  this.$uibModal = $uibModal;

}

  // Загрузить список отделов
  WorkplaceCountsController.prototype.loadWorkplaceCounts = function() {
    this.$http.get('/invent/workplace_counts.json', {
      params: {
        start: this.TablePaginator.startNum(),
        length: this.Config.global.uibPaginationConfig.itemsPerPage
      }
    }).then(
      (data) => this.successCallback(data),
      (data) => this.errorCallback(data)
    );
  };
  
  WorkplaceCountsController.prototype.successCallback = function(response) {
    this.divisions = response.data.array;
    this.TablePaginator.setData(response.data);
  };


  WorkplaceCountsController.prototype.errorCallback = function(response) {
    console.log("ошибка: " + response.status); // Исправить
  };

  
  // Загрузить данные отделов
  WorkplaceCountsController.prototype.EditWorkplaceCounts = function(workplace_count_id) {
    this.$http.get('/invent/workplace_counts/' + workplace_count_id + '/edit.json').then(
      (data) => this.openEditWorkplaceCounts(data.data),
      (data) => this.errorCallback(data)
      );
    };
    
    // Открыть модельное окно на редактирование
    WorkplaceCountsController.prototype.openEditWorkplaceCounts = function(dept) {
      this.$uibModal.open({
        templateUrl: 'EditWorkplaceCounts.slim',
        controller: 'EditWorkplaceCountsController',
        controllerAs: 'edit',
        size: 'md',
        resolve: {
          dept: () => dept
        }
        // backdrop: 'static'
      });
    };

  
})();


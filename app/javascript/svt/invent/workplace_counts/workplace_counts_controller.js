
import { app } from '../../app/app';

(function() {
'use strict';

app.controller('WorkplaceCountsController', WorkplaceCountsController);

WorkplaceCountsController.$inject = ['$http', 'TablePaginator', 'Config'];

function WorkplaceCountsController($http, TablePaginator, Config) {
  this.$http = $http;
  this.TablePaginator = TablePaginator;
  this.Config = Config;
  this.divisions;
  this.pagination = TablePaginator.config();
  this.loadWorkplaceCounts();
}

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
    console.log("ошибка: " + response.status);
  };
  
})();


import { app } from '../../app/app';

(function() {
  'use strict';

  app.controller('WorkplaceIndexCtrl', WorkplaceIndexCtrl);

  WorkplaceIndexCtrl.$inject = ['$scope', 'WorkplacesFilter', 'Cookies'];

  /**
   * Управление страницей РМ.
   */
  function WorkplaceIndexCtrl($scope, Filter, Cookies) {
    this.$scope = $scope;
    this.Cookies = Cookies;
    this.Filter = Filter;

    Cookies.Workplace.init();

    this.filters = Filter.filters;
    this.selectedFilters = Filter.selectedTableFilters;
    this.listType = Cookies.Workplace.get('tableListTypeFilter') || false;
  }

  WorkplaceIndexCtrl.prototype.reloadWorkplaces = function() {
    let broadcast = this.listType ? 'WorkplaceTableCtrl::reloadWorkplacesList' : 'WorkplaceTableCtrl::reloadWorkplacesTable';
    this.$scope.$broadcast(broadcast, null);
  };

  WorkplaceIndexCtrl.prototype.setFilters = function() {
    this.Cookies.Workplace.set('tableListTypeFilter', this.listType);
  };

  WorkplaceIndexCtrl.prototype.loadRooms = function() {
    this.Filter.loadRooms();
  };

  WorkplaceIndexCtrl.prototype.clearRooms = function() {
    this.Filter.clearRooms();
  };

  WorkplaceIndexCtrl.prototype.generatePDF = function() {
    let division = this.filters.divisions.length == 1 ? this.filters.divisions[0] : this.selectedFilters.division;

    window.open('/invent/workplace_counts/generate_pdf/' + encodeURIComponent(division.division), '_blank');
  };
})();

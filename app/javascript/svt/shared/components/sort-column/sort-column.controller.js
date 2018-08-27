import { app } from '../../../app/app';

app.controller('SortColumnController', SortColumnController);

SortColumnController.$inject = ['Workplaces'];

function SortColumnController(Workplaces) {
  this.sortData = Workplaces.sorting;

  this.setSorting = function(sortType) {
    this.sortData.name = this.sortName;
    this.sortData.type = sortType;

    this.onSort();
  }
}

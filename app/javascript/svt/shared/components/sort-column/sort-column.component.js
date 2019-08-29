import { app } from '../../../app/app';
import templateString from './sort-column.component.html'

app
  .component('sortColumn', {
    template    : templateString,
    controller  : 'SortColumnController',
    controllerAs: 'sort',
    bindings    : {
      onSort  : '&',
      sortName: '@'
    }
  });

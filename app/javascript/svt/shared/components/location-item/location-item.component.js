import { app } from '../../../app/app';
import templateString from './location-item.component.html'

app
  .component('locationItem', {
    template    : templateString,
    controller  : 'LocationItemCtrl',
    controllerAs: 'loc',
    bindings    : {
      // Техника, для которой необходимо добавить/обновить расположение на складе
      selectedItem: '='
    }
  });

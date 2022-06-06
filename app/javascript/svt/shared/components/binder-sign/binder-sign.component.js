import { app } from '../../../app/app';
import templateString from './binder-sign.component.html'

app
  .component('binderSign', {
    template    : templateString,
    controller  : 'BinderSignCtrl',
    controllerAs: 'edit',
    bindings    : {
      selectedItem: '='
    }
  });

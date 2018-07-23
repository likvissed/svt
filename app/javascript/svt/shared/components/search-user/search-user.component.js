import { app } from '../../../app/app';
import templateString from './search-user.component.html'

app
  .component('searchUser', {
    template: templateString,
    controller: 'SearchUserController',
    controllerAs: 'su',
    bindings: {
      selectedUser: '='
    }
  });

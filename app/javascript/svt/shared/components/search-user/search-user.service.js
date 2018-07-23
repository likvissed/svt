import { app } from '../../../app/app';

app.service('SearchUserService', SearchUserService);

SearchUserService.$inject = ['Server', 'Flash', 'Error'];

function SearchUserService(Server, Flash, Error) {
  this.getUsers = (searchValue) => {
    return Server.UserIss.query(
      { search_key: searchValue },
      (response) => {
        this.users = response;
      },
      (response, status) => this.Error.response(response, status)
    ).$promise;
  };
}

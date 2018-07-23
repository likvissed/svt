import { app } from '../../../app/app';

app.controller('SearchUserController', SearchUserController);

SearchUserController.$inject = ['SearchUserService'];

function SearchUserController(SearchUserService) {
  this.searchUsers = (searchValue) => {
    SearchUserService.getUsers(searchValue).then(
      () => this.users = SearchUserService.users
    );
  }

  this.clearUser = () => {
    this.selectedUser = null;
  }
}

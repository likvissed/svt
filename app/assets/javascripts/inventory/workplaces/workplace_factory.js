app
  .service('Workplace', Workplace);

Workplace.$inject = ['$http', 'Server', 'Error'];

/**
 * Сервис для редактирования(подтверждения или отклонения) РМ.
 *
 * @class SVT.Workplace
 */
function Workplace($http, Server, Error) {
  this.$http = $http;
  this.Server = Server;
  this.Error = Error;
}

Workplace.prototype.init = function (id) {
  var self = this;

  return this.$http
    .get('/inventory/workplaces/' + id + '/edit.json')
    .success(function (workplace) {
      self.workplace = angular.copy(workplace);
      
      return workplace;
    })
    .error(function (response) {
      self.Error.response(response);
    });
};


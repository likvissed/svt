// (function () {
//   'use strict';

//   app.service('Workplaces', Workplaces);

//   Workplaces.$inject = ['WorkplacesFilter', 'Server', 'TablePaginator', 'Config', 'Flash', 'Error'];

//   function Workplaces(Filter, Server, TablePaginator, Config, Flash, Error) {
//     this.Filter = Filter;
//     this.Server = Server;
//     this.TablePaginator = TablePaginator;
//     this.Config = Config;
//     this.Flash = Flash;
//     this.Error = Error;
//   }

//   Workplaces.prototype.loadWorkplaces = function(init) {
//     var self = this;

//     return this.Server.Invent.Workplace.query(
//       {
//         start: this.TablePaginator.startNum(),
//         length: this.Config.global.uibPaginationConfig.itemsPerPage,
//         init_filters: init,
//         filters: this.Filter.get()
//       },
//       function(response) {
//         // Список РМ
//         self.workplaces = response.data;
//         // Данные для составления нумерации страниц
//         self.TablePaginator.setData(response);

//         if (init) {
//           self.Filter.set(response.filters);
//         }
//       },
//       function(response, status) {
//         self.Error.response(response, status);
//       }
//     ).$promise;
//   };

//   Workplaces.prototype.loadListWorkplaces = function() {
//     var self = this;

//     return this.Server.Invent.Workplace.list(
//       {
//         start: this.TablePaginator.startNum(),
//         length: this.Config.global.uibPaginationConfig.itemsPerPage,
//         filters: this.Filter.get()
//       },
//       function(response) {
//         // Список РМ
//         self.workplaces = response.data;
//         self._prepareWorkplaceToRender();

//         // Данные для составления нумерации страниц
//         self.TablePaginator.setData(response);
//       },
//       function(response, status) {
//         self.Error.response(response, status);
//       }
//     ).$promise;
//   };

//   Workplaces.prototype._prepareWorkplaceToRender = function() {
//     var
//       items,
//       composition;

//     this.workplaces.forEach(function(el) {
//       items = [];

//       el.items.forEach(function(value) { items.push('<li>' + value + '</li>'); });
//       el.renderData = '<span>' + el.workplace + '</span><br>';
//       composition = items.length == 0 ? 'Состав отсутствует' : 'Состав:<ul>' + items.join('') + '</ul>';
//       el.renderData += composition;
//     });
//   }
// })();
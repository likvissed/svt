import { app } from '../../app/app';

(function() {
  app.factory('Server', Server);

  Server.$inject = ['$resource'];

  /**
   * Фабрика для работы с CRUD событиями.
   *
   * @class SVT.Server
   */
  function Server($resource) {
    return {
      Invent: {
        /**
         * Ресурс модели рабочих мест.
         */
        Workplace: $resource('/invent/workplaces/:workplace_id.json', {}, {
          query: {
            method : 'GET',
            isArray: false
          },
          list: {
            method : 'GET',
            isArray: false,
            url    : '/invent/workplaces/list_wp.json'
          },
          new: {
            method: 'GET',
            url   : '/invent/workplaces/new.json'
          },
          edit: {
            method: 'GET',
            url   : '/invent/workplaces/:id/edit.json'
          },
          update : { method: 'PUT' },
          confirm: {
            method: 'PUT',
            url   : '/invent/workplaces/confirm'
          },
          hardDelete: {
            method: 'DELETE',
            url   : '/invent/workplaces/:workplace_id/hard_destroy'
          },
          categoryForRoom: {
            method: 'GET',
            url   : '/invent/workplaces/category_for_room'
          }
        }),
        /**
         * Ресурс модели отделов с количеством рабочих мест.
         */
        WorkplaceCount: $resource('/invent/workplace_counts/:workplace_count_id.json', {}, { update: { method: 'PUT' } }),
        /**
         * Ресурс модели экземпляров техники.
         */
        Item          : $resource('/invent/items/:item_id.json', {}, {
          query: {
            method : 'GET',
            isArray: false
          },
          edit: {
            method: 'GET',
            url   : '/invent/items/:item_id/edit.json'
          },
          busy: {
            method: 'GET',
            url   : '/invent/items/busy'
          },
          avaliable: {
            method : 'GET',
            url    : '/invent/items/avaliable/:type_id',
            isArray: true
          },
          pcConfigFromAudit: {
            method: 'GET',
            url   : '/invent/items/pc_config_from_audit/:invent_num'
          },
          pcConfigFromUser: {
            method          : 'POST',
            url             : '/invent/items/pc_config_from_user.json',
            headers         : { 'Content-Type': undefined },
            transformRequest: angular.identity
          },
          toStock: {
            method: 'POST',
            url   : '/invent/items/to_stock'
          },
          toWriteOff: {
            method: 'POST',
            url   : '/invent/items/to_write_off'
          },
          update: { method: 'PUT' }
        }),
        Vendor: $resource('/invent/vendors/:vendor_id.json', {}),
        Model : $resource('/invent/models/:model_id.json', {}, {
          query: {
            method : 'GET',
            isArray: false
          },
          newModel: {
            method: 'GET',
            url   : '/invent/models/new'
          },
          edit: {
            method: 'GET',
            url   : '/invent/models/:model_id/edit'
          },
          update: { method: 'PUT' }
        })
      },
      /**
       * Ресурс модели работников отдела.
       */
      UserIss: $resource('/user_isses/:id.json', {}, {
        usersFromDivision: {
          method : 'GET',
          url    : ' /user_isses/users_from_division/:division',
          isArray: true
        }
      }),
      /**
       * Ресурс модели списка пользователей
       */
      User: $resource('/users/:id.json', {}, {
        query: {
          method : 'GET',
          isArray: false
        },
        newUser: {
          method: 'GET',
          url   : '/users/new'
        },
        edit: {
          method: 'GET',
          url   : '/users/:id/edit'
        },
        update: { method: 'PUT' }
      }),
      Warehouse: {
        Item: $resource('/warehouse/items/:id.json', {}, {
          query: {
            method : 'GET',
            isArray: false
          },
          edit: {
            method: 'GET',
            url   : '/warehouse/items/:id/edit.json'
          },
          update: {
            method: 'PUT'
          },
          split: {
            method: 'PUT',
            url   : '/warehouse/items/:id/split'
          }
        }),
        Order: $resource('/warehouse/orders/:id.json', {}, {
          query: {
            method : 'GET',
            url    : '/warehouse/orders/:operation.json',
            isArray: false
          },
          newOrder: {
            method : 'GET',
            url    : '/warehouse/orders/new',
            isArray: false
          },
          edit: {
            method: 'GET',
            url   : '/warehouse/orders/:id/edit.json'
          },
          print: {
            method: 'GET',
            url   : '/warehouse/orders/:id/print'
          },
          prepareToDeliver: {
            method: 'POST',
            url   : '/warehouse/orders/:id/prepare_to_deliver.json'
          },
          saveIn: {
            method: 'POST',
            url   : '/warehouse/orders/create_in'
          },
          saveOut: {
            method: 'POST',
            url   : '/warehouse/orders/create_out'
          },
          saveWriteOff: {
            method: 'POST',
            url   : '/warehouse/orders/create_write_off'
          },
          updateIn: {
            method: 'PUT',
            url   : '/warehouse/orders/:id/update_in'
          },
          updateOut: {
            method: 'PUT',
            url   : '/warehouse/orders/:id/update_out'
          },
          updateWriteOff: {
            method: 'PUT',
            url   : '/warehouse/orders/:id/update_write_off'
          },
          confirm: {
            method: 'PUT',
            url   : '/warehouse/orders/:id/confirm'
          },
          executeIn: {
            method: 'POST',
            url   : '/warehouse/orders/:id/execute_in'
          },
          executeOut: {
            method: 'POST',
            url   : '/warehouse/orders/:id/execute_out'
          },
          executeWriteOff: {
            method: 'POST',
            url   : '/warehouse/orders/:id/execute_write_off'
          }
        }),
        Supply: $resource('/warehouse/supplies/:id.json', {}, {
          query    : { isArray: false },
          newSupply: {
            method : 'GET',
            url    : '/warehouse/supplies/new',
            isArray: false
          },
          edit: {
            method: 'GET',
            url   : '/warehouse/supplies/:id/edit.json'
          },
          update: { method: 'PUT' }
        }),
        Location: $resource('', {}, {
          loadLocations: {
            method: 'GET',
            url   : '/warehouse/locations/load_locations'
          },
          rooms: {
            method : 'GET',
            url    : ' /warehouse/locations/load_rooms/:building_id',
            isArray: true
          }
        })
      },
      Statistics: $resource('/statistics', {}, {
        get: {
          isArray: true
        }
      })
    }
  }
})();

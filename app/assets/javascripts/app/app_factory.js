(function() {
  'use strict';

  app
    .service('Flash', Flash) // Сервис уведомлений пользователя (как об успешных операциях, так и об ошибках).
    .factory('Error', Error) // Сервис обработки ошибок.
    .factory('Server', Server) // Фабрика для работы с CRUD экшнами.
    .factory('myHttpInterceptor', myHttpInterceptor) // Фабрика для настройки параметрв для индикатора выполнения
    .factory('Cookies', Cookies)
    .factory('TablePaginator', TablePaginator)

  Flash.$inject = ['$timeout'];
  Error.$inject = ['Flash'];
  Server.$inject = ['$resource'];
  myHttpInterceptor.$inject = ['$q'];
  Cookies.$inject = ['$cookies'];
  TablePaginator.$inject = ['Config'];

// =====================================================================================================================

  /**
   * Сервис уведомления пользователей как об успешных операциях, так и об ошибочных.
   *
   * @class SVT.Flash
   */
  function Flash($timeout) {
    this.$timeout = $timeout;

    this.flash = {
      notice: '',
      alert:  ''
    };
  }

  /**
   * Показать notice уведомление и скрыть его через 2 секунды.
   *
   * @param message - сообщение, которое необходимо вывести.
   */
  Flash.prototype.notice = function(message) {
    var self = this;

    this.flash.alert = null;
    this.flash.notice = message;

    this.$timeout(function() {
      self.flash.notice = null;
    }, 2000);
  };

  /**
   * Показать alert уведомление.
   *
   * @param message - сообщение, которое необходимо вывести.
   */
  Flash.prototype.alert = function(message) {
    this.flash.notice = null;
    this.flash.alert = message;
  };

// =====================================================================================================================

  /**
   * Сервис обработки ошибок, полученных с сервера.
   *
   * @class SVT.Error
   */
  function Error(Flash) {
    return {
      /**
       * Обработать ответ сервера, содержащий ошибку и вывести сообщение об ошибке пользователю.
       *
       * @param response - объект, содержащий ответ сервера
       * @param status - статус ответа (необязательный параметр, используется, если не удается найти статус в
       * параметре "response")
       */
      response: function(response, status) {
        var
          // Код ответа
          code,
          // Расшифровка статуса ошибки.
          descr;

        code = (response && response.status) ? parseInt(response.status): parseInt(status);
        switch(code) {
          case 401:
            Flash.alert('Ваш сеанс закончился. Пожалуйста, войдите в систему снова.');
            break;
          case 403:
            Flash.alert('Доступ запрещен.');
            break;
          case 404:
            Flash.alert('Запись не найдена.');
            break;
          case 422:
            var message = response.data ? response.data.full_message : response.full_message;

            if (message) {
              Flash.alert(message);
            } else {
              descr = (response && response.statusText) ? ' (' + response.statusText + ')' : '';
              Flash.alert('Ошибка. Код: ' + code + descr + '. Обратитесь к администратору (тел. ***REMOVED***).');
            }

            break;
          default:
            descr = (response && response.statusText) ? ' (' + response.statusText + ')' : '';
            Flash.alert('Ошибка. Код: ' + code + descr + '. Обратитесь к администратору (тел. ***REMOVED***).');
            break;
        }
      }
    }
  }

// =====================================================================================================================

  /**
   * Фабрика для работы с CRUD экшнами.
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
            method: 'GET',
            isArray: false
          },
          list: {
            method: 'GET',
            isArray: false,
            url: '/invent/workplaces/list_wp.json'
          },
          new: {
            method: 'GET',
            url: '/invent/workplaces/new.json'
          },
          edit: {
            method: 'GET',
            url: '/invent/workplaces/:id/edit.json'
          },
          update: { method: 'PUT' },
          pcConfigFromAudit: {
            method: 'GET',
            url: '/invent/workplaces/pc_config_from_audit/:invent_num'
          },
          pcConfigFromUser: {
            method: 'POST',
            url: '/invent/workplaces/pc_config_from_user.json',
            headers: { 'Content-Type': undefined },
            transformRequest: angular.identity
          },
          confirm: {
            method: 'PUT',
            url: '/invent/workplaces/confirm'
          },
          hardDelete: {
            method: 'DELETE',
            url: '/invent/workplaces/:workplace_id/hard_destroy'
          }
        }),
        /**
         * Ресурс модели отделов с количеством рабочих мест.
         */
        WorkplaceCount: $resource('/invent/workplace_counts/:workplace_count_id.json', {}, { update: { method: 'PUT' } }),
        /**
         * Ресурс модели экземпляров техники.
         */
        Item: $resource('/invent/items/:item_id.json', {}, {
          query: {
            method: 'GET',
            isArray: false
          },
          edit: {
            method: 'GET',
            url: '/invent/items/:item_id/edit.json'
          },
          busy: {
            method: 'GET',
            url: '/invent/items/busy/:type_id',
            isArray: true
          },
          avaliable: {
            method: 'GET',
            url: '/invent/items/avaliable/:type_id',
            isArray: true
          }
        }),
        Vendor: $resource('/invent/vendors/:vendor_id.json', {}),
        Model: $resource('/invent/models/:model_id.json', {}, {
          query: { method: 'GET', isArray: false },
          newModel: {
            method: 'GET',
            url: '/invent/models/new'
          },
          edit: {
            method: 'GET',
            url: '/invent/models/:model_id/edit'
          },
          update: { method: 'PUT' }
        })
      },
      /**
       * Ресурс модели работников отдела.
       */
      UserIss: $resource('', {}, {
        usersFromDivision: {
          method: 'GET',
          url: ' /user_isses/users_from_division/:division',
          isArray: true
        }
      }),
      /**
       * Ресурс модели списка пользователей
       */
      User: $resource('/users/:id.json', {}, {
        query: {
          method: 'GET',
          isArray: false
        },
        newUser: {
          method: 'GET',
          url: '/users/new'
        },
        edit: {
          method: 'GET',
          url: '/users/:id/edit'
        },
        update: { method: 'PUT' }
      }),
      Warehouse: {
        Item: $resource('/warehouse/items/:id.json', {}, {
          query: {
            method: 'GET',
            isArray: false
          }
        }),
        Order: $resource('/warehouse/orders/:id.json', {}, {
          query: {
            method: 'GET',
            url: '/warehouse/orders/:operation.json',
            isArray: false
          },
          newOrder: {
            method: 'GET',
            url: '/warehouse/orders/new',
            isArray: false
          },
          edit: {
            method: 'GET',
            url: '/warehouse/orders/:id/edit.json'
          },
          print: {
            method: 'GET',
            url: '/warehouse/orders/:id/print'
          },
          prepareToDeliver: {
            method: 'POST',
            url: '/warehouse/orders/:id/prepare_to_deliver.json'
          },
          saveIn: {
            method: 'POST',
            url: '/warehouse/orders/create_in'
          },
          saveOut: {
            method: 'POST',
            url: '/warehouse/orders/create_out'
          },
          updateIn: {
            method: 'PUT',
            url: '/warehouse/orders/:id/update_in'
          },
          updateOut: {
            method: 'PUT',
            url: '/warehouse/orders/:id/update_out'
          },
          confirmOut: {
            method: 'PUT',
            url: '/warehouse/orders/:id/confirm_out'
          },
          executeIn: {
            method: 'POST',
            url: '/warehouse/orders/:id/execute_in'
          },
          executeOut: {
            method: 'POST',
            url: '/warehouse/orders/:id/execute_out'
          }
        }),
        Supply: $resource('/warehouse/supplies/:id.json', {}, {
          query: { isArray: false },
          newSupply: {
            method: 'GET',
            url: '/warehouse/supplies/new',
            isArray: false
          },
          edit: {
            method: 'GET',
            url: '/warehouse/supplies/:id/edit.json'
          },
          update: { method: 'PUT' }
        })
      }
    }
  }

// =====================================================================================================================

  /**
   * Фабрика для настройки параметрв для индикатора выполнения ajax запросов
   *
   * @class SVT.myHttpInterceptor
   */
  function myHttpInterceptor($q) {
    var self = this;

    self.requests = {
      count: 0
    };

    /**
     * Увеличить счетчик запросов.
     */
    function incCount() {
      self.requests.count ++;
    }

    /**
     * Уменьшить счетчик запросов.
     */
    function decCount() {
      self.requests.count --;
    }

    return {
      getRequestsCount: self.requests,
      incCount: function() {
        incCount();
      },
      decCount: function() {
        decCount();
      },
      request: function(config) {
        incCount();

        return config;
      },
      requestError: function(rejection) {
        decCount();

        return $q.reject(rejection);
      },
      response: function(response) {
        decCount();

        return response;
      },
      responseError: function(rejection) {
        decCount();

        return $q.reject(rejection);
      }
    };
  }

// =====================================================================================================================

  /**
   * Сервис для работы с cookies.
   *
   * @class SVT.Cookies
   */
  function Cookies($cookies) {
    var obj;

    /**
     * Инициализация cookies указанного объекта.
     *
     * @param name
     */
    function init(name) {
      switch (name) {
        case 'workplace':
          obj = {
            // Фильтр по отделам
            tableDivisionFilter: '0',
            // Фильтр по статусам
            tableStatusFilter: 'all',
            // Фильтр по типам
            tableTypeFilter: '0',
            // Фильтр списка РМ по отделам
            tableListDivisionFilter: '0',
            // Флаг, определяющий, как показывать РМ: в виде списка или таблицы
            tableListTypeFilter: false
          };
          break;
      }

      if (angular.isUndefined($cookies.getObject(name))) {
        // Установить начальные значения переменных куки
        $cookies.putObject(name, obj);
      } else {
        // Проверяем, существуют ли в cookies все ключи объекта obj
        angular.forEach(obj, function(value, key) {
          if (angular.isUndefined($cookies.getObject(name)[key])) {
            setCookie(name, key, value);
          }
        });

        // Получить актуальные значения переменных куки
        obj = $cookies.getObject(name);
      }
    }

    /**
     * Получить объект cookies с указанным именем name.
     *
     * @param name - имя объекта
     * @param key - имя свойства объекта
     */
    function getCookie(name, key) {
      if (angular.isUndefined(key))
        return $cookies.getObject(name);

      return angular.isUndefined($cookies.getObject(name)) ? 'Cookies отсутсвуют' : $cookies.getObject(name)[key];
    }

    /**
     * Установить объект cookies с указанным именем name.
     *
     * @param name - имя объекта
     * @param key - имя свойства объекта
     * @param value - устанавливаемое значение
     */
    function setCookie(name, key, value) {
      obj[key] = value;

      if (name == 'workplace') {
        console.log('here');
        $cookies.remove('workplace', { path: '/' });
        $cookies.remove('workplace', { path: '/invent' });
        $cookies.remove('workplace', { path: '/invent/workplaces' });
      }

      $cookies.putObject(name, obj);
    }

    return {
      /**
       * Страница /workplaces.
       */
      Workplace: {
        init: function() {
          init('workplace');
        },
        get: function(key) {
          return getCookie('workplace', key);
        },
        set: function(key, value) {
          setCookie('workplace', key, value);
        }
      }
    }
  }

// =====================================================================================================================

  /**
   * Фабрика для работы с нумерацией страниц на таблицах
   */
  function TablePaginator(Config) {
    var _pagination = {
      filteredRecords: 0,
      totalRecords: 0,
      currentPage: 1,
      maxSize: 5
    };

    return {
      /**
       * Получить конфиг пагинатора
       */
      config: function() {
        return _pagination;
      },
      /**
       * Получить индекс записи, с которой необходимо показать данные.
       */
      startNum: function() {
        return (_pagination.currentPage - 1) * Config.global.uibPaginationConfig.itemsPerPage;
      },
      /**
       * Установить данные пагинатора
       *
       * @param data { recordsFiltered: int, recordsTotal: int }
       */
      setData: function(data) {
        _pagination.filteredRecords = data.recordsFiltered;
        _pagination.totalRecords = data.recordsTotal;
      }
    }
  }
})();

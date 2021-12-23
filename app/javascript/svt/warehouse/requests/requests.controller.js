import { app } from '../../app/app';

(function () {
  'use strict';

  app.controller('WarehouseRequestsCtrl', WarehouseRequestsCtrl);

  WarehouseRequestsCtrl.$inject = ['$uibModal', 'TablePaginator', 'ActionCableChannel', 'Config', 'Flash', 'Error', 'Server'];

  function WarehouseRequestsCtrl($uibModal, TablePaginator, ActionCableChannel, Config, Flash, Error, Server) {
    this.$uibModal = $uibModal;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;
    this.pagination = TablePaginator.config();
    this.TablePaginator = TablePaginator;
    this.ActionCableChannel = ActionCableChannel;

    // Фильтры с вариантом выбора значений
    this.filters = {
      setCategoryFilter: { '': 'Все категории' },
      statuses         : []
    };

    // Данные, которые будут отправлены на сервер для фильтрации
    this.selectedFilters = {
      request_id  : '',
      order_id    : '',
      category    : '',
      for_statuses: []
    };

    this.statusFilter = {
      settings: {
        buttonClasses: 'btn btn-default btn-sm btn-block',
        dynamicTitle : false
      },
      translations: {
        buttonDefaultText      : 'Статусы',
        checkAll               : 'Выбрать всё',
        uncheckAll             : 'Сбросить всё',
        dynamicButtonTextSuffix: 'статусы'
      },
      events: {
        onSelectionChanged: () => this.reloadRequests()
      }
    };

    this._loadRequests();
    this._initActionCable();
  }

  WarehouseRequestsCtrl.prototype._loadRequests = function() {
    this.Server.Warehouse.Request.query(
      {
        start  : this.TablePaginator.startNum(),
        length : this.Config.global.uibPaginationConfig.itemsPerPage,
        filters: this.selectedFilters
      },
      (response) => {
        this.requests = response.data || [];
        // Данные для составления нумерации страниц
        this.TablePaginator.setData(response);

        if (response.filters) {
          this.filters.setCategoryFilter = Object.assign(this.filters.setCategoryFilter, response.filters.categories);
          this.filters.statuses = Object.assign(this.filters.statuses, response.filters.statuses);
        }
      },
      (response, status) => this.Error.response(response, status)
    );
  }

  /**
   * Инициировать подключение к каналу RequestsChannel.
   */
     WarehouseRequestsCtrl.prototype._initActionCable = function() {
      let consumer = new this.ActionCableChannel('Warehouse::RequestsChannel');

      consumer.subscribe(() => this._loadRequests());
    };

  /**
   * Применение фильтров
   */
  WarehouseRequestsCtrl.prototype.reloadRequests = function() {
    this._loadRequests();
    this._initActionCable();
  };

  WarehouseRequestsCtrl.prototype.editRequest = function(request) {
    this.Server.Warehouse.Request.edit(
      { id: request.request_id },
      (response) => {
        this.$uibModal.open({
          templateUrl : 'editRequestModal.slim',
          controller  : 'EditRequestCtrl',
          controllerAs: 'edit',
          size        : 'xl',
          backdrop    : 'static',
          resolve     : {
            data: {
              request             : response.request,
              workers             : response.workers,
              list_recommendations: response.list_recommendations
             }
          }
        });

      },
      (response, status) => {
        this.Error.response(response, status);
      }
    );
  }

})();

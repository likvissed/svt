(function () {
  'use strict';

  app
    .controller('WarehouseSuppliesCtrl', WarehouseSuppliesCtrl)
    .controller('EditSupplyCtrl', EditSupplyCtrl)
    .controller('ShowSupplyCtrl', ShowSupplyCtrl)
    .controller('EditSupplyOperationCtrl', EditSupplyOperationCtrl);

  WarehouseSuppliesCtrl.$inject = ['$uibModal', 'TablePaginator', 'ActionCableChannel', 'Config', 'WarehouseSupply', 'WarehouseOrder', 'Flash', 'Error', 'Server'];
  EditSupplyCtrl.$inject = ['$uibModal', '$uibModalInstance', 'WarehouseSupply', 'Flash', 'Error', 'Server'];
  ShowSupplyCtrl.$inject = ['$uibModal', '$uibModalInstance', 'data', 'WarehouseSupply', 'Error', 'Server'];
  EditSupplyOperationCtrl.$inject = ['$uibModalInstance', 'operation', 'WarehouseSupply', 'WarehouseOperation', 'Error', 'Server'];

  function WarehouseSuppliesCtrl($uibModal, TablePaginator, ActionCableChannel, Config, WarehouseSupply, WarehouseOrder, Flash, Error, Server) {
    this.$uibModal = $uibModal;
    this.ActionCableChannel = ActionCableChannel;
    this.TablePaginator = TablePaginator;
    this.Config = Config;
    this.Supply = WarehouseSupply;
    this.Order = WarehouseOrder;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;
    this.pagination = TablePaginator.config();

    this._loadSupplies();
    this._initActionCable();
  };

  /**
   * Инициировать подключение к каналу OrdersChannel
   */
  WarehouseSuppliesCtrl.prototype._initActionCable = function() {
    var
      self = this,
      consumer = new this.ActionCableChannel('Warehouse::SuppliesChannel');

    consumer.subscribe(function() {
      self._loadSupplies();
    });
  }

  WarehouseSuppliesCtrl.prototype._loadSupplies = function() {
    var self = this;

    this.Server.Warehouse.Supply.query(
      {
        start: this.TablePaginator.startNum(),
        length: this.Config.global.uibPaginationConfig.itemsPerPage
      },
      function(response) {
        // Список всех ордеров
        self.supplies = response.data || [];
        // Данные для составления нумерации страниц
        self.TablePaginator.setData(response);
      },
      function(response, status) {
        self.Error.response(response, status);
      }
    )
  }

  WarehouseSuppliesCtrl.prototype._openEditModal = function() {
    this.$uibModal.open({
      templateUrl: 'editSupplyModal.slim',
      controller: 'EditSupplyCtrl',
      controllerAs: 'edit',
      size: 'md',
      backdrop: 'static'
    });
  }

  /**
   * Открыть форму создания поставки
   */
  WarehouseSuppliesCtrl.prototype.newSupply = function() {
    var self = this;

    this.Server.Warehouse.Supply.newSupply({},
      function(data) {
        self.Supply.init(data);
        self._openEditModal();
      },
      function(response, status) {
        self.Error.response(response, status);
      }
    )
  };

  /**
   * Редактировать поставку
   *
   * @param supply
   */
  WarehouseSuppliesCtrl.prototype.editSupply = function(supply) {
    var self = this;

    this.Server.Warehouse.Supply.edit(
      { id: supply.id },
      function (data) {
        self.Supply.init(data);
        self._openEditModal();
      },
      function (response, status) {
        self.Error.response(response, status);
      }
    )
  };

  /**
   * Удалить поставку
   *
   * @param supply
   */
  WarehouseSuppliesCtrl.prototype.destroySupply = function(supply) {
    var
      self = this,
      confirm_str = "Вы действительно хотите удалить поставку \"" + supply.id + "\"?";

    if (!confirm(confirm_str))
      return false;

    this.Server.Warehouse.Supply.delete(
      { id: supply.id },
      function(response) {
        self.Flash.notice(response.full_message);
      },
      function(response, status) {
        self.Error.response(response, status);
      });
  };

// =====================================================================================================================

  function EditSupplyCtrl($uibModal, $uibModalInstance, WarehouseSupply, Flash, Error, Server) {
    this.setFormName('supply');

    this.$uibModal = $uibModal;
    this.$uibModalInstance = $uibModalInstance;
    this.Supply = WarehouseSupply;
    this.supply = this.Supply.supply;
    this.extra = this.Supply.additional;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;

    // Настройка календаря 'date'
    this.date = {
      // Переменная определяющая начальное состояние календаря (false - скрыть, true - показать)
      openDatePicker: false
    };
  }

  // Унаследовать методы класса FormValidationController
  EditSupplyCtrl.prototype = Object.create(FormValidationController.prototype);
  EditSupplyCtrl.prototype.constructor = EditSupplyCtrl;

  /**
   * Обновить данные поставки
   */
  EditSupplyCtrl.prototype.reloadSupply = function() {
    var self = this;

    this.Server.Warehouse.Supply.edit(
      { id: this.supply.id },
      function (data) {
        self.Supply.init(data);
      },
      function (response, status) {
        self.Error.response(response, status);
      }
    )
  };

  /**
   * Показать календарь.
   *
   * @param type - тип календаря, time_start или time_end
   */
  EditSupplyCtrl.prototype.openDatePicker = function() {
    this.date.openDatePicker = true;
  };

  /**
   * Добавить/Редактировать позицию
   *
   * @param operation
   */
  EditSupplyCtrl.prototype.editPosition = function(operation) {
    var self = this;

    var modalInstance = this.$uibModal.open({
      templateUrl: 'editSupplyOperation.slim',
      controller: 'EditSupplyOperationCtrl',
      controllerAs: 'op',
      size: 'md',
      backdrop: 'static',
      resolve: { operation: operation }
    });

    modalInstance.result.then(function(data) {
      operation ? self.Supply.updatePosition(operation, data) : self.Supply.addPosition(data);
    });
  }

  /**
   * Удалить позицию.
   *
   * @param operation - позиция
   */
  EditSupplyCtrl.prototype.delPosition = function(operation) {
    this.Supply.delPosition(operation);
  }

  EditSupplyCtrl.prototype.ok = function() {
    var self = this;

    if (this.supply.id) {
      this.Server.Warehouse.Supply.update(
        { id: this.supply.id },
        { supply: this.supply },
        function success(response) {
          self.Flash.notice(response.full_message);
          self.$uibModalInstance.close();
        },
        function error(response, status) {
          self.Error.response(response, status);
          self.errorResponse(response);
        }
      )
    } else {
      this.Server.Warehouse.Supply.save(
        { supply: this.supply },
        function success(response) {
          self.Flash.notice(response.full_message);
          self.$uibModalInstance.close();
        },
        function error(response, status) {
          self.Error.response(response, status);
          self.errorResponse(response);
        }
      )
    }
  }

  /**
   * Закрыть модальное окно.
   */
  EditSupplyCtrl.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };

// =====================================================================================================================

  function ShowSupplyCtrl($uibModal, $uibModalInstance, data, WarehouseSupply, Error, Server) {
    this.$uibModal = $uibModal;
    this.$uibModalInstance = $uibModalInstance;
    this.Supply = WarehouseSupply;
    this.Server = Server;
    this.Error = Error;
    this.supply = this.Supply.supply;
    this.extra = this.Supply.additional;
    this.selectedItem = data.item;
  }

  /**
   * Проверка, совпадает ли указанный item с выбранным (в переменной selectedItem)
   */
  ShowSupplyCtrl.prototype.isThisItem = function(item) {
    return item.id == this.selectedItem.id;
  };

    /**
   * Обновить данные поставки
   */
  ShowSupplyCtrl.prototype.reloadSupply = function() {
    var self = this;

    this.Server.Warehouse.Supply.edit(
      { id: this.supply.id },
      function (data) {
        self.Supply.init(data);
      },
      function (response, status) {
        self.Error.response(response, status);
      }
    )
  };

  /**
   * Закрыть модальное окно.
   */
  ShowSupplyCtrl.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };

// =====================================================================================================================

  function EditSupplyOperationCtrl($uibModalInstance, operation, WarehouseSupply, WarehouseOperation, Error, Server) {
    var self = this;

    this.$uibModalInstance = $uibModalInstance;
    this.Supply = WarehouseSupply;
    this.Operation = WarehouseOperation;
    this.Error = Error;
    this.Server = Server;

    this.extra = WarehouseSupply.additional;
    this.extra.update = operation ? true : false;
    this.result = {
      shiftGetterSetter: function(newShift) {
        if (angular.isDefined(newShift)) {
          self.result.shift = Math.abs(newShift);
        }

        return Math.abs(self.result.shift);
      },
      shift: this.Operation.getTemplate().shift
    };
    this._setDefaultResult(operation);
  }

  EditSupplyOperationCtrl.prototype._setDefaultResult = function(operation) {
    this.result.type = {
      type_id: operation ? operation.item.invent_type_id : 0,
      short_description: operation ? operation.item.item_type : ''
    }
    this.result.model = {
      model_id: operation ? operation.item.invent_model_id : 0,
      item_model: operation ? operation.item.item_model : ''
    }
    this.result.shift = operation ? operation.shift : this.Operation.getTemplate().shift;

    if (operation) {
      this.result.warehouseType = operation.item.warehouse_type;
      this.result.barcode = operation.item.barcode
      this.loadModels();
    }
  }

  /**
   * Очистить объект result
   */
  EditSupplyOperationCtrl.prototype.clearResult = function() {
    this._setDefaultResult();
  }

  /**
   * Загрузить список моделей
   */
  EditSupplyOperationCtrl.prototype.loadModels = function() {
    if (!this.result.type.type_id) { return false; }

    var self = this;

    this.extra.eqModels = [];
    this.result.model = {
      model_id: 0,
      item_model: ''
    }

    this.Server.Invent.Model.query(
      { type_id: self.result.type.type_id },
      function(data) {
        self.extra.eqModels = [{ model_id: 0, item_model: 'Выберите модель' }].concat(data);
      },
      function(response, status) {
        self.Error.response(response, status);
      }
    );
  }

  /**
   * Условия, при которых нельзя добавить позицию к поставке
   */
  EditSupplyOperationCtrl.prototype.disableButton = function() {
    if (this.result.warehouseType == 'with_invent_num') {
      return this.result.type.type_id == 0 || this.result.shift == 0 ||
        // Случай, когда модель выбирают из списка
        (this.result.type.type_id != 0 && this.extra.eqModels.length > 1 && this.result.model.model_id == 0) ||
        // Случай, когда модель нужно ввести вручную
        (this.result.type.type_id != 0 && this.extra.eqModels.length == 1 && !this.result.model.item_model);
    } else if (this.result.warehouseType == 'without_invent_num') {
      return this.result.type.short_descirption == '' || this.result.model.item_model == '' || this.result.shift == 0;
    } else { return true; }
  }

  EditSupplyOperationCtrl.prototype.ok = function() {
    this.$uibModalInstance.close(this.result);
  }

  /**
   * Закрыть модальное окно.
   */
  EditSupplyOperationCtrl.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };
})();
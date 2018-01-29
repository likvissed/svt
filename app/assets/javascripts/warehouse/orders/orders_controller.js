(function () {
  'use strict';

  app
    .controller('OrdersController', OrdersController)
    .controller('EditOrderController', EditOrderController)
    .controller('ExecOrderController', ExecOrderController)
    .controller('ItemsForOrderController', ItemsForOrderController);

  OrdersController.$inject = ['$uibModal', 'ActionCableChannel', 'TablePaginator', 'Order', 'Flash', 'Error', 'Server'];
  EditOrderController.$inject = ['$uibModal', '$uibModalInstance', 'Order', 'Flash', 'Error', 'Server'];
  ExecOrderController.$inject = ['$uibModal', '$uibModalInstance', 'Order', 'Flash', 'Error', 'Server'];
  ItemsForOrderController.$inject = ['$uibModalInstance', 'eqTypes', 'Order', 'Flash'];

// =====================================================================================================================

  function OrdersController($uibModal, ActionCableChannel, TablePaginator, Order, Flash, Error, Server) {
    this.$uibModal = $uibModal;
    this.ActionCableChannel = ActionCableChannel;
    this.Order = Order;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;
    this.pagination = TablePaginator.config();

    this._loadOrders();
    this._initActionCable();
  }

  /**
   * Инициировать подключение к каналу OrdersChannel
   */
  OrdersController.prototype._initActionCable = function() {
    var
      self = this,
      consumer = new this.ActionCableChannel('OrdersChannel');

    consumer.subscribe(function() {
      self._loadOrders();
    });
  };

  /**
   * Загрузить список ордеров.
   */
  OrdersController.prototype._loadOrders = function() {
    var self = this;

    this.Order.loadOrders().then(
      function() {
        self.orders = self.Order.orders;
      }
    );
  };

  /**
   * Открыть модальное окно
   */
  OrdersController.prototype._openEditModal = function() {
    this.$uibModal.open({
      templateUrl: 'bringModal.slim',
      controller: 'EditOrderController',
      controllerAs: 'edit',
      size: 'md',
      backdrop: 'static'
    });
  };

  /**
   * Открыть окно создания ордера.
   */
  OrdersController.prototype.newOrder = function(type) {
    var self = this;

    this.Order.init(type).then(function() {
      self._openEditModal();
    });
  };

  /**
   * Загрузить ордер для редактирования.
   *
   * @param order
   */
  OrdersController.prototype.editOrder = function(order) {
    var self = this;

    this.Order.loadOrder(order.warehouse_order_id).then(function() {
      self._openEditModal();
    });
  };

  /**
   * Открыть модальное окно для исполнения ордера.
   */
  OrdersController.prototype.execOrder = function(order) {
    var self = this;

    this.Order.loadOrder(order.warehouse_order_id).then(function() {
      self.$uibModal.open({
        templateUrl: 'execOrder.slim',
        controller: 'ExecOrderController',
        controllerAs: 'exec',
        size: 'md',
        backdrop: 'static'
      });
    });
  };

  /**
   * Удалить ордер.
   */
  OrdersController.prototype.destroyOrder = function(order) {
    var
      self = this,
      confirm_str = "Вы действительно хотите удалить ордер \"" + order.warehouse_order_id + "\"?";

    if (!confirm(confirm_str))
      return false;

    self.Server.Warehouse.Order.delete(
      { warehouse_order_id: order.warehouse_order_id },
      function(response) {
        self.Flash.notice(response.full_message);
      },
      function(response, status) {
        self.Error.response(response, status);
      });
  };

// =====================================================================================================================

  function EditOrderController($uibModal, $uibModalInstance, Order, Flash, Error, Server) {
    this.setFormName('order');

    this.$uibModal = $uibModal;
    this.$uibModalInstance = $uibModalInstance;
    this.Order = Order;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;

    this.order = this.Order.order;
    this.extra = this.Order.additional;

    // this.selectedConsumer = this.extra.users.find(function(el) { return el.id_tn == self.order.consumer_id_tn; }) || {};
  }

  // Унаследовать методы класса FormValidationController
  EditOrderController.prototype = Object.create(FormValidationController.prototype);
  EditOrderController.prototype.constructor = EditOrderController;

  /**
   * Открыть форму добавления техники в позицию ордера
   */
  EditOrderController.prototype._openFormToAddExistingItem = function() {
    var self = this;

    var modalInstance = this.$uibModal.open({
      templateUrl: 'existingItem.slim',
      controller: 'ItemsForOrderController',
      controllerAs: 'select',
      size: 'md',
      backdrop: 'static',
      resolve: {
        eqTypes: function() { return self.extra.eqTypes; }
      }
    });

    modalInstance.result.then(
      function(result) {
        self.Order.addPosition(result.type, result.item);
      });
  };

  /**
   * Событие выбора отдела.
   */
  // EditOrderController.prototype.changeDivision = function() {
  //   this.selectedConsumer = {};
  //   this.Order.setConsumer();
  //   this.Order.loadUsers();
  // };

  /**
   * Установить параметры пользователя, сдающего технику
   */
  EditOrderController.prototype.changeConsumer = function() {
    this.Order.setConsumer(this.selectedConsumer);
  };

  /**
   * Функция для исправления бага в компоненте typeahead ui.bootstrap. Она возвращает ФИО выбранного пользователя вместо
   * табельного номера.
   *
   * @param obj - объект выбранного ответственного.
   */
  EditOrderController.prototype.formatLabel = function(obj) {
    if (!this.extra.users) { return ''; }

    for (var i = 0; i < this.extra.users.length; i ++) {
      if (obj.id_tn === this.extra.users[i].id_tn) {
        return this.extra.users[i].fio;
      }
    }
  };

  /**
   * Добавить позицию
   */
  EditOrderController.prototype.addPosition = function() {
    this._openFormToAddExistingItem();
  };

  /**
   * Убрать позицию
   */
  EditOrderController.prototype.delPosition = function(operation) {
    this.Order.delPosition(operation);
  };

  /**
   * Создать ордер
   */
  EditOrderController.prototype.ok = function() {
    var
      self = this,
      sendData = this.Order.getObjectToSend();

    if (this.order.warehouse_order_id) {
      this.Server.Warehouse.Order.update(
        { warehouse_order_id: this.order.warehouse_order_id },
        { order: sendData },
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
      this.Server.Warehouse.Order.save(
        { order: sendData },
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
  };

  /**
   * Закрыть модальное окно.
   */
  EditOrderController.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };

// =====================================================================================================================

  function ExecOrderController($uibModal, $uibModalInstance, Order, Flash, Error, Server) {
    this.setFormName('order');

    this.$uibModal = $uibModal;
    this.$uibModalInstance = $uibModalInstance;
    this.Order = Order;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;

    this.order = this.Order.order;
    this.checkSelected();
  }

  // Унаследовать методы класса FormValidationController
  ExecOrderController.prototype = Object.create(FormValidationController.prototype);
  ExecOrderController.prototype.constructor = ExecOrderController;

  /**
   * Поставить/убрать все позиции на исполнение.
   */
  ExecOrderController.prototype.toggleAll = function() {
    var status = this.isAllOpSelected ? 'done' : 'processing';
    this.order.operations_attributes.forEach(function(op) { op.status = status; });
  };

  ExecOrderController.prototype.checkSelected = function() {
    this.isAllOpSelected = this.order.operations_attributes.every(function(op) { return op.status == 'done' });
  }

  /**
   * Исполнить выбранные поля ордера.
   */
  ExecOrderController.prototype.ok = function() {
    var
      self = this,
      sendData = this.Order.getObjectToSend();

    this.Server.Warehouse.Order.execute(
      { warehouse_order_id: this.order.warehouse_order_id },
      { order: sendData },
      function (response) {
        self.Flash.notice(response.full_message);
        self.$uibModalInstance.close();
      },
      function (response, status) {
        self.Error.response(response, status);
        self.errorResponse(response);
      }
    )
  };

  /**
   * Закрыть модальное окно.
   */
  ExecOrderController.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };

// =====================================================================================================================

  function ItemsForOrderController($uibModalInstance, eqTypes, Order, Flash) {
    this.$uibModalInstance = $uibModalInstance;
    this.eqTypes = eqTypes;
    this.Order = Order;
    this.Flash = Flash;

    this.warehouseType = '';
    // Выбранный тип техники
    this.selectedType = {
      type_id: 0,
      short_description: 'Выберите тип'
    };
    this.manuallyItem = {
      item_model: '',
      item_type: ''
    };
    // Выбранная техника (Б/У)
    this.selectedItem = {};
    // Инвентарный номер выбранного типа техники
    this.invent_num = '';
    this.items = [];

    this.eqTypes = [this.selectedType].concat(this.eqTypes);
  }

  /**
   * Из массива self.items удалить технику, которая уже присутствует в составе текущего РМ.
   */
  ItemsForOrderController.prototype._removeDuplicateItems = function() {
    var
      self = this,
      index;

    this.Order.order.operations_attributes.forEach(function(attr) {
      index = self.items.findIndex(function(el) { return el.item_id == attr.invent_item_id; });
      if (index != -1) {
        self.items.splice(index, 1);
      }
    })
  };

  /**
   * Загрузить список техники указанного типа.
   */
  ItemsForOrderController.prototype.loadItems = function() {
    var self = this;

    this.Order.loadBusyItems(this.selectedType.type_id, this.invent_num)
      .then(function(response) {
        self.items = response;
        self._removeDuplicateItems();

        if (response.length == 0) {
          self.Flash.alert('Техника не найдена. Проверьте корректность введенного инвентарного номера.');
          return false;
        }
      });
  };

  /**
   * Очистить объект selectedItem
   */
  ItemsForOrderController.prototype.clearData = function() {
    this.selectedItem = {};
    this.items = [];
  };

  ItemsForOrderController.prototype.ok = function() {
    if (this.warehouseType == 'returnable' && Object.keys(this.selectedItem).length == 0) {
      this.Flash.alert('Необходимо указать инвентарный номер и выбрать технику');
      return false;
    }

    if (this.warehouseType == 'expendable' && !this.manuallyItem.item_model && !this.manuallyItem.item_type) {
      this.Flash.alert('Необходимо указать тип и наименование техники');
      return false;
    }

    var result = {
      type: this.warehouseType,
      item: this.warehouseType == 'returnable' ? this.selectedItem : this.manuallyItem
    };

    this.$uibModalInstance.close(result);
  };

  ItemsForOrderController.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };
})();

(function () {
  'use strict';

  app
    .controller('OrdersController', OrdersController)
    .controller('EditOrderController', EditOrderController)
    .controller('ItemsForOrderController', ItemsForOrderController);

  OrdersController.$inject = ['$uibModal', 'ActionCableChannel', 'TablePaginator', 'Order', 'Flash'];
  EditOrderController.$inject = ['$uibModal', '$uibModalInstance', 'Order', 'Flash', 'Error', 'Server'];
  ItemsForOrderController.$inject = ['$uibModalInstance', 'eqTypes', 'Order', 'Operation', 'Flash'];

// =====================================================================================================================

  function OrdersController($uibModal, ActionCableChannel, TablePaginator, Order, Flash) {
    this.$uibModal = $uibModal;
    this.ActionCableChannel = ActionCableChannel;
    this.Order = Order;
    this.Flash = Flash;
    this.pagination = TablePaginator.config();

    this._loadOrders();
    this._initActionCable();
  };

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
  OrdersController.prototype._openModal = function() {
    this.$uibModal.open({
      templateUrl: 'bringModal.slim',
      controller: 'EditOrderController',
      controllerAs: 'edit',
      size: 'md',
      backdrop: 'static'
    });
  }

  /**
   * Открыть окно создания ордера.
   */
  OrdersController.prototype.newOrder = function(type) {
    var self = this;

    this.Order.init(type).then(function() {
      self._openModal();
    });
  }

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
    this.divisions = this.Order.divisions;
    console.log(this.order);

    this.selectedConsumer = {};
  }

  // Унаследовать методы класса FormValidationController
  EditOrderController.prototype = Object.create(FormValidationController.prototype);
  EditOrderController.prototype.constructor = EditOrderController;

  EditOrderController.prototype._openFormToAddExistingItem = function() {
    var self = this;

    var modalInstance = this.$uibModal.open({
      templateUrl: 'existingItem.slim',
      controller: 'ItemsForOrderController',
      controllerAs: 'select',
      size: 'md',
      backdrop: 'static',
      resolve: {
        eqTypes: function() { return self.Order.eqTypes; }
      }
    });

    modalInstance.result.then(
      function(result) {
        self.Order.addItem(result.selectedItem);
      });
  }

  /**
   * Загрузить список работников отдела.
   */
  EditOrderController.prototype.loadUsers = function() {
    var self = this;

    this.Order.loadUsers().then(function() {
      self.users = self.Order.users;
    });
  };

  /**
   * Установить параметры пользователя, сдающего технику
   */
  EditOrderController.prototype.changeConsumer = function(obj) {
    console.log('change');
    console.log(this.selectedConsumer);
    this.Order.setConsumer(this.selectedConsumer);
  };

  /**
   * Функция для исправления бага в компоненте typeahead ui.bootstrap. Она возвращает ФИО выбранного пользователя вместо
   * табельного номера.
   *
   * @param obj - объект выбранного ответственного.
   */
  EditOrderController.prototype.formatLabel = function(obj) {
    if (!this.users) { return ''; }

    for (var i = 0; i < this.users.length; i ++) {
      if (obj.id_tn === this.users[i].id_tn) {
        return this.users[i].fio;
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
  EditOrderController.prototype.delPosition = function(item) {
    this.Order.delItem(item);
  };

  /**
   * Создать ордер
   */
  EditOrderController.prototype.ok = function() {
    var self = this;

    this.Server.Warehouse.Order.save(
      { order: this.order },
      function success() {
        self.Flash.notice('Ордер создан');
        self.$uibModalInstance.close();
      },
      function error(response, status) {
        self.Error.response(response, status);
        self.errorResponse(response);
      }
    )
  };

  /**
   * Закрыть модальное окно.
   */
  EditOrderController.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };

// =====================================================================================================================

  function ItemsForOrderController($uibModalInstance, eqTypes, Order, Operation, Flash) {
    this.$uibModalInstance = $uibModalInstance;
    this.eqTypes = eqTypes;
    this.Order = Order;
    this.Operation = Operation;
    this.Flash = Flash;

    // Выбранный тип техники
    this.selectedType = {
      type_id: 0,
      short_description: 'Выберите тип'
    }
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

    this.Order.order.item_to_orders_attributes.forEach(function(attr) {
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
        console.log(response);

        self.items = response;
        self._removeDuplicateItems();
      });
  };

  ItemsForOrderController.prototype.ok = function() {
    if (Object.keys(this.selectedItem).length === 0) {
      this.Flash.alert('Необходимо выбрать технику');
    } else {
      var result = { selectedItem: this.selectedItem }

      this.$uibModalInstance.close(result);
    }
  };

  ItemsForOrderController.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };
})();

(function () {
  'use strict';

  app
    .controller('OrdersController', OrdersController)
    .controller('EditInOrderController', EditInOrderController)
    .controller('EditOutOrderController', EditOutOrderController)
    .controller('ExecOrderController', ExecOrderController)
    .controller('ItemsForOrderController', ItemsForOrderController)
    .controller('DeliveryItemsCtrl', DeliveryItemsCtrl);

  OrdersController.$inject = ['$uibModal', '$scope', 'ActionCableChannel', 'TablePaginator', 'WarehouseOrder', 'Flash', 'Error', 'Server'];
  EditInOrderController.$inject = ['$uibModal', '$uibModalInstance', 'WarehouseOrder', 'Flash', 'Error', 'Server'];
  EditOutOrderController.$inject = ['$uibModal', '$uibModalInstance', 'WarehouseOrder', 'WarehouseItems', 'Flash', 'Error', 'Server'];
  ExecOrderController.$inject = ['$uibModal', '$uibModalInstance', 'WarehouseOrder', 'Flash', 'Error', 'Server'];
  ItemsForOrderController.$inject = ['$scope', '$uibModalInstance', 'InventItem', 'WarehouseOrder', 'Flash'];
  DeliveryItemsCtrl.$inject = ['$uibModal', '$uibModalInstance', 'WarehouseOrder', 'Flash', 'Error', 'Server'];

// =====================================================================================================================

  function OrdersController($uibModal, $scope, ActionCableChannel, TablePaginator, WarehouseOrder, Flash, Error, Server) {
    var self = this;

    this.$uibModal = $uibModal;
    this.ActionCableChannel = ActionCableChannel;
    this.Order = WarehouseOrder;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;
    this.pagination = TablePaginator.config();

    $scope.initOperation = function(operation) {
      self.operation = operation;

      self._loadOrders();
      self._initActionCable();
    }
  }

  /**
   * Инициировать подключение к каналу OrdersChannel
   */
  OrdersController.prototype._initActionCable = function() {
    var
      self = this,
      channelType = this.operation.charAt(0).toUpperCase() + this.operation.slice(1),
      consumer = new this.ActionCableChannel('Warehouse::' + channelType + 'OrdersChannel');

    consumer.subscribe(function() {
      self._loadOrders();
    });
  };

  /**
   * Загрузить список ордеров.
   */
  OrdersController.prototype._loadOrders = function() {
    var self = this;

    this.Order.loadOrders(this.operation).then(
      function() {
        self.orders = self.Order.orders;
      }
    );
  };

  /**
   * Открыть модальное окно
   *
   * @param operation
   */
  OrdersController.prototype._openEditModal = function() {
    this.$uibModal.open({
      templateUrl: 'inOrderModal.slim',
      controller: 'EditInOrderController',
      controllerAs: 'edit',
      size: 'md',
      backdrop: 'static'
    });
  };

  /**
   * События изменения страницы.
   */
  OrdersController.prototype.changePage = function() {
    this._loadOrders();
  };

  /**
   * Открыть окно создания ордера.
   */
  OrdersController.prototype.newOrder = function() {
    var
      self = this,
      operation = 'in'

    this.Order.init(operation).then(function() {
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

    this.Order.loadOrder(order.id).then(function() {
      self._openEditModal();
    });
  };

  /**
   * Открыть модальное окно для исполнения ордера.
   */
  OrdersController.prototype.execOrder = function(order) {
    var
      self = this,
      checkUnreg = order.operation == 'in';

    this.Order.loadOrder(order.id, false, checkUnreg).then(function() {
      self.$uibModal.open({
        templateUrl: 'execOrder.slim',
        controller: 'ExecOrderController',
        controllerAs: 'exec',
        size: 'lg',
        backdrop: 'static'
      });
    });
  };

  /**
   * Удалить ордер.
   *
   * @param order
   */
  OrdersController.prototype.destroyOrder = function(order) {
    var
      self = this,
      confirm_str = "Вы действительно хотите удалить ордер \"" + order.id + "\"?";

    if (!confirm(confirm_str))
      return false;

    self.Server.Warehouse.Order.delete(
      { id: order.id },
      function(response) {
        self.Flash.notice(response.full_message);
      },
      function(response, status) {
        self.Error.response(response, status);
      });
  };

// =====================================================================================================================

  function EditInOrderController($uibModal, $uibModalInstance, WarehouseOrder, Flash, Error, Server) {
    this.setFormName('order');

    this.$uibModal = $uibModal;
    this.$uibModalInstance = $uibModalInstance;
    this.Order = WarehouseOrder;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;

    this.order = this.Order.order;
    this.extra = this.Order.additional;

    // this.selectedConsumer = this.extra.users.find(function(el) { return el.id_tn == self.order.consumer_id_tn; }) || {};
  }

  // Унаследовать методы класса FormValidationController
  EditInOrderController.prototype = Object.create(FormValidationController.prototype);
  EditInOrderController.prototype.constructor = EditInOrderController;

  /**
   * Обновить данные ордера
   */
  EditInOrderController.prototype.reloadOrder = function() {
    this.Order.reloadOrder();
  }

  /**
   * Открыть форму добавления техники в позицию ордера
   */
  EditInOrderController.prototype._openFormToAddExistingItem = function() {
    var self = this;

    var modalInstance = this.$uibModal.open({
      templateUrl: 'existingItem.slim',
      controller: 'ItemsForOrderController',
      controllerAs: 'select',
      size: 'md',
      backdrop: 'static',
    });

    modalInstance.result.then(function(result) {
      self.Order.addPosition(result.warehouseType, result.item);
    });
  };

  /**
   * Событие выбора отдела.
   */
  // EditInOrderController.prototype.changeDivision = function() {
  //   this.selectedConsumer = {};
  //   this.Order.setConsumer();
  //   this.Order.loadUsers();
  // };

  /**
   * Установить параметры пользователя, сдающего технику
   */
  EditInOrderController.prototype.changeConsumer = function() {
    this.Order.setConsumer(this.selectedConsumer);
  };

  /**
   * Функция для исправления бага в компоненте typeahead ui.bootstrap. Она возвращает ФИО выбранного пользователя вместо
   * табельного номера.
   *
   * @param obj - объект выбранного ответственного.
   */
  EditInOrderController.prototype.formatLabel = function(obj) {
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
  EditInOrderController.prototype.addPosition = function() {
    if (this.order.status == 'done') { return false; }
    this._openFormToAddExistingItem();
  };

  /**
   * Убрать позицию
   */
  EditInOrderController.prototype.delPosition = function(operation) {
    this.Order.delPosition(operation);
  };

  /**
   * Создать ордер
   *
   * @param done - если true, ордер будет сразу же исполнен
   */
  EditInOrderController.prototype.ok = function(done) {
    var
      self = this,
      sendData = this.Order.getObjectToSend();

    done = done || false;

    if (done && !confirm('Вы действительно хотите создать ордер и сразу же его исполнить? Удалить исполненый ордер или отменить его исполнение невозможно')) {
      return false;
    }

    if (this.order.id) {
      this.Server.Warehouse.Order.updateIn(
        { id: this.order.id },
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
      this.Server.Warehouse.Order.saveIn(
        {
          order: sendData,
          done: done
        },
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
  EditInOrderController.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };

// =====================================================================================================================

  function EditOutOrderController($uibModal, $uibModalInstance, WarehouseOrder, WarehouseItems, Flash, Error, Server) {
    var self = this;

    this.setFormName('order');

    this.$uibModal = $uibModal;
    this.$uibModalInstance = $uibModalInstance;
    this.Order = WarehouseOrder;
    this.Items = WarehouseItems;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;

    this.order = this.Order.order;
    this.extra = this.Order.additional;

    this._createShiftGetterSetter();
  }

  // Унаследовать методы класса FormValidationController
  EditOutOrderController.prototype = Object.create(FormValidationController.prototype);
  EditOutOrderController.prototype.constructor = EditInOrderController;

  EditOutOrderController.prototype._createShiftGetterSetter = function() {
    this.order.createShiftGetterSetter = function(op) {
      op.shiftGetterSetter = function(newShift) {
        if (angular.isDefined(newShift)) {
          op.shift = -newShift;
        }

        return Math.abs(op.shift);
      };

      return op.shiftGetterSetter;
    }
  };

  /**
   * Обновить данные ордера
   */
  EditOutOrderController.prototype.reloadOrder = function() {
    this.Order.reloadOrder();
    this._createShiftGetterSetter();
  }

  /**
   * Убрать позицию
   */
  EditOutOrderController.prototype.delPosition = function(operation) {
    this.Order.delPosition(operation);
    this.Items.items.find(function(item) { return item.id == operation.item_id; }).added_to_order = false
  };

  /**
   * Закрыть модальное окно.
   */
  EditOutOrderController.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };

  /**
   * Создать ордер
   */
  EditOutOrderController.prototype.ok = function() {
    var
      self = this,
      sendData = this.Order.getObjectToSend();

    if (this.order.id) {
      this.Server.Warehouse.Order.updateOut(
        { id: this.order.id },
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
      this.Server.Warehouse.Order.saveOut(
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
  }

// =====================================================================================================================

  function ExecOrderController($uibModal, $uibModalInstance, WarehouseOrder, Flash, Error, Server) {
    this.setFormName('order');

    this.$uibModal = $uibModal;
    this.$uibModalInstance = $uibModalInstance;
    this.Order = WarehouseOrder;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;

    this.order = this.Order.order;
    this.Order.prepareToExec();
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

  /**
   * Проверка, исполнена ли операция
   */
  ExecOrderController.prototype.isOperationDone = function(op) {
    return op.status == 'done' && op.date;
  }

  /**
   * Установить/снять флаг, показывающий, выбраны ли все пункты
   */
  ExecOrderController.prototype.checkSelected = function() {
    this.isAllOpSelected = this.order.operations_attributes.every(function(op) { return op.status == 'done' });
  }

  ExecOrderController.prototype.deliveryItems = function() {
    var self = this;

    if (!confirm('Вы действительно хотите исполнить выбранные позиции? Удалить исполненные позиции или отменить их исполнение невозмозно')) {
      return false;
    }

    this.Order.prepareToDeliver()
      .then(
        function(response) {
          self.clearErrors();
          var modalInstance = self.$uibModal.open({
            templateUrl: 'deliveryOfItems.slim',
            controller: 'DeliveryItemsCtrl',
            controllerAs: 'delivery',
            size: 'lg',
            backdrop: 'static'
          });

          modalInstance.result.then(function() {
            self.cancel();
          });
        },
        function(response) {
          self.errorResponse(response);
        })
  }

  /**
   * Исполнить выбранные поля ордера.
   */
  ExecOrderController.prototype.ok = function() {
    var
      self = this,
      sendData = this.Order.getObjectToSend();

    if (!confirm('Вы действительно хотите исполнить выбранные позиции? Удалить исполненные позиции или отменить их исполнение невозмозно')) {
      return false;
    }

    this.Server.Warehouse.Order.executeIn(
      { id: this.order.id },
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

  function ItemsForOrderController($scope, $uibModalInstance, InventItem, WarehouseOrder, Flash) {
    var self = this;

    this.$uibModalInstance = $uibModalInstance;
    this.Order = WarehouseOrder;
    this.InventItem = InventItem;
    this.Flash = Flash;

    this.eqTypes = WarehouseOrder.additional.eqTypes;
    this.warehouseType = '';
    this.manuallyItem = {
      item_model: '',
      item_type: ''
    };
    // Инвентарный номер выбранного типа техники
    this.invent_num = '';
    // Отдел необходим для ограничения выборки техники (в окне поиска техники)
    $scope.division = this.Order.order.consumer_dept;
    // Обязательно необходимо сбросить объект selectedItem
    this.InventItem.selectedItem = null;

    $scope.$on('removeDuplicateInvItems', function(event, data) {
      self._removeDuplicateItems(data);
    });
  }

  /**
   * Из массива self.items удалить технику, которая уже присутствует в составе текущего РМ.
   *
   * @param items
   */
  ItemsForOrderController.prototype._removeDuplicateItems = function(items) {
    var
      self = this,
      index;

    this.Order.order.operations_attributes.forEach(function(attr) {
      index = items.findIndex(function(el) { return attr.inv_item_ids.includes(el.item_id); });
      if (index != -1) {
        items.splice(index, 1);
      }
    })
  };

  ItemsForOrderController.prototype.ok = function() {
    if (this.warehouseType == 'with_invent_num' && !this.InventItem.selectedItem) {
      this.Flash.alert('Необходимо указать инвентарный номер и выбрать технику');
      return false;
    }

    if (this.warehouseType == 'without_invent_num' && !this.manuallyItem.item_model && !this.manuallyItem.item_type) {
      this.Flash.alert('Необходимо указать тип и наименование техники');
      return false;
    }

    var result = {
      warehouseType: this.warehouseType,
      item: this.warehouseType == 'with_invent_num' ? this.InventItem.selectedItem : this.manuallyItem
    };

    this.$uibModalInstance.close(result);
  };

  ItemsForOrderController.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };

  // =====================================================================================================================

  function DeliveryItemsCtrl($uibModal, $uibModalInstance, WarehouseOrder, Flash, Error, Server) {
    this.setFormName('order');

    this.$uibModal = $uibModal;
    this.$uibModalInstance = $uibModalInstance;
    this.Order = WarehouseOrder;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;

    this.order = this.Order.order;
  }

  // Унаследовать методы класса FormValidationController
  DeliveryItemsCtrl.prototype = Object.create(FormValidationController.prototype);
  DeliveryItemsCtrl.prototype.constructor = ExecOrderController;

  /**
   * Обновить данные техники указанной оперции
   *
   * @param inv_item
   */
  DeliveryItemsCtrl.prototype.refreshInvItemData = function(inv_item) {
    if (!inv_item.id) { return false; }

    var self = this;

    this.Server.Invent.Item.get(
      { item_id: inv_item.id },
      function(response) {
        angular.extend(inv_item, response);
      },
      function(response, status) {
        self.Error.response(response, status);
      }
    )
  };

  /**
   * Выдать технику
   */
  DeliveryItemsCtrl.prototype.ok = function() {
    var
      self = this,
      sendData = this.Order.getObjectToSend();

    this.Server.Warehouse.Order.executeOut(
      { id: this.order.id },
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
   * Закрыть окно
   */
  DeliveryItemsCtrl.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };

  /**
   * Фильтр, определяющий, какие операции только что были выбраны пользователем для исполнения
   */
  DeliveryItemsCtrl.prototype.selectedOpFilter = function(selectedOp) {
    return function(op) {
      return selectedOp.find(function(el) { return el.id == op.id });
    }
  }
})();

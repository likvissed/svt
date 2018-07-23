import { app } from '../../app/app';
import { FormValidationController } from '../../app/app_controller';

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
    this.$uibModal = $uibModal;
    this.ActionCableChannel = ActionCableChannel;
    this.Order = WarehouseOrder;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;
    this.pagination = TablePaginator.config();

    $scope.initOperation = (operation) => {
      this.operation = operation;

      this._loadOrders();
      this._initActionCable();
    };
  }

  /**
   * Инициировать подключение к каналу OrdersChannel
   */
  OrdersController.prototype._initActionCable = function() {
    let
      channelType = this.operation.charAt(0).toUpperCase() + this.operation.slice(1),
      consumer = new this.ActionCableChannel('Warehouse::' + channelType + 'OrdersChannel');

    consumer.subscribe(() => this._loadOrders());
  };

  /**
   * Загрузить список ордеров.
   */
  OrdersController.prototype._loadOrders = function() {
    this.Order.loadOrders(this.operation).then(() => this.orders = this.Order.orders);
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
    this.Order.init('in').then(() => this._openEditModal());
  };

  /**
   * Загрузить ордер для редактирования.
   *
   * @param order
   */
  OrdersController.prototype.editOrder = function(order) {
    this.Order.loadOrder(order.id).then(() => this._openEditModal());
  };

  /**
   * Открыть модальное окно для исполнения ордера.
   */
  OrdersController.prototype.execOrder = function(order) {
    let checkUnreg = order.operation == 'in';

    this.Order.loadOrder(order.id, false, checkUnreg).then(() => {
      this.$uibModal.open({
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
    let confirm_str = "Вы действительно хотите удалить ордер \"" + order.id + "\"?";

    if (!confirm(confirm_str)) { return false; }

    this.Server.Warehouse.Order.delete(
      { id: order.id },
      (response) => this.Flash.notice(response.full_message),
      (response, status) => this.Error.response(response, status)
    );
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
  };

  /**
   * Открыть форму добавления техники в позицию ордера
   */
  EditInOrderController.prototype._openFormToAddExistingItem = function() {
    let modalInstance = this.$uibModal.open({
      templateUrl: 'existingItem.slim',
      controller: 'ItemsForOrderController',
      controllerAs: 'select',
      size: 'md',
      backdrop: 'static',
    });

    modalInstance.result.then((result) => {
      this.Order.addPosition(result.warehouseType, result.item);
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
  // EditInOrderController.prototype.changeConsumer = function() {
  //   this.Order.setConsumer(this.selectedConsumer);
  // };

  /**
   * Функция для исправления бага в компоненте typeahead ui.bootstrap. Она возвращает ФИО выбранного пользователя вместо
   * табельного номера.
   *
   * @param obj - объект выбранного ответственного.
   */
  EditInOrderController.prototype.formatLabel = function(obj) {
    if (!this.extra.users) { return ''; }

    for (let i = 0; i < this.extra.users.length; i ++) {
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
  EditInOrderController.prototype.ok = function(done = false) {
    let sendData = this.Order.getObjectToSend();

    if (done && !confirm('Вы действительно хотите создать ордер и сразу же его исполнить? Удалить исполненый ордер или отменить его исполнение невозможно')) {
      return false;
    }

    if (this.order.id) {
      this.Server.Warehouse.Order.updateIn(
        { id: this.order.id },
        { order: sendData },
        (response) => {
          this.Flash.notice(response.full_message);
          this.$uibModalInstance.close();
        },
        (response, status) => {
          this.Error.response(response, status);
          this.errorResponse(response);
        }
      );
    } else {
      this.Server.Warehouse.Order.saveIn(
        {
          order: sendData,
          done: done
        },
        (response) => {
          this.Flash.notice(response.full_message);
          this.$uibModalInstance.close();
        },
        (response, status) => {
          this.Error.response(response, status);
          this.errorResponse(response);
        }
      );
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
  };

  /**
   * Убрать позицию
   */
  EditOutOrderController.prototype.delPosition = function(operation) {
    this.Order.delPosition(operation);
    this.Items.items.find((item) => item.id == operation.item_id).added_to_order = false
  };

  /**
   * Закрыть модальное окно.
   */
  EditOutOrderController.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };

  /**
   * Создать ордер.
   */
  EditOutOrderController.prototype.ok = function() {
    let sendData = this.Order.getObjectToSend();

    if (this.order.id) {
      this.Server.Warehouse.Order.updateOut(
        { id: this.order.id },
        { order: sendData },
        (response) => {
          this.Flash.notice(response.full_message);
          this.$uibModalInstance.close();
        },
        (response, status) => {
          this.Error.response(response, status);
          this.errorResponse(response);
        }
      )
    } else {
      this.Server.Warehouse.Order.saveOut(
        { order: sendData },
        (response) => {
          this.Flash.notice(response.full_message);
          this.$uibModalInstance.close();
        },
        (response, status) => {
          this.Error.response(response, status);
          this.errorResponse(response);
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
    let status = this.isAllOpSelected ? 'done' : 'processing';
    this.order.operations_attributes.forEach((op) => op.status = status);
  };

  // /**
  //  * Обновить данные ордера.
  //  */
  // ExecOrderController.prototype.reloadOrder = function() {
  //   this.Order.reloadOrder();
  //   this.Order.prepareToExec();
  // };

  /**
   * Проверка, исполнена ли операция.
   */
  ExecOrderController.prototype.isOperationDone = function(op) {
    return op.status == 'done' && op.date;
  };

  /**
   * Установить/снять флаг, показывающий, выбраны ли все пункты.
   */
  ExecOrderController.prototype.checkSelected = function() {
    this.isAllOpSelected = this.order.operations_attributes.every((op) => op.status == 'done');
  };

  ExecOrderController.prototype.deliveryItems = function() {
    this.Order.prepareToDeliver()
      .then(
        (response) => {
          this.clearErrors();
          let modalInstance = this.$uibModal.open({
            templateUrl: 'deliveryOfItems.slim',
            controller: 'DeliveryItemsCtrl',
            controllerAs: 'delivery',
            size: 'lg',
            backdrop: 'static'
          });

          modalInstance.result.then(() => this.cancel());
        },
        (response) => this.errorResponse(response)
      );
  };

  /**
   * Утвердить/отклонить ордер.
   */
  ExecOrderController.prototype.confirmOrder = function() {
    if (this.order.operation != 'out') { return false; }

    this.Server.Warehouse.Order.confirmOut(
      { id: this.order.id },
      {},
      (response) => {
        this.Flash.notice(response.full_message);
        this.$uibModalInstance.close();
      },
      (response, status) => {
        this.Error.response(response, status);
        this.errorResponse(response);
      }
    );
  };

  /**
   * Исполнить выбранные поля ордера.
   */
  ExecOrderController.prototype.ok = function() {
    let sendData = this.Order.getObjectToSend();

    if (!confirm('Вы действительно хотите исполнить выбранные позиции? Удалить исполненные позиции или отменить их исполнение невозмозно')) {
      return false;
    }

    this.Server.Warehouse.Order.executeIn(
      { id: this.order.id },
      { order: sendData },
      (response) => {
        this.Flash.notice(response.full_message);
        this.$uibModalInstance.close();
      },
      (response, status) => {
        this.Error.response(response, status);
        this.errorResponse(response);
      }
    )
  };

  /**
   * Распечатать ордер.
   */
  ExecOrderController.prototype.printOrder = function() {
    let sendData = this.Order.getObjectToSend();

    window.open('/warehouse/orders/' + this.order.id + '/print?order=' + JSON.stringify(sendData), '_blank');
  };

  /**
   * Закрыть модальное окно.
   */
  ExecOrderController.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };

// =====================================================================================================================

  function ItemsForOrderController($scope, $uibModalInstance, InventItem, WarehouseOrder, Flash) {
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

    $scope.$on('removeDuplicateInvItems', (event, data) => this._removeDuplicateItems(data));
  }

  /**
   * Из массива this.items удалить технику, которая уже присутствует в составе текущего РМ.
   *
   * @param items
   */
  ItemsForOrderController.prototype._removeDuplicateItems = function(items) {
    let index;

    this.Order.order.operations_attributes.forEach(function(attr) {
      index = items.findIndex((el) => attr.inv_item_ids.includes(el.item_id));
      if (index != -1) {
        items.splice(index, 1);
      }
    });
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

    let result = {
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
   * Обновить данные техники указанной оперции.
   *
   * @param inv_item
   */
  DeliveryItemsCtrl.prototype.refreshInvItemData = function(inv_item) {
    if (!inv_item.id) { return false; }

    this.Server.Invent.Item.get(
      { item_id: inv_item.id },
      (response) => angular.extend(inv_item, response),
      (response, status) => this.Error.response(response, status)
    )
  };

  /**
   * Распечатать ордер.
   */
  DeliveryItemsCtrl.prototype.printOrder = function() {
    let sendData = this.Order.getObjectToSend();

    window.open('/warehouse/orders/' + this.order.id + '/print?order=' + JSON.stringify(sendData), '_blank');
  };

  /**
   * Выдать технику.
   */
  DeliveryItemsCtrl.prototype.ok = function() {
    let sendData = this.Order.getObjectToSend();

    this.Server.Warehouse.Order.executeOut(
      { id: this.order.id },
      { order: sendData },
      (response) => {
        this.Flash.notice(response.full_message);
        this.$uibModalInstance.close();
      },
      (response, status) => {
        this.Error.response(response, status);
        this.errorResponse(response);
      }
    );
  };

  /**
   * Закрыть окно.
   */
  DeliveryItemsCtrl.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };

  /**
   * Фильтр, определяющий, какие операции только что были выбраны пользователем для исполнения.
   */
  DeliveryItemsCtrl.prototype.selectedOpFilter = function(selectedOp) {
    return function(op) {
      return selectedOp.find((el) => el.id == op.id);
    }
  }
})();


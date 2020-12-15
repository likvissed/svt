import { app } from '../../app/app';

(function () {
  'use strict';

  app
    .service('WarehouseOrder', WarehouseOrder);

  WarehouseOrder.$inject = ['WarehouseOperation', 'OrderFilters', 'Server', 'TablePaginator', 'Config', 'Flash', 'Error'];

  function WarehouseOrder(WarehouseOperation, OrderFilters, Server, TablePaginator, Config, Flash, Error) {
    this.Operation = WarehouseOperation;
    this.Filters = OrderFilters;
    this.Server = Server;
    this.TablePaginator = TablePaginator;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;

    this.additional = {};
    this.order = {};
  }

  /**
   * Сформировать счетчик выбранных элементов в таблице техники.
   *
   * @param count
   */
  WarehouseOrder.prototype._initVisibleCount = function(count) {
    this.additional.visibleCount = count || 0;
  };

  /**
   * Обработать данные для формирования ордера.
   *
   * @param data - данные, которые будут вставлены в ордер.
   * @param onlyOrder - флаг. Если true, дополнительные параметры устанавливаться не будут, только данные ордера.
   * @param newOperations - флаг. Если true, позиции ордера будут созданы заново.
   */
  WarehouseOrder.prototype._processingData = function(data, onlyOrder = false, newOperations = false) {
    this._setOrder(data.order, newOperations);

    if (!onlyOrder) {
      // Заполнить список отделов
      this.additional.divisions = data.divisions;
      // Заполнить список типов оборудования
      this.additional.eqTypes = [{ type_id: null, short_description: 'Выберите тип' }].concat(data.eq_types);

      this.Operation.setTemplate(data.operation, this.order.operation);
    }
  };

  /**
   * Сформировать массив позиций.
   *
   * @param order - данные ордера
   * @param newOp - флаг. Если true - позиции будут пустыми.
   */
  WarehouseOrder.prototype._initOperations = function(order, newOp = false) {
    if (newOp) {
      this.order.operations_attributes = [];
    } else {
      this.order.operations_attributes = order.operations_attributes || this.order.operations_attributes || [];
    }
  };

  /**
   * Создать объект Order.
   *
   * @param order - данные ордера.
   * @param newOperations - флаг. Если true, позиции ордера будут созданы заново.
   */
  WarehouseOrder.prototype._setOrder = function(order, newOperations = false) {
    angular.extend(this.order, order);
    this._initOperations(order, newOperations);
    this.order.consumer = order.consumer;

    if (typeof this._orderTemplate === 'undefined') {
      this._orderTemplate = angular.copy(this.order);
    }
    this._initVisibleCount(this.order.operations_attributes.length);
  };

  /**
   * Получить выбранную позицию.
   *
   * @param item - техника, по которой ищется позиция
   */
  WarehouseOrder.prototype.getOperation = function(item) {
    if (!this.order || !this.order.operations_attributes) { return false; }

    return this.order.operations_attributes.find((op) => op.item_id == item.id);
  };

  /**
   * Загрузить список ордеров
   *
   * @params operation - тип ордеров
   * @params init - флаг. Если true, будут загружены фильтры.
   */
  WarehouseOrder.prototype.loadOrders = function(operation, init = false) {
    return this.Server.Warehouse.Order.query(
      {
        start       : this.TablePaginator.startNum(),
        length      : this.Config.global.uibPaginationConfig.itemsPerPage,
        operation   : operation,
        init_filters: init,
        filters     : this.Filters.getFiltersToSend()
      },
      (response) => {
        // Список всех ордеров
        this.orders = response.data;
        // Данные для составления нумерации страниц
        this.TablePaginator.setData(response);

        if (init) {
          this.Filters.set(response.filters);
        }
      },
      (response, status) => this.Error.response(response, status)
    ).$promise;
  };

  /**
   * Загрузить данные указанного ордера.
   *
   * @param order_id - id ордера
   * @param onlyOrder - флаг. Если true, дополнительные параметры устанавливаться не будут, только данные ордера.
   * @param checkUnreg - флаг. Если true, будет проверка, разрегестрирована ли техника.
   */
  WarehouseOrder.prototype.loadOrder = function(order_id, onlyOrder = false, checkUnreg = false) {
    return this.Server.Warehouse.Order.edit(
      {
        id         : order_id,
        check_unreg: checkUnreg
      },
      (data) => this._processingData(data, onlyOrder),
      (response, status) => this.Error.response(response, status)
    ).$promise;
  };

  /**
   * Загрузить данные о текущем ордере заново
   */
  WarehouseOrder.prototype.reloadOrder = function() {
    this.loadOrder(this.order.id, true);
  };

  /**
   * Загрузить данные с сервера: объект ордер, список отделов
   *
   * @param type - тип ордера (на приход или расход)
   * @param data - данные ордера.
   * @param newOperations - флаг. Если true, позиции ордера будут созданы заново.
   */
  WarehouseOrder.prototype.init = function(type, data, newOperations = false) {
    if (data) {
      this._processingData(data);

      return true;
    }

    return this.Server.Warehouse.Order.newOrder(
      { operation: type },
      (data) => this._processingData(data, false, newOperations),
      (response, status) => this.Error.response(response, status)
    ).$promise;
  };

  /**
   * Заново заполнить объект order начальными данными.
   */
  WarehouseOrder.prototype.reinit = function() {
    angular.extend(this.order, angular.copy(this._orderTemplate));
    this._initVisibleCount();
  };

  /**
   * Выбрать все позиции ордера для исполнения.
   */
  WarehouseOrder.prototype.prepareToExec = function() {
    this.order.operations_attributes.forEach((op) => op.status = 'done');
  };

  /**
   * Добавить данные по ответственному к объекту order.
   */
  WarehouseOrder.prototype._setConsumer = function() {
    this.order.consumer_id_tn = this.order.consumer ? angular.copy(this.order.consumer.id_tn) : null;
    this.order.consumer_fio = this.order.consumer ? angular.copy(this.order.consumer.fio) : null;
    this.order.consumer_tn = this.order.consumer ? angular.copy(this.order.consumer.tn) : null;
  };

  /**
   * Добавить объект operation к текущему ордеру.
   *
   * @param warehouseType
   * @param item - для приходного ордера invent_item, для расходного и на списание - warehouse_item
   */
  WarehouseOrder.prototype.addPosition = function(warehouseType, item) {
    let existingItem = this.order.operations_attributes.find((op) => op.item_id == item.id && item.id);

    if (existingItem) {
      delete(existingItem._destroy);
    } else {
      this.order.operations_attributes.push(this.Operation.generate(warehouseType, item));

      // Добавить связанную технику, являющейся свойством для inv_item
      if (item.warehouse_items) {
        item.warehouse_items.forEach((w_item) => {
          this.order.operations_attributes.push(this.Operation.generate(warehouseType, w_item));
          this.additional.visibleCount++;
        });
      }
    }

    this.additional.visibleCount++;
  };
  /**
   * Удалить объект operation из ордера.
   *
   * @param operation
   */
  WarehouseOrder.prototype.delPosition = function(operation) {
    if (operation.id) {
      operation._destroy = 1;
    } else {
      let index = this.order.operations_attributes.indexOf(operation);
      this.order.operations_attributes.splice(index, 1);
    }

    this.additional.visibleCount--;
  };

  /**
   * Подготовить данные для отправки на сервер.
   *
   * @param doneFlag
   */
  WarehouseOrder.prototype.getObjectToSend = function(doneFlag = false) {
    this._setConsumer();

    let obj = angular.copy(this.order);

    if (doneFlag) {
      obj.status = 'done';
      obj.dont_calculate_status = true;
    }

    obj.operations_attributes.forEach(function(op) {
      delete(op.item);
      delete(op.inv_items);
      delete(op.formatted_date);
      delete(op.inv_item_to_operations);

      if (op.inv_items_attributes) {
        op.inv_items_attributes.forEach(function(inv_item) {
          Object.keys(inv_item).forEach(function(key) {
            if (['id', 'invent_num', 'serial_num'].includes(key)) { return true; }

            delete(inv_item[key]);
          });
        });
      }
    });

    delete(obj.consumer);
    delete(obj.selected_op);

    return obj;
  };

  /**
   * Проверить корректность данных ордера перед выдачей оборудования.
   */
  WarehouseOrder.prototype.prepareToDeliver = function() {
    let sendData = this.getObjectToSend();

    return this.Server.Warehouse.Order.prepareToDeliver(
      { id: this.order.id },
      { order: sendData },
      (response) => {
        let newOp;

        this.order.operations_attributes.forEach((op) => {
          newOp = response.operations_attributes.find((el) => op.id == el.id)
          angular.extend(op, newOp);
        });
        this.order.selected_op = response.selected_op;
      },
      (response, status) => this.Error.response(response, status)
    ).$promise;
  };
})();

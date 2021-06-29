import { app } from '../../app/app';

(function() {
  'use strict';

  app.controller('InventItemsTableCtrl', InventItemsTableCtrl);

  InventItemsTableCtrl.$inject = ['$uibModal', 'TablePaginator', 'ActionCableChannel', 'InventItemsTable', 'InventItemsTableFiltersFactory', 'InventItem', 'PropertyValue', 'Statistics', 'Config', 'Server', 'Flash', 'Error'];

  function InventItemsTableCtrl($uibModal, TablePaginator, ActionCableChannel, InventItemsTable, InventItemsTableFiltersFactory, InventItem, PropertyValue, Statistics, Config, Server, Flash, Error) {
    this.$uibModal = $uibModal;
    this.ActionCableChannel = ActionCableChannel;
    this.Items = InventItemsTable;
    this.Filters = InventItemsTableFiltersFactory;
    this.Item = InventItem;
    this.PropertyValue = PropertyValue;
    this.Statistics = Statistics;
    this.Config = Config;
    this.Server = Server;
    this.Flash = Flash;
    this.Error = Error;

    this.pagination = TablePaginator.config();
    this.filters = this.Filters.getFilters();
    this.selected = this.Filters.getSelected();

    this._loadItems(true);
    this._initActionCable();

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
        onSelectionChanged: () => this.changeFilter()
      }
    };
  }

  /**
   * Загрузить данные с сервера.
   */
  InventItemsTableCtrl.prototype._loadItems = function(initFlag) {
    this.Items.init(initFlag).then(() => this.items = this.Items.items);
  };

  /**
   * Инициировать подключение к каналу WorkplacesChannel.
   */
  InventItemsTableCtrl.prototype._initActionCable = function() {
    let consumer = new this.ActionCableChannel('Invent::ItemsChannel');

    consumer.subscribe(() => this._loadItems());
  };

  /**
   * События изменения страницы.
   */
  InventItemsTableCtrl.prototype.changePage = function() {
    this._loadItems(false);
  };

  /**
   * Событие изменения фильтра.
   */
  InventItemsTableCtrl.prototype.changeFilter = function() {
    this._loadItems(false);
  };

  /**
   * Загрузить список комнат.
   */
  InventItemsTableCtrl.prototype.loadRooms = function() {
    this.Items.loadRooms();
  };

  /**
   * Очистить список комнат.
   */
  InventItemsTableCtrl.prototype.clearRooms = function() {
    this.Items.clearRooms();
  };

  /**
   * Добавить фильтр по составу техники.
   */
  InventItemsTableCtrl.prototype.addPropFilter = function() {
    this.Filters.addProperty();
  };

  /**
   * Удалить выбранный фильтр по составу техники.
   *
   * @param index - индекс удаляемого элемента.
   */
  InventItemsTableCtrl.prototype.delPropFilter = function(index) {
    if (this.selected.properties.length > 1) {
      this.Filters.delProperty(index);
    } else {
      this.Filters.setDefaultState(index);
    }

    this._loadItems(false);
  };

  /**
   * Удалить технику.
   *
   * @param item
   */
  InventItemsTableCtrl.prototype.destroyItem = function(item) {
    if (item.model === null) {
      item.model = '';
    }
    let confirm_str = `Вы действительно хотите удалить ${item.type.short_description} "'${item.model}" '?`;

    if (!confirm(confirm_str)) { return false; }

    this.Server.Invent.Item.delete(
      { item_id: item.item_id },
      (response) => {
        this.Flash.notice(response.full_message);
        this._loadItems(false);
      },
      (response, status) => this.Error.response(response, status)
    );
  };

  /**
   * Редактировать состав техники.
   *
   * @param item
   */
  InventItemsTableCtrl.prototype.editItem = function(item) {
    this.Item.edit(item.item_id).then(
      () => {
        this.$uibModal.open({
          animation   : this.Config.global.modalAnimation,
          templateUrl : 'editItem.slim',
          controller  : 'EditInventItemModalCtrl',
          controllerAs: 'modal',
          size        : 'md',
          backdrop    : 'static'
        });
      }
    );
  };

  /**
   * Подсветить ИБП, для которых необходимо заменить батареи.
   *
   * @param item
   */
  InventItemsTableCtrl.prototype.colorizeUps = function(item) {
    if (!item['need_battery_replacement?']) { return false; }

    if (item['need_battery_replacement?'].type == 'warning') {
      return 'warning';
    } else if (item['need_battery_replacement?'].type == 'critical') {
      return 'danger';
    }
  };

  /**
   * Изменить данные фильтра в свойстве с типом list_plus.
   *
   * @param index - индекс фильтра в массиве.
   */
  InventItemsTableCtrl.prototype.changeFilterPropertyType = function(index) {
    let filter = this.selected.properties[index];

    filter.value_manually = !filter.value_manually;

    this.Filters.clearValueForSelectedProperty(filter);
  };

  /**
   * Очистить данные фильтру, указанному по индексу.
   *
   * @param index
   */
  InventItemsTableCtrl.prototype.clearPropertyFilter = function(index) {
    let filter = this.selected.properties[index];
    this.Filters.clearValueForSelectedProperty(filter);
  };

  /**
   * Определяет, разрешить ли фильтр "Exact" для фильтра, указанного по индексу.
   */
  InventItemsTableCtrl.prototype.isAllowExactFilter = function(index) {
    const filter = this.selected.properties[index];

    if (!filter.property_to_type.property) { return false; }

    let prop_type = filter.property_to_type.property.property_type;

    return prop_type == 'string' || prop_type == 'list_plus' && filter.value_manually;
  };

  /**
   * Загрузить статистику по батареям ИБП.
   */
  InventItemsTableCtrl.prototype.getBatteryStat = function() {
    this.Statistics.get('ups_battery').then(
      () => {
        this.$uibModal.open({
          animation   : this.Config.global.modalAnimation,
          templateUrl : 'statisticsUps.slim',
          controller  : 'StatisticsCtrl',
          controllerAs: 'stat',
          size        : 'md',
          backdrop    : 'static'
        });
      }
    )
  };

  /**
   * Получить данные в JSON формате для открытия кейса.
   *
   * @param item
   */
  InventItemsTableCtrl.prototype.dataForAstraea = function(item) {
    let tn;

    if (item.workplace) {
      if (item.workplace.user_iss) {
        tn = item.workplace.user_iss.tn;
      }

      const data = {
        barcode     : item.barcode,
        item_id     : item.item_id,
        invent_num  : item.invent_num,
        id_tn       : item.workplace.id_tn,
        tn          : tn,
        workplace_id: item.workplace_id,
        type_id     : item.type_id,
        severity    : 6
      }

      return encodeURIComponent(JSON.stringify(data));
    }
  };
})();

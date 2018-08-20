import { app } from '../../app/app';

(function() {
  'use strict';

  app
    .controller('WorkplaceIndexCtrl', WorkplaceIndexCtrl)
    .controller('WorkplaceTableCtrl', WorkplaceTableCtrl)
    .controller('WorkplaceListCtrl', WorkplaceListCtrl)
    .controller('WorkplaceEditCtrl', WorkplaceEditCtrl)
    .controller('ManuallyPcDialogCtrl', ManuallyPcDialogCtrl)
    .controller('SelectItemTypeCtrl', SelectItemTypeCtrl);

  WorkplaceIndexCtrl.$inject = ['$scope', 'WorkplacesFilter', 'Cookies'];
  WorkplaceTableCtrl.$inject = ['$scope', 'Workplaces', 'ActionCableChannel', 'TablePaginator', 'Server', 'Config', 'Flash', 'Error', 'Cookies'];
  WorkplaceListCtrl.$inject = ['$scope', 'Workplaces', 'ActionCableChannel', 'TablePaginator', 'Server', 'Config', 'Flash', 'Error'];
  WorkplaceEditCtrl.$inject = ['$timeout', '$uibModal', 'Flash', 'Config', 'Workplace', 'WorkplaceItem'];
  ManuallyPcDialogCtrl.$inject = ['$uibModalInstance', 'Flash', 'Workplace', 'WorkplaceItem', 'item'];
  SelectItemTypeCtrl.$inject = ['$scope', '$uibModalInstance', 'data', 'Workplace', 'InventItem', 'Flash'];

  /**
   * Управление страницей РМ.
   */
  function WorkplaceIndexCtrl($scope, Filter, Cookies) {
    this.$scope = $scope;
    this.Cookies = Cookies;
    this.Filter = Filter;

    Cookies.Workplace.init();

    this.filters = Filter.filters;
    this.selectedFilters = Filter.selectedTableFilters;
    this.listType = Cookies.Workplace.get('tableListTypeFilter') || false;
  }

  WorkplaceIndexCtrl.prototype.reloadWorkplaces = function() {
    let broadcast = this.listType ? 'WorkplaceTableCtrl::reloadWorkplacesList' : 'WorkplaceTableCtrl::reloadWorkplacesTable';
    this.$scope.$broadcast(broadcast, null);
  };

  WorkplaceIndexCtrl.prototype.setFilters = function() {
    this.Cookies.Workplace.set('tableListTypeFilter', this.listType);
  };

  WorkplaceIndexCtrl.prototype.loadRooms = function() {
    this.Filter.loadRooms();
  };

  WorkplaceIndexCtrl.prototype.clearRooms = function() {
    this.Filter.clearRooms();
  };

// =====================================================================================================================

  /**
   * Управление таблицей рабочих мест.
   */
  function WorkplaceTableCtrl($scope, Workplaces, ActionCableChannel, TablePaginator, Server, Config, Flash, Error) {
    this.Workplaces = Workplaces;
    this.ActionCableChannel = ActionCableChannel;
    this.TablePaginator = TablePaginator;
    this.Server = Server;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;
    this.pagination = TablePaginator.config();

    this._loadWorkplaces(true);
    this._initActionCable();

    $scope.$on('WorkplaceTableCtrl::reloadWorkplacesTable', () => this.reloadWorkplaces());

  // /**
  //  * Заполнить данные фильтров.
  //  *
  //  * @param data - данные фильтров, полученные с сервера
  //  */
  // WorkplaceTableCtrl.prototype._setFilters = function(data) {
  //   var cookieVal;

  //   this.divisionFilters = this.divisionFilters.concat(data.divisions);
  //   Object.assign(this.statusFilters, data.statuses);
  //   this.typeFilters = this.typeFilters.concat(data.types);

  //   // Установить выбранный фильтр по инвентарному номеру
  //   cookieVal = this.Cookies.Workplace.get('tableInventNumFilter');
  //   if (angular.isUndefined(cookieVal)) {
  //     this.selectedInventNumFilter = '';
  //   } else {
  //     this.selectedInventNumFilter = cookieVal;
  //   }

  //   // Установить выбранный фильтр по ID рабочего места
  //   cookieVal = this.Cookies.Workplace.get('tableIdFilter');
  //   if (angular.isUndefined(cookieVal)) {
  //     this.selectedIdFilter = '';
  //   } else {
  //     this.selectedIdFilter = cookieVal;
  //   }

  //   // Установить выбранный фильтр по отделам
  //   cookieVal = this.Cookies.Workplace.get('tableDivisionFilter');
  //   if (angular.isUndefined(cookieVal)) {
  //     this.selectedDivisionFilter = this.divisionFilters[0];
  //   } else {
  //     this.selectedDivisionFilter = this.divisionFilters.find(function(el) { return el.workplace_count_id == cookieVal })
  //   }

  //   // Установить выбранный фильтр по статусам РМ
  //   cookieVal = this.Cookies.Workplace.get('tableStatusFilter');
  //   if (angular.isUndefined(cookieVal)) {
  //     this.selectedStatusFilter = Object.keys(this.statusFilters)[0];
  //   } else {
  //     this.selectedStatusFilter = cookieVal;
  //   }

  //   // Установить выбранный фильтр по типам РМ
  //   cookieVal = this.Cookies.Workplace.get('tableTypeFilter');
  //   if (angular.isUndefined(cookieVal)) {
  //     this.selectedTypeFilter = this.typeFilters[0];
  //   } else {
  //     this.selectedTypeFilter = this.typeFilters.find(function(el) { return el.workplace_type_id == cookieVal })
  //   }
  // };
  };

  /**
   * Загрузить данные о РМ.
   *
   * @param init
   */
  WorkplaceTableCtrl.prototype._loadWorkplaces = function(init) {
    this.Workplaces.loadWorkplaces(init).then(
      (response) => this.workplaces = this.Workplaces.workplaces
    );
  };

  /**
   * Инициировать подключение к каналу WorkplacesChannel.
   */
  WorkplaceTableCtrl.prototype._initActionCable = function() {
    let consumer = new this.ActionCableChannel('Invent::WorkplacesChannel');

    consumer.subscribe(() => this._loadWorkplaces());
  };

  /**
   * Загрузить список РМ.
   */
  WorkplaceTableCtrl.prototype.reloadWorkplaces = function() {
    this._loadWorkplaces();
  };

  /**
   * Удалить РМ.
   *
   * @param id
   */
  WorkplaceTableCtrl.prototype.destroyWp = function(id) {
    let confirm_str = "Вы действительно хотите удалить рабочее место \"" + id + "\"?";

    if (!confirm(confirm_str)) { return false; }

    this.Server.Invent.Workplace.delete(
      { workplace_id: id },
      (response) => this.Flash.notice(response.full_message),
      (response, status) => this.Error.response(response, status)
    );
  };

// =====================================================================================================================

  /**
   * Управление общей таблицей рабочих мест.
   *
   * @class SVT.WorkplaceListCtrl
   */
  function WorkplaceListCtrl($scope, Workplaces, ActionCableChannel, TablePaginator, Server, Config, Flash, Error) {
    this.Workplaces = Workplaces;
    this.ActionCableChannel = ActionCableChannel;
    this.Server = Server;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;
    this.pagination = TablePaginator.config();

    this._loadWorkplaces();
    this._initActionCable();

    $scope.$on('WorkplaceTableCtrl::reloadWorkplacesList', () => this.reloadWorkplaces());

    // var checkboxCell = '<input ng-model="wpList.flags.all" ng-click="wpList.toggleAll()" ng-disabled="wpList.isEmptyWorkplace()" type="checkbox">';

    // // Объект, содержащий данные отделов по инвентаризации (workplace_id => data)
    // self.workplaces = {};
    // // Фильтр по отделам
    // self.divisionFilters = [
    //   {
    //     workplace_count_id: 0,
    //     division: 'Все отделы'
    //   }
    // ];
    // // Флаги
    // self.flags = {
    //   // выбрано хотя бы одно поле
    //   single: false,
    //   // выбраны все поля
    //   all: false
    // };
    // // self.selectAll = false;

    //   if (json.filters) {
    //     self._setFilters(json.filters);
    //   }
    // }

    // function checkboxCellFunc(data, type, full, meta) {
    //   return '<input ng-model="wpList.workplaces[' + data.workplace_id + '].selected" ng-click="wpList.toggleOne()" type="checkbox">';
    // }
  }

  /**
   * Загрузить данные о РМ.
   *
   * @param init
   */
  WorkplaceListCtrl.prototype._loadWorkplaces = function(init) {
    this.Workplaces.loadListWorkplaces().then(
      (response) => this.workplaces = this.Workplaces.workplaces
    );
  };

  /**
   * Инициировать подключение к каналу WorkplacesListChannel.
   */
  WorkplaceListCtrl.prototype._initActionCable = function() {
    let consumer = new this.ActionCableChannel('Invent::WorkplacesListChannel');

    consumer.subscribe(() => this._loadWorkplaces());
  };

  /**
   * Загрузить список РМ.
   */
  WorkplaceListCtrl.prototype.reloadWorkplaces = function() {
    this._loadWorkplaces();
  };

  /**
   * Удалить РМ.
   *
   * @param id
   */
  WorkplaceListCtrl.prototype.destroyWp = function(id) {
    let confirm_str = "Вы действительно хотите удалить рабочее место \"" + id + "\"?";

    if (!confirm(confirm_str)) { return false; }

    this.Server.Invent.Workplace.delete(
      { workplace_id: id },
      (response) => this.Flash.notice(response.full_message),
      (response, status) => this.Error.response(response, status)
    );
  };

  // /**
  //  * Заполнить данные фильтров.
  //  *
  //  * @param data - данные фильтров, полученные с сервера
  //  */
  // WorkplaceListCtrl.prototype._setFilters = function(data) {
  //   var cookieVal;

  //   this.divisionFilters = this.divisionFilters.concat(data.divisions);

  //   // Установить выбранный фильтр по отделам
  //   cookieVal = this.Cookies.Workplace.get('tableListDivisionFilter');
  //   if (angular.isUndefined(cookieVal)) {
  //     this.selectedDivisionFilter = this.divisionFilters[0];
  //   } else {
  //     this.selectedDivisionFilter = this.divisionFilters.find(function(el) { return el.workplace_count_id == cookieVal; });
  //   }
  // };

  // /**
  //  * Записать выбранные фильтры в cookies.
  //  */
  // WorkplaceListCtrl.prototype._setFilterCookies = function() {
  //   this.Cookies.Workplace.set('tableListDivisionFilter', this.selectedDivisionFilter.workplace_count_id);
  // };

  // /**
  //  * Установить служебные переменные в дефолтные состояния.
  //  */
  // WorkplaceListCtrl.prototype._setDefaultTableMetadata = function() {
  //   this.workplaces = {};
  //   this.flags.all = false;
  //   this.flags.single = false;
  // };

  // /**
  //  * Удалить элементы из объекта workplaces.
  //  *
  //  * @param keys - массив ключей, которые необходимо удалить.
  //  */
  // WorkplaceListCtrl.prototype._removeRow = function(keys) {
  //   keys.forEach(function(id) { delete this[id]; }, this.workplaces);
  //   this.dtInstance.reloadData(null, this.Config.global.reloadPaging);
  //   this._setDefaultTableMetadata();
  // };

  // /**
  //  * Возвращает true, если объект workplaces пустой.
  //  */
  // WorkplaceListCtrl.prototype.isEmptyWorkplace = function() {
  //   return Object.keys(this.workplaces).length == 0;
  // };

  // /**
  //  * Выделить или снять всё.
  //  */
  // WorkplaceListCtrl.prototype.toggleAll = function() {
  //   angular.forEach(this.workplaces, function(value) { value.selected = this.flags.all; }, this);
  // };

  // /**
  //  * Проверить, сколько checkbox выделено.
  //  */
  // WorkplaceListCtrl.prototype.toggleOne = function() {
  //   var
  //     // Счетчик выделенных полей checkbox
  //     count = 0,
  //     // Флаг, который будет присвоен переменной flags.all
  //     flag = true;

  //   angular.forEach(this.workplaces, function(wp) { wp.selected ? count ++ : flag = false; });

  //   this.flags.all = flag;
  //   this.flags.single = count != 0;
  // };

  // /**
  //  * Сохранить фильтры и обновить данные таблицы с учетом фильтров.
  //  */
  // WorkplaceListCtrl.prototype.changeFilter = function() {
  //   this._setFilterCookies();
  //   this._setDefaultTableMetadata();

  //   this.dtInstance.changeData({
  //     data: {
  //       filters: {
  //         workplace_count_id: this.selectedDivisionFilter.workplace_count_id
  //       }
  //     }
  //   });
  // };

  // /**
  //  * Обновить данные о РМ.
  //  */
  // WorkplaceListCtrl.prototype.updateWp = function(type) {
  //   var
  //     self = this,
  //     // Список id, которые будут отправлены на сервер
  //     wpIds = Object.keys(this.workplaces).filter(function(el) { return this.workplaces[el].selected }, this);

  //   if (wpIds.length == 0) {
  //     self.Flash.alert('Необходимо выбрать хотя бы одно рабочее место');
  //     return false;
  //   }

  //   this.Server.Invent.Workplace.confirm(
  //     {
  //       type: type,
  //       ids: wpIds
  //     },
  //     function success(response) {
  //       self._removeRow(wpIds);
  //       self.Flash.notice(response.full_message);
  //     },
  //     function error(response) {
  //       self.Error.response(response);
  //     })
  // };

// =====================================================================================================================

  /**
   * Редактирование данных о РМ. Подтверждение/отклонение введенных данных.
   *
   * @class SVT.WorkplaceEditCtrl
   */
  function WorkplaceEditCtrl($timeout, $uibModal, Flash, Config, Workplace, WorkplaceItem) {
    this.$timeout = $timeout;
    this.$uibModal = $uibModal;
    this.Flash = Flash;
    this.Config = Config;
    this.Workplace = Workplace;
    this.Item = WorkplaceItem;
  }

  WorkplaceEditCtrl.prototype.init = function(id) {
    this.additional = this.Item.getAdditional();

    this.Workplace.init(id).then(() => {
      // Список типов РМ
      this.wp_types = this.Workplace.wp_types;
      // Типы оборудования на РМ с необходимыми для заполнения свойствами
      this.eq_types = this.Item.getTypes();
      // Направления деятельности
      this.specs = this.Workplace.specs;
      // Список отделов, прикрепленных к пользователю
      this.divisions = this.Workplace.divisions;
      // Список площадок и корпусов
      this.iss_locations = this.Workplace.iss_locations;
      // Список пользователей отдела
      this.users = this.Workplace.users;
      // Список возможных статусов РМ
      this.statuses = this.Workplace.statuses;

      // Данные о рабочем месте
      this.workplace = this.Workplace.workplace;

      if (!id) { this.loadUsers(); }
    });
  };

  /**
   * Загрузить список работников отдела.
   */
  WorkplaceEditCtrl.prototype.loadUsers = function() {
    this.workplace.id_tn = null;
    this.Workplace.loadUsers().then(() => this.users = this.Workplace.users);
  };

  /**
   * Функция для исправления бага в компоненте typeahead ui.bootstrap. Она возвращает ФИО выбранного пользователя вместо
   * табельного номера.
   *
   * @param id_tn - id_tn выбранного ответственного.
   */
  WorkplaceEditCtrl.prototype.formatLabel = function(id_tn) {
    if (!this.users) { return ''; }

    for (let i = 0; i < this.users.length; i ++) {
      if (id_tn === this.users[i].id_tn) {
        return this.users[i].fio;
      }
    }
  };

  /**
   * Установить workplace_type_id рабочего места.
   */
  WorkplaceEditCtrl.prototype.setWorkplaceType = function() {
    this.workplace.workplace_type_id = angular.copy(this.workplace.workplace_type.workplace_type_id);
  };

  /**
   * Установить location_site_id рабочего места.
   */
  WorkplaceEditCtrl.prototype.setLocationSite = function() {
    this.workplace.location_site_id = angular.copy(this.workplace.location_site.site_id);
  };

  /**
   * Установить начальное значение для корпуса при изменении площадки.
   */
  WorkplaceEditCtrl.prototype.setDefaultLocation = function(type) {
    this.Workplace.setDefaultLocation(type);
  };

  /**
   * Отправить запрос в Аудит для получения конфигурации оборудования.
   *
   * @param item
   */
  WorkplaceEditCtrl.prototype.getAuditData = function(item) {
    if (item.invent_num) {
      this.additional.invent_num = angular.copy(item.invent_num);
      this.Workplace.getAuditData(item);
    } else {
      this.Flash.alert('Сначала необходимо ввести инвентарный номер');
    }
  };

  /**
   * Запустить диалоговое окно "Ввод данных вручную".
   */
  WorkplaceEditCtrl.prototype.runManuallyPcDialog = function(item) {
    this.$uibModal.open({
      animation: this.Config.global.modalAnimation,
      templateUrl: 'manuallyPcDialog.slim',
      controller: 'ManuallyPcDialogCtrl',
      controllerAs: 'manually',
      size: 'md',
      backdrop: 'static',
      resolve: {
        item: function() { return item; }
      }
    });
  };

  /**
   * Записать в модель workplace.items данные о выбранной модели выбранного типа оборудования.
   *
   * @param item - экземпляр техники, у которого изменили модель
   */
  WorkplaceEditCtrl.prototype.changeItemModel = function(item) {
    this.Item.changeModel(item);
  };

  /**
   * Отправить данные на сервер для сохранения и закрыть Wizzard.
   */
  WorkplaceEditCtrl.prototype.saveWorkplace = function() {
    this.Workplace.saveWorkplace()
  };

  /**
   * Запустить диалоговое окно "Выбор типа устройства".
   */
  WorkplaceEditCtrl.prototype.showSelectItemType = function() {
    let modalInstance = this.$uibModal.open({
      animation: this.Config.global.modalAnimation,
      templateUrl: 'newItem.slim',
      controller: 'SelectItemTypeCtrl',
      controllerAs: 'select',
      size: 'md',
      backdrop: 'static',
      resolve: {
        data: () => {
          return { eq_types: this.eq_types };
        }
      }
    });

    modalInstance.result.then(
      (result) => {
        if (result.item_id) {
          // Для б/у оборудования с другого РМ
          this.Workplace.addExistingItem(result);
        } else {
          // Для нового оборудования
          this.Workplace.createItem(result);
        }
      },
      () => this.Workplace.setFirstActiveTab()
    );
  };

  /**
   * Удалить выбранное оборудование из состава РМ.
   *
   * @param item - удаляемый элемент.
   * @param $event - объект события.
   */
  WorkplaceEditCtrl.prototype.delItem = function(item, $event) {
    $event.stopPropagation();
    $event.preventDefault();

    this.Workplace.delItem(item);
  };

  /**
   * Удалить технику из БД.
   *
   * @param id
   */
  WorkplaceEditCtrl.prototype.destroyItem = function(item) {
    let confirm_str = "ВНИМАНИЕ! Техника будет удалена без возможности восстановления! Вы действительно хотите удалить " + item.type.short_description + "?";

    if (!confirm(confirm_str)) { return false; }

    // this.Workplace.destroyWorkplace();
    this.Item.destroyItem(item).then(() => this.Workplace.delItem(item));
  };

  /**
   * Удалить РМ.
   *
   * @param id
   */
  WorkplaceEditCtrl.prototype.destroyWp = function() {
    let confirm_str = "ВНИМАНИЕ! Вместе с рабочим местом будет удалена вся входящая в него техника! Вы действительно хотите удалить рабочее место?";

    if (!confirm(confirm_str)) { return false; }

    this.Workplace.destroyWorkplace();
  };

// =====================================================================================================================

  /**
   * Ввод данных о составе СБ, Моноблока, Ноутбука вручную.
   *
   * @class SVT.WorkplaceEditCtrl
   */
  function ManuallyPcDialogCtrl($uibModalInstance, Flash, Workplace, WorkplaceItem, item) {
    this.$uibModalInstance = $uibModalInstance;
    this.Flash = Flash;
    this.Workplace = Workplace;
    this.Item = WorkplaceItem;
    this.item = item;
  }

  /**
   * Скачать скрипт.
   */
  ManuallyPcDialogCtrl.prototype.downloadPcScript = function() {
    this.Workplace.downloadPcScript();
  };

  /**
   * Закрыть модальное окно.
   */
  ManuallyPcDialogCtrl.prototype.close = function() {
    this.$uibModalInstance.close();
  };

  /**
   * Загрузить файл для декодирования.
   *
   * @param file
   */
  ManuallyPcDialogCtrl.prototype.setPcFile = function(file) {
    if (!this.Item.isValidFile(file)) {
      this.Flash.alert('Необходимо загрузить текстовый файл, полученный в результате работы скачанной вами программы');

      return false;
    }

    this.Workplace.matchUploadFile(file).then(
      (response) => {
        if (!this.Item.matchDataFromUploadedFile(this.item, response.data)) {
          this.Flash.alert('Не удалось обработать данные. Убедитесь в том, что вы загружаете файл, созданный скачанной программой. Если ошибка не исчезает, обратитесь к администратору (т.***REMOVED***)');

          return false;
        }

        this.Flash.notice(response.full_message);
        this.$uibModalInstance.close();
      }
    );
  };

// =====================================================================================================================

  function SelectItemTypeCtrl($scope, $uibModalInstance, data, Workplace, Item, Flash) {
    this.$uibModalInstance = $uibModalInstance;
    this.Flash = Flash;
    // Типы оборудования
    this.eqTypes = data.eq_types;
    // Выбранный тип устройства
    this.selectedType = angular.copy(this.eqTypes[0]);
    this.Item = Item;
    this.Workplace = Workplace;
    // Тип техники: новая или б/у
    this.itemType = '';
    // Отдел необходим для ограничения выборки техники (в окне поиска техники)
    // $scope.division = this.Workplace.workplace.division.division;

    this.Item.selectedItem = null;
    $scope.$on('removeDuplicateInvItems', (event, data) => {
      this._removeDuplicateItems(data);
    });
  }

  /**
   * Из массива this.items удалить технику, которая уже присутствует в составе текущего РМ.
   *
   * @param items
   */
  SelectItemTypeCtrl.prototype._removeDuplicateItems = function(items) {
    let index;

    this.Workplace.workplace.items_attributes.forEach((item) => {
      index = items.findIndex((el) => el.item_id == item.id);
      if (index != -1) {
        items.splice(index, 1);
      }
    })
  };

  SelectItemTypeCtrl.prototype.ok = function() {
    if (this.itemType == 'new') {
      if (this.Workplace.validateType(this.selectedType)) {
        this.$uibModalInstance.close(this.selectedType);
      }
    } else {
      if (this.Item.selectedItem) {
        this.$uibModalInstance.close(this.Item.selectedItem);
      } else {
        this.Flash.alert('Необходимо выбрать технику.');
      }
    }
  };

  SelectItemTypeCtrl.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };
})();

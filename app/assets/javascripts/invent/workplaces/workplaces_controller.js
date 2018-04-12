(function() {
  'use strict';

  app
    .controller('WorkplaceIndexCtrl', WorkplaceIndexCtrl)
    .controller('WorkplaceListCtrl', WorkplaceListCtrl)
    .controller('WorkplaceEditCtrl', WorkplaceEditCtrl)
    .controller('ManuallyPcDialogCtrl', ManuallyPcDialogCtrl)
    .controller('SelectItemTypeCtrl', SelectItemTypeCtrl);

  WorkplaceIndexCtrl.$inject = ['Workplaces', 'ActionCableChannel', 'TablePaginator', 'Server', 'Config', 'Flash', 'Error', 'Cookies'];
  WorkplaceListCtrl.$inject = ['$scope', '$compile', '$controller', 'DTOptionsBuilder', 'DTColumnBuilder', 'ActionCableChannel', 'Server', 'Config', 'Flash', 'Error', 'Cookies'];
  WorkplaceEditCtrl.$inject = ['$timeout', '$uibModal', 'Flash', 'Config', 'Workplace', 'WorkplaceItem'];
  ManuallyPcDialogCtrl.$inject = ['$uibModalInstance', 'Flash', 'Workplace', 'WorkplaceItem', 'item'];
  SelectItemTypeCtrl.$inject = ['$scope', '$uibModalInstance', 'data', 'Workplace', 'InventItem', 'Flash'];

  /**
   * Управление общей таблицей рабочих мест.
   *
   * @class SVT.WorkplaceIndexCtrl
   */
  function WorkplaceIndexCtrl(Workplaces, ActionCableChannel, TablePaginator, Server, Config, Flash, Error, Cookies) {
    this.Workplaces = Workplaces;
    this.ActionCableChannel = ActionCableChannel;
    this.TablePaginator = TablePaginator;
    this.Server = Server;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;
    this.pagination = TablePaginator.config();
    this.selectedFilters = this.Workplaces.selectedTableFilters;
    this.filters = this.Workplaces.filters;

    this._loadWorkplaces(true);
    this._initActionCable();

  //   self.Cookies = Cookies;
  //   self.Cookies.Workplace.init();

  //         // Сохраненные фильтры.
  //         filters: {
  //           invent_num: self.Cookies.Workplace.get('tableInventNumFilter') || '',
  //           workplace_id: self.Cookies.Workplace.get('tableIdFilter') || '',
  //           workplace_count_id: self.Cookies.Workplace.get('tableDivisionFilter') || self.divisionFilters[0].workplace_count_id,
  //           status: self.Cookies.Workplace.get('tableStatusFilter') || Object.keys(this.statusFilters)[0],
  //           workplace_type_id: self.Cookies.Workplace.get('tableTypeFilter') || self.typeFilters[0].workplace_type_id
  //         }
  //       },
  //     .withDOM(
  //       '<"row"' +
  //         '<"col-sm-4 col-md-4 col-lg-3 col-xlg-3 col-fhd-2 multiline-buffer"' +
  //           '<"#workplaces.new-record">>' +
  //         '<"col-lg-3 col-xlg-3 col-fhd-9">' +
  //         '<"col-sm-4 col-md-4 col-lg-3 col-xlg-3 col-fhd-2 multiline-buffer"' +
  //           '<"workplaces-invent-num-filter">>' +
  //         '<"col-sm-4 col-md-4 col-lg-3 col-xlg-3 col-fhd-2 multiline-buffer"' +
  //           '<"workplaces-id-filter">>' +
  //         '<"col-sm-4 col-md-4 col-lg-3 col-xlg-3 col-fhd-2 multiline-buffer"' +
  //           '<"workplaces-type-filter">>' +
  //         '<"col-sm-4 col-md-4 col-lg-3 col-xlg-3 col-fhd-2 multiline-buffer"' +
  //           '<"workplaces-division-filter">>' +
  //         '<"col-sm-4 col-md-4 col-lg-3 col-xlg-3 col-fhd-2 multiline-buffer"' +
  //           '<"workplaces-status-filter">>' +
  //         '<"col-sm-4 col-md-4 col-lg-3 col-xlg-3 col-fhd-3 multiline-buffer"f>>' +
  //       '<"row"' +
  //         '<"col-fhd-24"t>>' +
  //       '<"row"' +
  //         '<"col-xs-12"i>' +
  //         '<"col-xs-12"p>>'
  //     );

  // /**
  //  * Заполнить данные фильтров.
  //  *
  //  * @param data - данные фильтров, полученные с сервера
  //  */
  // WorkplaceIndexCtrl.prototype._setFilters = function(data) {
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

  // /**
  //  * Записать выбранные фильтры в cookies.
  //  */
  // WorkplaceIndexCtrl.prototype._setFilterCookies = function() {
  //   this.Cookies.Workplace.set('tableInventNumFilter', this.selectedInventNumFilter);
  //   this.Cookies.Workplace.set('tableIdFilter', this.selectedIdFilter);
  //   this.Cookies.Workplace.set('tableDivisionFilter', this.selectedDivisionFilter.workplace_count_id);
  //   this.Cookies.Workplace.set('tableStatusFilter', this.selectedStatusFilter);
  //   this.Cookies.Workplace.set('tableTypeFilter', this.selectedTypeFilter.workplace_type_id);
  // };
  };

  /**
   * Загрузить данные о РМ.
   *
   * @param init
   */
  WorkplaceIndexCtrl.prototype._loadWorkplaces = function(init) {
    var self = this;

    this.Workplaces.loadWorkplaces(init).then(
      function(response) {
        self.workplaces = self.Workplaces.workplaces;
      }
    );
  };

  /**
   * Инициировать подключение к каналу WorkplacesChannel.
   */
  WorkplaceIndexCtrl.prototype._initActionCable = function() {
    var
      self = this,
      consumer = new this.ActionCableChannel('Invent::WorkplacesChannel');

    consumer.subscribe(function() {
      self._loadWorkplaces();
    });
  };

  /**
   * События изменения страницы.
   */
  WorkplaceIndexCtrl.prototype.changePage = function() {
    this._loadWorkplaces();
  };

  WorkplaceIndexCtrl.prototype.reloadWorkplaces = function() {
    this._loadWorkplaces();
  }

  /**
   * Удалить РМ.
   *
   * @param id
   */
  WorkplaceIndexCtrl.prototype.destroyWp = function(id) {
    var
      self = this,
      confirm_str = "Вы действительно хотите удалить рабочее место \"" + id + "\"?";

    if (!confirm(confirm_str))
      return false;

    self.Server.Invent.Workplace.delete(
      { workplace_id: id },
      function(response) {
        self.Flash.notice(response.full_message);
      },
      function(response, status) {
        self.Error.response(response, status);
      });
  }

// =====================================================================================================================

  /**
   * Управление общей таблицей рабочих мест.
   *
   * @class SVT.WorkplaceListCtrl
   */
  function WorkplaceListCtrl($scope, $compile, $controller, DTOptionsBuilder, DTColumnBuilder, ActionCableChannel, Server, Config, Flash, Error, Cookies) {
    var self = this;

    self.Config = Config;
    self.Flash = Flash;
    self.Error = Error;
    self.Cookies = Cookies;
    self.Cookies.Workplace.init();
    self.Server = Server;

    // Подключаем основные параметры таблицы
    $controller('DefaultDataTableCtrl', {});

    var checkboxCell = '<input ng-model="wpList.flags.all" ng-click="wpList.toggleAll()" ng-disabled="wpList.isEmptyWorkplace()" type="checkbox">';

    // Объект, содержащий данные отделов по инвентаризации (workplace_id => data)
    self.workplaces = {};
    // Фильтр по отделам
    self.divisionFilters = [
      {
        workplace_count_id: 0,
        division: 'Все отделы'
      }
    ];
    // Флаги
    self.flags = {
      // выбрано хотя бы одно поле
      single: false,
      // выбраны все поля
      all: false
    };
    // self.selectAll = false;
    self.dtInstance = {};
    self.dtOptions = DTOptionsBuilder
      .newOptions()
      .withBootstrap()
      .withOption('initComplete', initComplete)
      .withOption('stateSave', true)
      .withDataProp('workplaces')
      .withOption('ajax', {
        url: '/invent/workplaces/list_wp.json',
        data: {
          // Флаг, необходимый, чтобы получить данные для всех фильтров.
          init_filters: true,
          // Сохраненные фильтры.
          filters: {
            workplace_count_id: self.Cookies.Workplace.get('tableListDivisionFilter') || self.divisionFilters[0].workplace_count_id
          }
        },
        error: function(response) {
          self.Error.response(response);
        }
      })
      .withOption('createdRow', createdRow)
      .withOption('headerCallback', headerCallback)
      .withDOM(
        '<"row"' +
          '<"col-sm-6 col-md-6 col-lg-5 col-xlg-4 col-fhd-3"' +
            '<"workplace-list-approve">>' +
          '<"col-sm-10 col-md-11 col-lg-13 col-xlg-14 col-fhd-16">' +
          '<"col-sm-4 col-md-3 col-lg-3 col-xlg-3 col-fhd-2"' +
            '<"workplace-list-division-filter">>' +
          '<"col-sm-4 col-md-4 col-lg-3 col-xlg-3 col-fhd-3"f>>' +
        '<"row"' +
          '<"col-fhd-24"t>>' +
        '<"row"' +
          '<"col-xs-12"i>' +
          '<"col-xs-12"p>>'
      );

    self.dtColumns = [
      DTColumnBuilder.newColumn('workplace_id').withTitle('ID').notSortable().withOption('className', 'col-fhd-1'),
      DTColumnBuilder.newColumn(null).withTitle(checkboxCell).notSortable().renderWith(checkboxCellFunc),
      DTColumnBuilder.newColumn(null).withTitle('Описание').notSortable().withOption('className', 'col-fhd-22').renderWith(showWorkplace),
      DTColumnBuilder.newColumn(null).withTitle('').notSortable().withOption('className', 'col-fhd-1 text-center').renderWith(editRecord)
    ];

    function initComplete(settings, json) {
      // Создание подписки на канал WorkplacesChannel для обновления автоматического обновления таблицы.
      // var consumer = new ActionCableChannel('WorkplaceListChannel');
      // consumer.subscribe(function() {
      //   self.dtInstance.reloadData(null, self.Config.global.reloadPaging);
      // });

      if (json.filters) {
        self._setFilters(json.filters);
      }
    }

    /**
     * Callback после создания каждой строки.
     */
    function createdRow(row, data, dataIndex) {
      self.workplaces[data.workplace_id] = data;
      self.workplaces[data.workplace_id].selected = false;

      // Компиляция строки
      $compile(angular.element(row))($scope);
    }

    /**
     * Отрендерить ссылку на редактирование записи.
     */
    function editRecord(data, type, full, meta) {
      return '<a href="/invent/workplaces/' + data.workplace_id + '/edit" class="default-color pointer"' +
        ' uib-tooltip="Редактировать запись" tooltip-append-to-body="true"><i class="fa fa-pencil-square-o fa-1g"></a>';
    }

    /**
     * Callback после создания каждой строки (применяется к шапке один раз).
     */
    function headerCallback(header) {
      if (!this.headerCompiled) {
        this.headerCompiled = true;
        $compile(angular.element(header).contents())($scope);
      }
    }

    function checkboxCellFunc(data, type, full, meta) {
      return '<input ng-model="wpList.workplaces[' + data.workplace_id + '].selected" ng-click="wpList.toggleOne()" type="checkbox">';
    }

    function showWorkplace(data, type, full, meta) {
      var
        res,
        items = [];

      data.items.forEach(function(value) { items.push('<li>' + value + '</li>'); });
      res = '<span>' + data.workplace + '</span><br>Состав:<ul>' + items.join('') + '</ul>';

      return res;
    }
  }

  /**
   * Заполнить данные фильтров.
   *
   * @param data - данные фильтров, полученные с сервера
   */
  WorkplaceListCtrl.prototype._setFilters = function(data) {
    var cookieVal;

    this.divisionFilters = this.divisionFilters.concat(data.divisions);

    // Установить выбранный фильтр по отделам
    cookieVal = this.Cookies.Workplace.get('tableListDivisionFilter');
    if (angular.isUndefined(cookieVal)) {
      this.selectedDivisionFilter = this.divisionFilters[0];
    } else {
      this.selectedDivisionFilter = this.divisionFilters.find(function(el) { return el.workplace_count_id == cookieVal; });
    }
  };

  /**
   * Записать выбранные фильтры в cookies.
   */
  WorkplaceListCtrl.prototype._setFilterCookies = function() {
    this.Cookies.Workplace.set('tableListDivisionFilter', this.selectedDivisionFilter.workplace_count_id);
  };

  /**
   * Установить служебные переменные в дефолтные состояния.
   */
  WorkplaceListCtrl.prototype._setDefaultTableMetadata = function() {
    this.workplaces = {};
    this.flags.all = false;
    this.flags.single = false;
  };

  /**
   * Удалить элементы из объекта workplaces.
   *
   * @param keys - массив ключей, которые необходимо удалить.
   */
  WorkplaceListCtrl.prototype._removeRow = function(keys) {
    keys.forEach(function(id) { delete this[id]; }, this.workplaces);
    this.dtInstance.reloadData(null, this.Config.global.reloadPaging);
    this._setDefaultTableMetadata();
  };

  /**
   * Возвращает true, если объект workplaces пустой.
   */
  WorkplaceListCtrl.prototype.isEmptyWorkplace = function() {
    return Object.keys(this.workplaces).length == 0;
  };

  /**
   * Выделить или снять всё.
   */
  WorkplaceListCtrl.prototype.toggleAll = function() {
    angular.forEach(this.workplaces, function(value) { value.selected = this.flags.all; }, this);
  };

  /**
   * Проверить, сколько checkbox выделено.
   */
  WorkplaceListCtrl.prototype.toggleOne = function() {
    var
      // Счетчик выделенных полей checkbox
      count = 0,
      // Флаг, который будет присвоен переменной flags.all
      flag = true;

    angular.forEach(this.workplaces, function(wp) { wp.selected ? count ++ : flag = false; });

    this.flags.all = flag;
    this.flags.single = count != 0;
  };

  /**
   * Сохранить фильтры и обновить данные таблицы с учетом фильтров.
   */
  WorkplaceListCtrl.prototype.changeFilter = function() {
    this._setFilterCookies();
    this._setDefaultTableMetadata();

    this.dtInstance.changeData({
      data: {
        filters: {
          workplace_count_id: this.selectedDivisionFilter.workplace_count_id
        }
      }
    });
  };

  /**
   * Обновить данные о РМ.
   */
  WorkplaceListCtrl.prototype.updateWp = function(type) {
    var
      self = this,
      // Список id, которые будут отправлены на сервер
      wpIds = Object.keys(this.workplaces).filter(function(el) { return this.workplaces[el].selected }, this);

    if (wpIds.length == 0) {
      self.Flash.alert('Необходимо выбрать хотя бы одно рабочее место');
      return false;
    }

    this.Server.Invent.Workplace.confirm(
      {
        type: type,
        ids: wpIds
      },
      function success(response) {
        self._removeRow(wpIds);
        self.Flash.notice(response.full_message);
      },
      function error(response) {
        self.Error.response(response);
      })
  };

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
    var self = this;

    self.additional = self.Item.getAdditional();

    this.Workplace.init(id).then(function() {
      // Список типов РМ
      self.wp_types = self.Workplace.wp_types;
      // Типы оборудования на РМ с необходимыми для заполнения свойствами
      self.eq_types = self.Item.getTypes();
      // Направления деятельности
      self.specs = self.Workplace.specs;
      // Список отделов, прикрепленных к пользователю
      self.divisions = self.Workplace.divisions;
      // Список площадок и корпусов
      self.iss_locations = self.Workplace.iss_locations;
      // Список пользователей отдела
      self.users = self.Workplace.users;
      // Список возможных статусов РМ
      self.statuses = self.Workplace.statuses;

      // Данные о рабочем месте
      self.workplace = self.Workplace.workplace;


      if (!id) { self.loadUsers(); }
    });
  };

  /**
   * Загрузить список работников отдела.
   */
  WorkplaceEditCtrl.prototype.loadUsers = function() {
    var self = this;

    this.Workplace.loadUsers().then(function() {
      self.users = self.Workplace.users;
    });
  };

  /**
   * Функция для исправления бага в компоненте typeahead ui.bootstrap. Она возвращает ФИО выбранного пользователя вместо
   * табельного номера.
   *
   * @param id_tn - id_tn выбранного ответственного.
   */
  WorkplaceEditCtrl.prototype.formatLabel = function(id_tn) {
    if (!this.users) { return ''; }

    for (var i = 0; i < this.users.length; i ++) {
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
    var self = this;

    var modalInstance = this.$uibModal.open({
      animation: this.Config.global.modalAnimation,
      templateUrl: 'newItem.slim',
      controller: 'SelectItemTypeCtrl',
      controllerAs: 'select',
      size: 'md',
      backdrop: 'static',
      resolve: {
        data: function() {
          return { eq_types: self.eq_types };
        }
      }
    });

    modalInstance.result.then(
      function(result) {
        if (result.item_id) {
          // Для б/у оборудования с другого РМ
          self.Workplace.addExistingItem(result);
        } else {
          // Для нового оборудования
          self.Workplace.createItem(result);
        }
      },
      function() {
        self.Workplace.setFirstActiveTab()
      });
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
    var self = this;

    if (!this.Item.isValidFile(file)) {
      this.Flash.alert('Необходимо загрузить текстовый файл, полученный в результате работы скачанной вами программы');

      return false;
    }

    this.Workplace.matchUploadFile(file).then(
      function(response) {
        if (!self.Item.matchDataFromUploadedFile(self.item, response.data)) {
          self.Flash.alert('Не удалось обработать данные. Убедитесь в том, что вы загружаете файл, созданный скачанной программой. Если ошибка не исчезает, обратитесь к администратору (т.***REMOVED***)');

          return false;
        }

        self.Flash.notice(response.full_message);
        self.$uibModalInstance.close();
      }
    );
  };

// =====================================================================================================================

  function SelectItemTypeCtrl($scope, $uibModalInstance, data, Workplace, Item, Flash) {
    var self = this;

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
    $scope.division = this.Workplace.workplace.division.division;

    $scope.$on('removeDuplicateInvItems', function(event, data) {
      self._removeDuplicateItems(data);
    });
  }

  /**
   * Из массива self.items удалить технику, которая уже присутствует в составе текущего РМ.
   *
   * @param items
   */
  SelectItemTypeCtrl.prototype._removeDuplicateItems = function(items) {
    var
      self = this,
      index;

    self.Workplace.workplace.items_attributes.forEach(function(item) {
      index = items.findIndex(function(el) { return el.item_id == item.id; });
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

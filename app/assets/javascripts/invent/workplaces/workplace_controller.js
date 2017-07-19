(function () {
  'use strict';

  app
    .controller('WorkplaceIndexCtrl', WorkplaceIndexCtrl)
    .controller('WorkplaceListCtrl', WorkplaceListCtrl)
    .controller('WorkplaceEditCtrl', WorkplaceEditCtrl)
    .controller('ManuallyPcDialogCtrl', ManuallyPcDialogCtrl)
    .controller('SelectItemTypeCtrl', SelectItemTypeCtrl);

  WorkplaceIndexCtrl.$inject = ['$scope', '$compile', '$controller', 'DTOptionsBuilder', 'DTColumnBuilder', 'ActionCableChannel', 'Config', 'Error', 'Cookies'];
  WorkplaceListCtrl.$inject = ['$scope', '$compile', '$controller', 'DTOptionsBuilder', 'DTColumnBuilder', 'ActionCableChannel', 'Server', 'Config', 'Flash', 'Error', 'Cookies'];
  WorkplaceEditCtrl.$inject = ['$filter', '$timeout', '$uibModal', 'Flash', 'Config', 'Workplace', 'Item'];
  ManuallyPcDialogCtrl.$inject = ['$uibModalInstance', 'Flash', 'Workplace', 'Item', 'item'];
  SelectItemTypeCtrl.$inject = ['$uibModalInstance', 'data', 'Workplace'];

  /**
   * Управление общей таблицей рабочих мест.
   *
   * @class SVT.WorkplaceIndexCtrl
   */
  function WorkplaceIndexCtrl($scope, $compile, $controller, DTOptionsBuilder, DTColumnBuilder, ActionCableChannel, Config, Error, Cookies) {
    var self = this;

// =============================================== Инициализация =======================================================

    self.Config = Config;
    self.Error = Error;
    self.Cookies = Cookies;
    self.Cookies.Workplace.init();
    // Фильтр по отделам
    self.divisionFilters = [
      {
        workplace_count_id: 0,
        division: 'Все отделы'
      }
    ];
    // Фильтр по статусам
    self.statusFilters = { 'all': 'Все статусы' };
    // Фильтр по типам РМ
    self.typeFilters = [
      {
        workplace_type_id: 0,
        short_description: 'Все типы'
      }
    ];

    // Подключаем основные параметры таблицы
    $controller('DefaultDataTableCtrl', {});

    // Объект, содержащий данные отделов по инвентаризации (workplace_id => data)
    self.workplaces = {};
    self.dtInstance = {};
    self.dtOptions = DTOptionsBuilder
      .newOptions()
      .withBootstrap()
      .withOption('initComplete', initComplete)
      .withOption('stateSave', true)
      .withDataProp('workplaces')
      .withOption('ajax', {
        url: '/invent/workplaces.json',
        data: {
          // Флаг, необходимый, чтобы получить данные для всех фильтров.
          init_filters: true,
          // Сохраненные фильтры.
          filters: {
            workplace_count_id: self.Cookies.Workplace.get('tableDivisionFilter') || self.divisionFilters[0].workplace_count_id,
            status: self.Cookies.Workplace.get('tableStatusFilter') || Object.keys(this.statusFilters)[0],
            workplace_type_id: self.Cookies.Workplace.get('tableTypeFilter') || self.typeFilters[0].workplace_type_id
          }
        },
        error: function (response) {
          self.Error.response(response);
        }
      })
      .withOption('createdRow', createdRow)
      .withDOM(
        '<"row"' +
          '<"col-sm-8 col-md-12 col-lg-12 col-xlg-12 col-fhd-15">' +
          '<"col-sm-4 col-md-3 col-lg-3 col-xlg-3 col-fhd-2"' +
            '<"workplaces-type-filter">>' +
          '<"col-sm-4 col-md-3 col-lg-3 col-xlg-3 col-fhd-2"' +
            '<"workplaces-division-filter">>' +
          '<"col-sm-4 col-md-3 col-lg-3 col-xlg-3 col-fhd-2"' +
            '<"workplaces-status-filter">>' +
          '<"col-sm-4 col-md-3 col-lg-3 col-xlg-3 col-fhd-3"f>>' +
        '<"row"' +
          '<"col-fhd-24"t>>' +
        '<"row"' +
          '<"col-fhd-12"i>' +
          '<"col-fhd-12"p>>'
      );

    self.dtColumns = [
      DTColumnBuilder.newColumn(null).withTitle('').withOption('className', 'col-fhd-1').renderWith(renderIndex),
      DTColumnBuilder.newColumn('division').withTitle('Отдел').withOption('className', 'col-fhd-2'),
      DTColumnBuilder.newColumn('wp_type').withTitle('Тип').withOption('className', 'col-fhd-4'),
      DTColumnBuilder.newColumn('responsible').withTitle('Ответственный').withOption('className', 'col-fhd-5'),
      DTColumnBuilder.newColumn('location').withTitle('Расположение').withOption('className', 'col-fhd-5'),
      DTColumnBuilder.newColumn('count').withTitle('Кол-во техники').withOption('className', 'col-fhd-2'),
      DTColumnBuilder.newColumn('status').withTitle('Статус').notSortable().withOption('className', 'col-fhd-3').renderWith(statusRecord),
      DTColumnBuilder.newColumn(null).withTitle('').notSortable().withOption('className', 'col-fhd-1 text-center').renderWith(editRecord),
      DTColumnBuilder.newColumn(null).withTitle('').notSortable().withOption('className', 'col-fhd-1 text-center').renderWith(delRecord)
    ];

    function initComplete(settings, json) {
      // Создание подписки на канал WorkplacesChannel для обновления автоматического обновления таблицы.
      var consumer = new ActionCableChannel('WorkplacesChannel');
      consumer.subscribe(function () {
        self.dtInstance.reloadData(null, self.Config.global.reloadPaging);
      });

      if (json.filters) {
        self._setFilters(json.filters);
      }
    }

    /**
     * Показать номер строки.
     */
    function renderIndex(data, type, full, meta) {
      self.workplaces[data.workplace_id] = data;
      return meta.row + 1;
    }

    /**
     * Callback после создания каждой строки.
     */
    function createdRow(row, data, dataIndex) {
      // Компиляция строки
      $compile(angular.element(row))($scope);
    }

    /**
     * Вывести статус в формате label.
     */
    function statusRecord(data, type, full, meta) {
      var labelClass;

      switch(data) {
        case 'Подтверждено':
          labelClass = 'label-success';
          break;
        case 'В ожидании проверки':
          labelClass = 'label-warning';
          break;
        case 'Отклонено':
          labelClass = 'label-danger';
      }

      return '<span class="label ' + labelClass + '">' + data + '</span>';
    }

    /**
     * Отрендерить ссылку на редактирование записи.
     */
    function editRecord(data, type, full, meta) {
      return '<a href="/invent/workplaces/' + data.workplace_id + '/edit" class="default-color pointer"' +
        ' uib-tooltip="Редактировать запись"><i class="fa fa-pencil-square-o fa-1g"></a>';
    }

    /**
     * Отрендерить ссылку на удаление данных.
     */
    function delRecord(data, type, full, meta) {
      return '<a href="" class="text-danger pointer" disable-link=true ng-click="wpIndex.destroyRecord(' +
        data.workplace_id + ')" uib-tooltip="Удалить запись"><i class="fa fa-trash-o fa-1g"></a>';
    }
  }

  /**
   * Заполнить данные фильтров.
   *
   * @param data - данные фильтров, полученные с сервера
   */
  WorkplaceIndexCtrl.prototype._setFilters = function (data) {
    var cookieVal;

    this.divisionFilters = this.divisionFilters.concat(data.divisions);
    Object.assign(this.statusFilters, data.statuses);
    this.typeFilters = this.typeFilters.concat(data.types);

    // Установить выбранный фильтр по отделам
    cookieVal = this.Cookies.Workplace.get('tableDivisionFilter');
    if (angular.isUndefined(cookieVal)) {
      this.selectedDivisionFilter = this.divisionFilters[0];
    } else {
      this.selectedDivisionFilter = $.grep(this.divisionFilters, function (el) { return el.workplace_count_id == cookieVal })[0];
    }

    // Установить выбранный фильтр по статусам РМ
    cookieVal = this.Cookies.Workplace.get('tableStatusFilter');
    if (angular.isUndefined(cookieVal)) {
      this.selectedStatusFilter = Object.keys(this.statusFilters)[0];
    } else {
      this.selectedStatusFilter = cookieVal;
    }

    // Установить выбранный фильтр по типам РМ
    cookieVal = this.Cookies.Workplace.get('tableTypeFilter');
    if (angular.isUndefined(cookieVal)) {
      this.selectedTypeFilter = this.typeFilters[0];
    } else {
      this.selectedTypeFilter = $.grep(this.typeFilters, function (el) { return el.workplace_type_id == cookieVal })[0];
    }
  };

  /**
   * Записать выбранные фильтры в cookies.
   */
  WorkplaceIndexCtrl.prototype._setFilterCookies = function () {
    this.Cookies.Workplace.set('tableDivisionFilter', this.selectedDivisionFilter.workplace_count_id);
    this.Cookies.Workplace.set('tableStatusFilter', this.selectedStatusFilter);
    this.Cookies.Workplace.set('tableTypeFilter', this.selectedTypeFilter.workplace_type_id);
  };

  /**
   * Сохранить фильтры и обновить данные таблицы с учетом фильтров.
   */
  WorkplaceIndexCtrl.prototype.changeFilter = function () {
    this._setFilterCookies();

    this.dtInstance.changeData({
      data: {
        filters: {
          workplace_count_id: this.selectedDivisionFilter.workplace_count_id,
          status: this.selectedStatusFilter,
          workplace_type_id: this.selectedTypeFilter.workplace_type_id
        }
      }
    });
  };

  /**
   * Удалить рабочее место.
   */
  WorkplaceIndexCtrl.prototype.destroyRecord = function () {

  };

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
        error: function (response) {
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
          '<"col-fhd-12"i>' +
          '<"col-fhd-12"p>>'
      );

    self.dtColumns = [
      DTColumnBuilder.newColumn(null).withTitle('').renderWith(renderIndex),
      DTColumnBuilder.newColumn(null).withTitle(checkboxCell).notSortable().renderWith(checkboxCellFunc),
      DTColumnBuilder.newColumn(null).withTitle('Описание').notSortable().withOption('className', 'col-fhd-23').renderWith(showWorkplace)
    ];

    function initComplete(settings, json) {
      // Создание подписки на канал WorkplacesChannel для обновления автоматического обновления таблицы.
      var consumer = new ActionCableChannel('WorkplaceListChannel');
      consumer.subscribe(function () {
        self.dtInstance.reloadData(null, self.Config.global.reloadPaging);
      });

      if (json.filters) {
        self._setFilters(json.filters);
      }
    }

    /**
     * Показать номер строки.
     */
    function renderIndex(data, type, full, meta) {
      return meta.row + 1;
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

      angular.forEach(data.items, function (value) { items.push('<li>' + value + '</li>'); });
      res = '<span>' + data.workplace + '</span><br>Состав:<ul>' + items.join('') + '</ul>';

      return res;
    }
  }

  /**
   * Заполнить данные фильтров.
   *
   * @param data - данные фильтров, полученные с сервера
   */
  WorkplaceListCtrl.prototype._setFilters = function (data) {
    var cookieVal;

    this.divisionFilters = this.divisionFilters.concat(data.divisions);

    // Установить выбранный фильтр по отделам
    cookieVal = this.Cookies.Workplace.get('tableListDivisionFilter');
    if (angular.isUndefined(cookieVal)) {
      this.selectedDivisionFilter = this.divisionFilters[0];
    } else {
      this.selectedDivisionFilter = $.grep(this.divisionFilters, function (el) { return el.workplace_count_id == cookieVal })[0];
    }
  };

  /**
   * Записать выбранные фильтры в cookies.
   */
  WorkplaceListCtrl.prototype._setFilterCookies = function () {
    this.Cookies.Workplace.set('tableListDivisionFilter', this.selectedDivisionFilter.workplace_count_id);
  };

  /**
   * Установить служебные переменные в дефолтные состояния.
   */
  WorkplaceListCtrl.prototype._setDefaultTableMetadata = function () {
    this.workplaces = {};
    this.flags.all = false;
    this.flags.single = false;
  };

  /**
   * Удалить элементы из объекта workplaces.
   *
   * @param keys - массив ключей, которые необходимо удалить.
   */
  WorkplaceListCtrl.prototype._removeRow = function (keys) {
    angular.forEach(keys, function (id) { delete this[id] }, this.workplaces);
    if (this.isEmptyWorkplace()) {
      this._setDefaultTableMetadata();
    }
  };

  /**
   * Возвращает true, если объект workplaces пустой.
   */
  WorkplaceListCtrl.prototype.isEmptyWorkplace = function () {
    return Object.keys(this.workplaces).length == 0;
  };

  /**
   * Выделить или снять всё.
   */
  WorkplaceListCtrl.prototype.toggleAll = function () {
    var self = this;
    angular.forEach(self.workplaces, function (value) { value.selected = self.flags.all; });
  };

  /**
   * Проверить, сколько checkbox выделено.
   */
  WorkplaceListCtrl.prototype.toggleOne = function () {
    var
      self = this,
      // Счетчик выделенных полей checkbox
      count = 0,
      // Флаг, который будет присвоен переменной flags.all
      flag = true;

    angular.forEach(self.workplaces, function (wp) {
      if (!wp.selected) {
        flag = false;
      }
      else {
        count ++;
      }
    });

    this.flags.all = flag;
    this.flags.single = count != 0;
  };

  /**
   * Сохранить фильтры и обновить данные таблицы с учетом фильтров.
   */
  WorkplaceListCtrl.prototype.changeFilter = function () {
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
  WorkplaceListCtrl.prototype.updateWp = function (type) {
    var
      self = this,
      wpIds = $.grep(Object.keys(this.workplaces), function (el) { return self.workplaces[el].selected });

    if (wpIds.length == 0) {
      self.Flash.alert('Необходимо выбрать хотя бы одно рабочее место');
      return false;
    }

    this.Server.Workplace.confirm(
      {
        type: type,
        ids: wpIds
      },
      function success(response) {
        self.dtInstance.reloadData(null, self.Config.global.reloadPaging);
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
  function WorkplaceEditCtrl($filter, $timeout, $uibModal, Flash, Config, Workplace, Item) {
    this.$filter = $filter;
    this.$timeout = $timeout;
    this.$uibModal = $uibModal;
    this.Flash = Flash;
    this.Config = Config;
    this.Workplace = Workplace;
    this.Item = Item;
  }

  WorkplaceEditCtrl.prototype.init = function (id) {
    var self = this;

    self.additional = self.Item.getAdditional();

    this.Workplace.init(id).then(function () {
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
    });
  };

  /**
   * Функция для исправления бага в компоненте typeahead ui.bootstrap. Она возвращает ФИО выбранного пользователя вместо
   * табельного номера.
   *
   * @param id_tn - id_tn выбранного ответственного.
   */
  WorkplaceEditCtrl.prototype.formatLabel = function (id_tn) {
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
  WorkplaceEditCtrl.prototype.setWorkplaceType = function () {
    this.workplace.workplace_type_id = angular.copy(this.workplace.workplace_type.workplace_type_id);
  };

  /**
   * Установить location_site_id рабочего места.
   */
  WorkplaceEditCtrl.prototype.setLocationSite = function () {
    this.workplace.location_site_id = angular.copy(this.workplace.location_site.site_id);
  };

  /**
   * Установить начальное значение для корпуса при изменении площадки.
   */
  WorkplaceEditCtrl.prototype.setDefaultLocation = function (type) {
    this.Workplace.setDefaultLocation(type);
  };

  /**
   * Проверить, совпадает ли инвентарный номер с сохраненным (после потери фокуса поля "Инвентарный").
   *
   * @param item - объект item массива inv_atems_attributes.
   */
  WorkplaceEditCtrl.prototype.checkPcInvnum = function (item) {
    if (
      // Относится ли текущий тип оборудования к тем, что указаны в массиве pcTypes.
    !this.$filter('contains')(this.additional.pcTypes, item.type.name)
    // Совпадает ли инв. номер с сохраненным
    || this.additional.invent_num == item.invent_num
    ) { return false; }

    // Очистить состав ПК
    this.Item.clearPropertyValues(item);
    // Удалить загруженный файл
    this.Item.setPcFile(null);
    // Убрать флаг
    this.additional.auditData = false;
  };

  /**
   * Отправить запрос в Аудит для получения конфигурации оборудования.
   *
   * @param item
   */
  WorkplaceEditCtrl.prototype.getAuditData = function (item) {
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
  WorkplaceEditCtrl.prototype.runManuallyPcDialog = function (item) {
    if (item.invent_num) {
      this.$uibModal.open({
        animation: this.Config.global.modalAnimation,
        templateUrl: 'manuallyPcDialog.slim',
        controller: 'ManuallyPcDialogCtrl',
        controllerAs: 'manually',
        size: 'md',
        backdrop: 'static',
        resolve: {
          item: function () { return item; }
        }
      });
    } else {
      this.Flash.alert('Сначала необходимо ввести инвентарный номер');
    }
  };

  /**
   * Очистить инвентарный номер, данные, полученные от аудита, а также удалить загруженный файл.
   *
   * @param item
   */
  WorkplaceEditCtrl.prototype.changeAuditData = function (item) {
    this.Item.clearPcMetadata(item);
    this.Item.clearPropertyValues(item);
  };

  /**
   * Записать в модель workplace.inv_items данные о выбранной модели выбранного типа оборудования.
   *
   * @param item - экземпляр техники, у которого изменили модель
   */
  WorkplaceEditCtrl.prototype.changeItemModel = function (item) {
    this.Item.changeModel(item);
  };

  /**
   * Отправить данные на сервер для сохранения и закрыть Wizzard.
   */
  WorkplaceEditCtrl.prototype.saveWorkplace = function () {
    this.Workplace.saveWorkplace()
  };

  /**
   * Запустить диалоговое окно "Выбор типа устройства".
   */
  WorkplaceEditCtrl.prototype.showSelectItemType = function () {
    var self = this;

    var modalInstance = this.$uibModal.open({
      animation: this.Config.global.modalAnimation,
      templateUrl: 'newItem.slim',
      controller: 'SelectItemTypeCtrl',
      controllerAs: 'select',
      size: 'md',
      backdrop: 'static',
      resolve: {
        data: function () {
          return { eq_types: self.eq_types };
        }
      }
    });

    modalInstance.result.then(
      function (selectedType) {
        self.Workplace.createItem(selectedType);
      },
      function () {
        self.Workplace.setFirstActiveTab()
      });
  };

  /**
   * Удалить выбранное оборудование из состава РМ.
   *
   * @param item - удаляемый элемент.
   * @param $event - объект события.
   */
  WorkplaceEditCtrl.prototype.delItem = function (item, $event) {
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
  function ManuallyPcDialogCtrl($uibModalInstance, Flash, Workplace, Item, item) {
    this.$uibModalInstance = $uibModalInstance;
    this.Flash = Flash;
    this.Workplace = Workplace;
    this.Item = Item;
    this.item = item;
  }

  /**
   * Скачать скрипт.
   */
  ManuallyPcDialogCtrl.prototype.downloadPcScript = function () {
    this.Workplace.downloadPcScript();
  };

  /**
   * Закрыть модальное окно.
   */
  ManuallyPcDialogCtrl.prototype.close = function () {
    this.$uibModalInstance.close();
  };

  /**
   * Сохранить файл в общую структуру данных.
   *
   * @param file
   */
  ManuallyPcDialogCtrl.prototype.setPcFile = function (file) {
    var self = this;

    if (!this.Item.fileValidationPassed(file)) {
      this.Flash.alert('Необходимо загрузить текстовый файл, полученный в результате работы скачанной вами программы');

      return false;
    }

    this.Item.setPcFile(file);
    this.Item.setAdditional('auditData', true);
    this.Item.setFileName(this.item, file.name);

    var reader = new FileReader();
    reader.onload = function (event) {
      self.Item.matchDataFromUploadedFile(self.item, event.target.result);
      self.Item.setAdditional('invent_num', angular.copy(self.item.invent_num));
      self.Flash.notice('Файл добавлен');
      self.$uibModalInstance.close();
    };
    reader.readAsText(file);
  };

// =====================================================================================================================

  function SelectItemTypeCtrl($uibModalInstance, data, Workplace) {
    this.$uibModalInstance = $uibModalInstance;
    // Типы оборудования
    this.eq_types = data.eq_types;
    // Выбранный тип устройства
    this.selected = angular.copy(this.eq_types[0]);
    this.Workplace = Workplace
  }

  /**
   * Проверка валидаций выбранного типа оборудования.
   */
  SelectItemTypeCtrl.prototype.validateSelectedType = function () {
    if (!this.Workplace.validateType(this.selected))
      this.selected = angular.copy(this.eq_types[0]);
  };

  SelectItemTypeCtrl.prototype.ok = function () {
    if (this.Workplace.validateType(this.selected))
      this.$uibModalInstance.close(this.selected);
  };

  SelectItemTypeCtrl.prototype.cancel = function () {
    this.$uibModalInstance.dismiss();
  };
})();
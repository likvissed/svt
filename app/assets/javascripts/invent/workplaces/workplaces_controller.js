(function () {
  'use strict';

  app
    .controller('WorkplaceIndexCtrl', WorkplaceIndexCtrl)
    .controller('WorkplaceListCtrl', WorkplaceListCtrl)
    .controller('WorkplaceEditCtrl', WorkplaceEditCtrl)
    .controller('ManuallyPcDialogCtrl', ManuallyPcDialogCtrl)
    .controller('SelectItemTypeCtrl', SelectItemTypeCtrl);

  WorkplaceIndexCtrl.$inject = ['$scope', '$compile', '$controller', 'DTOptionsBuilder', 'DTColumnBuilder', 'ActionCableChannel', 'Server', 'Config', 'Flash', 'Error', 'Cookies'];
  WorkplaceListCtrl.$inject = ['$scope', '$compile', '$controller', 'DTOptionsBuilder', 'DTColumnBuilder', 'ActionCableChannel', 'Server', 'Config', 'Flash', 'Error', 'Cookies'];
  WorkplaceEditCtrl.$inject = ['$filter', '$timeout', '$uibModal', 'Flash', 'Config', 'Workplace', 'Item'];
  ManuallyPcDialogCtrl.$inject = ['$uibModalInstance', 'Flash', 'Workplace', 'Item', 'item'];
  SelectItemTypeCtrl.$inject = ['$uibModalInstance', 'data', 'Workplace', 'Flash'];

  /**
   * Управление общей таблицей рабочих мест.
   *
   * @class SVT.WorkplaceIndexCtrl
   */
  function WorkplaceIndexCtrl($scope, $compile, $controller, DTOptionsBuilder, DTColumnBuilder, ActionCableChannel, Server, Config, Flash, Error, Cookies) {
    var self = this;

// =============================================== Инициализация =======================================================

    self.Server = Server;
    self.Config = Config;
    self.Flash = Flash;
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
      .withOption('serverSide', true)
      .withOption('processing', true)
      .withOption('initComplete', initComplete)
      .withOption('stateSave', true)
      .withLanguage({
        searchPlaceholder: 'ФИО'
      })
      .withDataProp('data')
      .withOption('ajax', {
        url: '/invent/workplaces.json',
        data: {
          // Флаг, необходимый, чтобы получить данные для всех фильтров.
          init_filters: true,
          // Сохраненные фильтры.
          filters: {
            invent_num: self.Cookies.Workplace.get('tableInventNumFilter') || '',
            workplace_id: self.Cookies.Workplace.get('tableIdFilter') || '',
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
          '<"col-sm-4 col-md-4 col-lg-3 col-xlg-3 col-fhd-2 multiline-buffer"' +
            '<"#workplaces.new-record">>' +
          '<"col-lg-3 col-xlg-3 col-fhd-9">' +
          '<"col-sm-4 col-md-4 col-lg-3 col-xlg-3 col-fhd-2 multiline-buffer"' +
            '<"workplaces-invent-num-filter">>' +
          '<"col-sm-4 col-md-4 col-lg-3 col-xlg-3 col-fhd-2 multiline-buffer"' +
            '<"workplaces-id-filter">>' +
          '<"col-sm-4 col-md-4 col-lg-3 col-xlg-3 col-fhd-2 multiline-buffer"' +
            '<"workplaces-type-filter">>' +
          '<"col-sm-4 col-md-4 col-lg-3 col-xlg-3 col-fhd-2 multiline-buffer"' +
            '<"workplaces-division-filter">>' +
          '<"col-sm-4 col-md-4 col-lg-3 col-xlg-3 col-fhd-2 multiline-buffer"' +
            '<"workplaces-status-filter">>' +
          '<"col-sm-4 col-md-4 col-lg-3 col-xlg-3 col-fhd-3 multiline-buffer"f>>' +
        '<"row"' +
          '<"col-fhd-24"t>>' +
        '<"row"' +
          '<"col-xs-12"i>' +
          '<"col-xs-12"p>>'
      );

    self.dtColumns = [
      DTColumnBuilder.newColumn('workplace_id').withTitle('ID').notSortable().withOption('className', 'col-fhd-1'),
      DTColumnBuilder.newColumn('division').withTitle('Отдел').notSortable().withOption('className', 'col-fhd-2'),
      DTColumnBuilder.newColumn('wp_type').withTitle('Тип').notSortable().withOption('className', 'col-fhd-4'),
      DTColumnBuilder.newColumn('responsible').withTitle('Ответственный').notSortable().withOption('className', 'col-fhd-6'),
      DTColumnBuilder.newColumn('location').withTitle('Расположение').notSortable().withOption('className', 'col-fhd-5'),
      DTColumnBuilder.newColumn('count').withTitle('Кол-во техники').notSortable().withOption('className', 'col-fhd-2'),
      DTColumnBuilder.newColumn('status').withTitle('Статус').notSortable().notSortable().withOption('className', 'col-fhd-2').renderWith(statusRecord),
      DTColumnBuilder.newColumn(null).withTitle('').notSortable().withOption('className', 'col-fhd-1 text-center').renderWith(editRecord),
      DTColumnBuilder.newColumn(null).withTitle('').notSortable().withOption('className', 'col-fhd-1 text-center').renderWith(delRecord)
    ];

    function initComplete(settings, json) {
      // $('.dataTables_filter input').off().on('input', function (e) {});

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
          break;
        case 'Заморожено':
          labelClass = 'label-primary';
          break;
      }

      return '<span class="label ' + labelClass + '">' + data + '</span>';
    }

    /**
     * Отрендерить ссылку на редактирование записи.
     */
    function editRecord(data, type, full, meta) {
      return '<a href="/invent/workplaces/' + data.workplace_id + '/edit" class="default-color pointer"' +
        ' uib-tooltip="Редактировать состав рабочего места" tooltip-append-to-body="true"><i ' +
        'class="fa fa-pencil-square-o fa-1g"></a>';
    }

    /**
     * Отрендерить ссылку на удаление данных.
     */
    function delRecord(data, type, full, meta) {
      return '<a href="" class="text-danger pointer" disable-link=true ng-click="wpIndex.destroyWp(' +
        data.workplace_id + ')" uib-tooltip="Удалить рабочее место (с сохранением техники)" ' +
        'tooltip-append-to-body="true"><i class="fa fa-trash-o fa-1g"></a>';
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

    // Установить выбранный фильтр по инвентарному номеру
    cookieVal = this.Cookies.Workplace.get('tableInventNumFilter');
    if (angular.isUndefined(cookieVal)) {
      this.selectedInventNumFilter = '';
    } else {
      this.selectedInventNumFilter = cookieVal;
    }

    // Установить выбранный фильтр по ID рабочего места
    cookieVal = this.Cookies.Workplace.get('tableIdFilter');
    if (angular.isUndefined(cookieVal)) {
      this.selectedIdFilter = '';
    } else {
      this.selectedIdFilter = cookieVal;
    }

    // Установить выбранный фильтр по отделам
    cookieVal = this.Cookies.Workplace.get('tableDivisionFilter');
    if (angular.isUndefined(cookieVal)) {
      this.selectedDivisionFilter = this.divisionFilters[0];
    } else {
      this.selectedDivisionFilter = this.divisionFilters.find(function (el) { return el.workplace_count_id == cookieVal })
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
      this.selectedTypeFilter = this.typeFilters.find(function (el) { return el.workplace_type_id == cookieVal })
    }
  };

  /**
   * Записать выбранные фильтры в cookies.
   */
  WorkplaceIndexCtrl.prototype._setFilterCookies = function () {
    this.Cookies.Workplace.set('tableInventNumFilter', this.selectedInventNumFilter);
    this.Cookies.Workplace.set('tableIdFilter', this.selectedIdFilter);
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
          invent_num: this.selectedInventNumFilter,
          workplace_id: this.selectedIdFilter,
          workplace_count_id: this.selectedDivisionFilter.workplace_count_id,
          status: this.selectedStatusFilter,
          workplace_type_id: this.selectedTypeFilter.workplace_type_id
        }
      }
    });
  };

  /**
   * Удалить рабочее место.
   *
   * @params id - id рабочего места.
   */
  WorkplaceIndexCtrl.prototype.destroyWp = function (id) {
    var
      self = this,
      confirm_str = "Вы действительно хотите удалить рабочее место \"" + id + "\"?";

    if (!confirm(confirm_str))
      return false;

    self.Server.Invent.Workplace.delete(
      { workplace_id: id },
      function (response) {
        console.log(response);
        self.Flash.notice(response.full_message);
        self.dtInstance.reloadData(null, self.Config.global.reloadPaging);
      },
      function (response, status) {
        self.Error.response(response, status);
      });
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
          '<"col-xs-12"i>' +
          '<"col-xs-12"p>>'
      );

    self.dtColumns = [
      DTColumnBuilder.newColumn(null).withTitle('').renderWith(renderIndex),
      DTColumnBuilder.newColumn(null).withTitle(checkboxCell).notSortable().renderWith(checkboxCellFunc),
      DTColumnBuilder.newColumn(null).withTitle('Описание').notSortable().withOption('className', 'col-fhd-22').renderWith(showWorkplace),
      DTColumnBuilder.newColumn(null).withTitle('').notSortable().withOption('className', 'col-fhd-1 text-center').renderWith(editRecord)
    ];

    function initComplete(settings, json) {
      // Создание подписки на канал WorkplacesChannel для обновления автоматического обновления таблицы.
      // var consumer = new ActionCableChannel('WorkplaceListChannel');
      // consumer.subscribe(function () {
      //   self.dtInstance.reloadData(null, self.Config.global.reloadPaging);
      // });

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
      this.selectedDivisionFilter = this.divisionFilters.find(function (el) { return el.workplace_count_id == cookieVal });
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
    var self = this;

    keys.forEach(function (id) { delete this[id] }, this.workplaces);
    this.dtInstance.reloadData(null, self.Config.global.reloadPaging);

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

      if (!id) { self.loadUsers(); }
    });
  };

  /**
   * Загрузить список работников отдела.
   */
  WorkplaceEditCtrl.prototype.loadUsers = function () {
    var self = this;

    this.Workplace.loadUsers().then(function () {
      self.users = self.Workplace.users;
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
      function (result) {
        if (result.selectedItem) {
          // Для б/у оборудования
          self.Workplace.addExistingItem(result.selectedType, result.selectedItem);
        } else {
          // Для нового оборудования
          self.Workplace.createItem(result.selectedType);
        }
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

    this.Workplace.matchUploadFile(file).then(
      function (response) {
        self.Item.setPcFile(file);
        self.Item.setAdditional('auditData', true);
        self.Item.setFileName(self.item, file.name);

        if (!self.Item.matchDataFromUploadedFile(self.item, response.data.data)) {
          self.Flash.alert('Не удалось обработать данные. Убедитесь в том, что вы загружаете файл, созданный скачанной программой. Если ошибка не исчезает, обратитесь к администратору (т.***REMOVED***)');
          //self.invent.changeAuditData(self.item);

          return false;
        }

        self.Item.setAdditional('invent_num', angular.copy(self.item.invent_num));
        self.Flash.notice(response.data.full_message);
        self.$uibModalInstance.close();
      }
    );
  };

// =====================================================================================================================

  function SelectItemTypeCtrl($uibModalInstance, data, Workplace, Flash) {
    this.$uibModalInstance = $uibModalInstance;
    this.Flash = Flash;
    // Типы оборудования
    this.eq_types = data.eq_types;
    // Выбранный тип устройства
    this.selectedType = angular.copy(this.eq_types[0]);
    // Выбранная техника (Б/У)
    this.selectedItem = {};
    this.Workplace = Workplace;
    // Тип техники: новая или б/у
    this.itemType = '';
  }

  /**
   * Из массива self.items удалить технику, которая уже присутствует в составе текущего РМ.
   */
  SelectItemTypeCtrl.prototype._removeDuplicateItems = function() {
    var
      self = this,
      index;

    self.Workplace.workplace.inv_items_attributes.forEach(function (item) {
      index = self.items.findIndex(function (el) { return el.item_id == item.id; });
      if (index != -1) {
        self.items.splice(index, 1);
      }
    })
  };

  SelectItemTypeCtrl.prototype.setInitselectedType = function() {
    this.selectedType = angular.copy(this.eq_types[0]);
  };

  /**
   * Проверка валидаций выбранного типа оборудования.
   */
  SelectItemTypeCtrl.prototype.validateSelectedType = function() {
    if (this.Workplace.validateType(this.selectedType)) {
      return true;
    } else {
      this.selectedType = angular.copy(this.eq_types[0]);
      return false;
    }
  };

  /**
   * Загрузить всё Б/У оборудование со склада.
   */
  SelectItemTypeCtrl.prototype.loadItems = function() {
    var self = this;

    if (!this.validateSelectedType()) {
      return false;
    }

    this.Workplace.loadUsedItems(this.selectedType.type_id)
      .then(function(response) {
        self.items = response;
        self._removeDuplicateItems();
      });
  };

  SelectItemTypeCtrl.prototype.ok = function() {
    var result = { selectedType: this.selectedType };

    if (this.itemType == 'new') {
      if (this.Workplace.validateType(this.selectedType)) {
        this.$uibModalInstance.close(result);
      }
    } else {
      if (this.Workplace.validateType(this.selectedType) && this.selectedItem.item_id) {
        result['selectedItem'] = this.selectedItem;
        this.$uibModalInstance.close(result);
      } else {
        this.Flash.alert('Необходимо выбрать технику.');
      }
    }
  };

  SelectItemTypeCtrl.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };
})();

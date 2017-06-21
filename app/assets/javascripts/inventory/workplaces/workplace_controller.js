app
  .controller('WorkplaceIndexCtrl', WorkplaceIndexCtrl)
  .controller('WorkplaceEditCtrl', WorkplaceEditCtrl)
  .controller('ManuallyPcDialogCtrl', ManuallyPcDialogCtrl)
  .controller('SelectItemTypeCtrl', SelectItemTypeCtrl);

WorkplaceIndexCtrl.$inject = ['$scope', '$compile', '$controller', 'DTOptionsBuilder', 'DTColumnBuilder'];
WorkplaceEditCtrl.$inject = ['$filter', '$timeout', '$uibModal', 'Flash', 'Config', 'Workplace', 'Item'];
ManuallyPcDialogCtrl.$inject = ['$uibModalInstance', 'Flash', 'Workplace', 'Item', 'item'];
SelectItemTypeCtrl.$inject = ['$uibModalInstance', 'data', 'Workplace'];

/**
 * Управление общей таблицей рабочих мест.
 *
 * @class SVT.WorkplaceIndexCtrl
 */
function WorkplaceIndexCtrl($scope, $compile, $controller, DTOptionsBuilder, DTColumnBuilder) {
  var self = this;

// =============================================== Инициализация =======================================================

  // Подключаем основные параметры таблицы
  $controller('DefaultDataTableCtrl', {});

  // Объект, содержащий данные отделов по инвентаризации (workplace_id => data)
  self.workplaces = {};
  self.dtInstance = {};
  self.dtOptions = DTOptionsBuilder
    .newOptions()
    .withOption('initComplete', initComplete)
    .withOption('stateSave', true)
    .withOption('ajax', {
      url: '/inventory/workplaces.json',
      error: function (response) {
        // Error.response(response);
      }
    })
    .withOption('createdRow', createdRow)
    .withDOM(
      '<"row"' +
        '<"col-sm-20 col-md-21 col-lg-21 col-fhd-21">' +
        '<"col-sm-4 col-md-3 col-lg-3 col-fhd-3"f>>' +
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
    console.log(json);
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
    return '<a href="/inventory/workplaces/' + data.workplace_id + '/edit" class="default-color"' +
      ' uib-tooltip="Редактировать запись"><i class="fa fa-pencil-square-o fa-1g"></a>';
  }

  /**
   * Отрендерить ссылку на удаление данных.
   */
  function delRecord(data, type, full, meta) {
    return '<a href="" class="text-danger" disable-link=true ng-click="wpIndex.destroyRecord(' + data.workplace_id +
      ')" uib-tooltip="Удалить запись"><i class="fa fa-trash-o fa-1g"></a>';
  }
}

/**
 * Удалить рабочее место.
 */
WorkplaceIndexCtrl.prototype.destroyRecord = function () {
  
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

  for (var i=0; i< this.users.length; i++) {
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
app
  .controller('WorkplaceIndexCtrl', WorkplaceIndexCtrl)
  .controller('WorkplaceEditCtrl', WorkplaceEditCtrl);

WorkplaceIndexCtrl.$inject = ['$scope', '$compile', '$controller', 'DTOptionsBuilder', 'DTColumnBuilder'];
WorkplaceEditCtrl.$inject = ['Workplace'];

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
  };
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
function WorkplaceEditCtrl(Workplace) {
  this.Workplace = Workplace;
}

WorkplaceEditCtrl.prototype.init = function (id) {
  var self = this;

  this.Workplace.init(id).then(function () {
    // Список типов РМ
    self.wp_types = self.Workplace.wp_types;
    // Типы оборудования на РМ с необходимыми для заполнения свойствами
    self.eq_types = self.Workplace.eq_types;
    // Направления деятельности
    self.specs = self.Workplace.specs;
    // Список отделов, прикрепленных к пользователю
    self.divisions = self.Workplace.divisions;
    // Список площадок и корпусов
    self.iss_locations = self.Workplace.iss_locations;
    // Список пользователей отдела
    self.users = self.Workplace.users;

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
  for (var i=0; i< this.users.length; i++) {
    if (id_tn === this.users[i].id_tn) {
      return this.users[i].fio;
    }
  }
};

// =====================================================================================================================
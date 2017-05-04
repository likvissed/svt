app
  .controller('WorkplaceIndexCtrl', WorkplaceIndexCtrl)
  .controller('WorkplaceEditCtrl', WorkplaceEditCtrl);

WorkplaceIndexCtrl.$inject  = ['$controller', 'DTOptionsBuilder', 'DTColumnBuilder'];
WorkplaceEditCtrl.$inject   = ['Workplace'];

/**
 * Управление общей таблицей рабочих мест.
 *
 * @class SVT.WorkplaceIndexCtrl
 */
function WorkplaceIndexCtrl($controller, DTOptionsBuilder, DTColumnBuilder) {
  var self = this;

  // Подключаем основные параметры таблицы
  $controller('DefaultDataTableCtrl', {});

  // Объект, содержащий данные отделов по инвентаризации (workplace_id => data)
  self.workplaces   = {}
  self.dtInstance   = {};
  self.dtOptions    = DTOptionsBuilder
    .newOptions()
    .withOption('stateSave', true)
    .withOption('ajax', {
      url:  '/inventory/workplaces.json',
      error: function (response) {
        // Error.response(response);
      }
    })
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

  self.dtColumns      = [
    DTColumnBuilder.newColumn(null).withTitle('').withOption('className', 'col-fhd-1').renderWith(renderIndex),
    DTColumnBuilder.newColumn('division').withTitle('Отдел').withOption('className', 'col-fhd-2'),
    DTColumnBuilder.newColumn('wp_type').withTitle('Тип').withOption('className', 'col-fhd-4'),
    DTColumnBuilder.newColumn('responsible').withTitle('Ответственный').withOption('className', 'col-fhd-6'),
    DTColumnBuilder.newColumn('location').withTitle('Расположение').withOption('className', 'col-fhd-4'),
    DTColumnBuilder.newColumn('count').withTitle('Кол-во техники').withOption('className', 'col-fhd-2'),
    DTColumnBuilder.newColumn('status').withTitle('Статус').withOption('className', 'col-fhd-3'),
    DTColumnBuilder.newColumn(null).withTitle('').notSortable().withOption('className', 'col-fhd-1 text-center').renderWith(editRecord),
    DTColumnBuilder.newColumn(null).withTitle('').notSortable().withOption('className', 'col-fhd-1 text-center').renderWith(delRecord)
  ];

  function renderIndex(data, type, full, meta) {
    self.workplaces[data.workplace_id] = data;
    return meta.row + 1;
  }

  function editRecord(data, type, full, meta) {
    return '<a href="/inventory/workplaces/' + data.workplace_id + '/edit" class="default-color" disable-link=true' +
      ' uib-tooltip=Редактировать запись"><i class="fa fa-pencil-square-o fa-1g"></a>';
  }

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

  this.Workplace.init(id).then(function (workplace) {
    self.workplace = self.Workplace.workplace;
  });
};

// =====================================================================================================================
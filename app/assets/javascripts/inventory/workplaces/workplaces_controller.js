(function () {
  'use strict';

  app
    .controller('WorkplaceIndexCtrl', WorkplaceIndexCtrl);

  WorkplaceIndexCtrl.$inject = ['$controller', 'DTOptionsBuilder', 'DTColumnBuilder', 'TableSettings'];

  /**
   * Управление общей таблицей рабочих мест.
   *
   * @class Inv.WorkplaceIndexCtrl
   * @param $controller
   * @param DTOptionsBuilder
   * @param DTColumnBuilder
   * @param TableSettings
   */

  function WorkplaceIndexCtrl($controller, DTOptionsBuilder, DTColumnBuilder, TableSettings) {
    var self = this;

    var my_table = new TableSettings('workplaces');
    my_table.renderIndex();

    console.dir(my_table);

    // Подключаем основные параметры таблицы
    $controller('DefaultDataTableCtrl', {});

    self.dtInstance     = {};
    self.dtOptions = DTOptionsBuilder
      .newOptions()
      .withOption('stateSave', true)
      .withOption('initComplete', initComplete)
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
      // DTColumnBuilder.newColumn('name').withTitle('Наименование').withOption('className', 'col-fhd-6'),
      DTColumnBuilder.newColumn('wp_type').withTitle('Тип').withOption('className', 'col-fhd-4'),
      DTColumnBuilder.newColumn('responsible').withTitle('Ответственный').withOption('className', 'col-fhd-6'),
      DTColumnBuilder.newColumn('location').withTitle('Расположение').withOption('className', 'col-fhd-4'),
      DTColumnBuilder.newColumn('count').withTitle('Кол-во техники').withOption('className', 'col-fhd-2 text-center'),
      DTColumnBuilder.newColumn('status').withTitle('Статус').withOption('className', 'col-fhd-4 text-center'),
      DTColumnBuilder.newColumn(null).withTitle('').notSortable().withOption('className', 'text-center col-fhd-3').renderWith(editRecord),
      // DTColumnBuilder.newColumn(null).withTitle('').notSortable().withOption('className', 'text-center col-fhd-1').renderWith(delRecord)
    ];

    function initComplete(setting, json) {
      console.log(json);
    }

    function renderIndex(data, type, full, meta) {
      // self.services[data.id] = data;
      return meta.row + 1;
    }

    function editRecord() {
      return '<div class="btn-group" role="group">' +
          '<button class="btn btn-default btn-sm">Изменить</button>' +
          '<button class="btn btn-danger btn-sm">Удалить</button>' +
        '</div>';
    }
  }

})();
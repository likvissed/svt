app
  .controller('CountWorkplaceIndexCtrl', CountWorkplaceIndexCtrl)
  .controller('ModalCountWpController', ModalCountWpController);

CountWorkplaceIndexCtrl.$inject = ['$controller', '$scope', '$compile', '$uibModal', 'DTOptionsBuilder', 'DTColumnBuilder', 'Config', 'Server', 'Flash', 'Error', 'CountWorkplace'];
ModalCountWpController.$inject  = ['$scope', '$uibModalInstance', 'data', 'Server', 'Config', 'Flash', 'Error'];

/**
 * Управление общей таблицей информации РМ по отделам.
 *
 * class Inv.CountWorkplaceIndexCtrl
 * @param $controller
 * @param $scope
 * @param $compile
 * @param $uibModal
 * @param DTOptionsBuilder
 * @param DTColumnBuilder
 * @param Config - описание: {@link Inv.Config}
 * @param Server - описание: {@link Inv.Server}
 * @param Flash - описание: {@link Inv.Flash}
 * @param Error - описание: {@link Inv.Error}
 * @param CountWorkplace - описание: {@link Inv.CountWorkplace}
 */
function CountWorkplaceIndexCtrl($controller, $scope, $compile, $uibModal, DTOptionsBuilder, DTColumnBuilder, Config, Server, Flash, Error, CountWorkplace) {
  var self = this;

// =============================================== Инициализация =======================================================

  self.$scope         = $scope;
  self.$uibModal      = $uibModal;
  self.Config         = Config;
  self.Server         = Server;
  self.Flash          = Flash;
  self.Error          = Error;
  self.CountWorkplace = CountWorkplace;

  // Подключаем основные параметры таблицы
  $controller('DefaultDataTableCtrl', {});

  // Объекты отделов инвентаризации (count_workplace_id => data)
  self.countWp    = {};
  self.dtInstance = {};
  self.dtOptions  = DTOptionsBuilder
    .newOptions()
    .withOption('stateSave', true)
    .withOption('ajax', {
      url:  '/count_workplaces.json',
      error: function (response) {
        Error.response(response);
      }
    })
    .withOption('createdRow', createdRow)
    .withDOM(
      '<"row"' +
        '<"col-sm-4 col-md-3 col-lg-2 col-fhd-2"' +
          '<"#count_workplaces.new-record">>' +
        '<"col-sm-16 col-md-18 col-lg-19 col-fhd-19">' +
        '<"col-sm-4 col-md-3 col-lg-3 col-fhd-3"f>>' +
      '<"row"' +
        '<"col-fhd-24"t>>' +
      '<"row"' +
        '<"col-fhd-12"i>' +
        '<"col-fhd-12"p>>'
    );

  self.dtColumns      = [
    DTColumnBuilder.newColumn(null).withTitle('').withOption('className', 'col-fhd-1').renderWith(renderIndex),
    DTColumnBuilder.newColumn('division').withTitle('Отдел').withOption('className', 'col-fhd-3'),
    DTColumnBuilder.newColumn('responsible').withTitle('Ответственный').withOption('className', 'col-fhd-5'),
    DTColumnBuilder.newColumn('phone').withTitle('Телефон').withOption('className', 'col-fhd-3'),
    DTColumnBuilder.newColumn('count_wp').withTitle('Кол-во РМ').withOption('className', 'col-fhd-3 text-center'),
    DTColumnBuilder.newColumn('date-range').withTitle('Время доступа').withOption('className', 'col-fhd-4' +
      ' text-center'),
    DTColumnBuilder.newColumn('waiting').withTitle('Ожидают').withOption('className', 'text-center col-fhd-2'),
    DTColumnBuilder.newColumn('ready').withTitle('Готовность').withOption('className', 'text-center col-fhd-2'),
    DTColumnBuilder.newColumn(null).withTitle('').notSortable().withOption('className', 'text-center col-fhd-1').renderWith(editRecord),
    DTColumnBuilder.newColumn(null).withTitle('').notSortable().withOption('className', 'text-center col-fhd-1').renderWith(delRecord)
  ];

// =============================================== Приватные функции ===================================================

  /**
   * Показать номер строки.
   */
  function renderIndex(data, type, full, meta) {
    // Сохранить данные сервиса (нужны для вывода пользователю информации об удаляемом элементе)
    self.countWp[data.count_workplace_id] = data;
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
   * Отрендерить ссылку на редактирование записи.
   */
  function editRecord(data, type, full, meta) {
    return '<a href="" class="default-color" disable-link=true ng-click="countWp.openCountWpEditModal(' + data.count_workplace_id +
      ')" uib-tooltip="Редактировать запись"><i class="fa fa-pencil-square-o fa-1g"></a>';
  }

  /**
   * Отрендерить ссылку на удаление данных.
   */
  function delRecord(data, type, full, meta) {
    return '<a href="" class="text-danger" disable-link=true ng-click="countWp.destroyRecord(' + data.count_workplace_id +
      ')" uib-tooltip="Удалить запись"><i class="fa fa-trash-o fa-1g"></a>';
  }

}

/**
 * Открытия модального окна для создания/редактирования отдела.
 *
 * @param data - данные, вставляемые в форму
 */
CountWorkplaceIndexCtrl.prototype._openCountWpEditModal = function (data) {
  var self = this;

  var modalInstance = self.$uibModal.open({
    animation:    self.Config.global.modalAnimation,
    templateUrl:  'editCountWp.haml',
    controller:   'ModalCountWpController',
    controllerAs: 'modal',
    resolve: {
      data: data
    }
  });

  modalInstance.result.then(function () {
    // Обновить таблицу после того, как пользователь нажал кнопку "Готово".
    self.dtInstance.reloadData(null, self.Config.count_workplace.reloadPaging);
  }, function () {
    // Закрыли модальное окно (все остальные случаи)
    self.CountWorkplace.clearData();
  });
};

/**
 * Создать пустой шаблон данных или загрухить данные с сервера создания или редактирования отдела.
 *
 * @param id - id отдела
 */
CountWorkplaceIndexCtrl.prototype.openCountWpEditModal = function (id) {
  var self = this;

  if (id)
    self.CountWorkplace.getDivision(id).then(function (data) {
      self._openCountWpEditModal(data);
    });
  else
    self._openCountWpEditModal(self.CountWorkplace.newDivision());

};

/**
 * Удалить запись.
 *
 * @param id - id записи в объекте countWp
 */
CountWorkplaceIndexCtrl.prototype.destroyRecord = function (id) {
  var self = this;

  var confirm_str = "Вы действительно хотите удалить отдел \"" + self.countWp[id].division + "\"?";

  if (!confirm(confirm_str))
    return false;

  self.Server.CountWorkplace.delete({ count_workplace_id: id },
    // Success
    function (response) {
      self.Flash.notice(response.full_message);

      self.dtInstance.reloadData(null, self.Config.count_workplace.reloadPaging);
    },
    // Error
    function (response) {
      self.Error.response(response);
    });

};

// =====================================================================================================================

/**
 * Управление модальным окном, создающим/редактирующим записи.
 *
 * @class Inv.ModalCountWpController
 * @param $scope
 * @param $uibModalInstance
 * @param data - данные, передаваемые модальному окну
 * @param Server - описание: {@link Inv.Server}
 * @param Config - описание: {@link Inv.Config}
 * @param Flash - описание: {@link Inv.Flash}
 * @param Error - описание: {@link Inv.Error}
 */
function ModalCountWpController($scope, $uibModalInstance, data, Server, Config, Flash, Error) {
  // Установить имя формы для класса ModalCountWpController
  this.setFormName('count_workplace');

  this.$scope             = $scope;
  this.$uibModalInstance  = $uibModalInstance;
  this.Server             = Server;
  this.Flash              = Flash;
  this.Error              = Error;

  // Данные по отделу
  this.data         = data.value;
  // Метод передачи данных (POST, PATCH)
  this.method       = data.method;
  // Общие настройки календаря
  this.dateOptions  = Config.global.datePicker;
  // Настройка календаря 'time_start'
  this.time_start   = {
    // Переменная определяющая начальное состояние календаря (false - скрыть, true - показать)
    openDatePicker: false,
    // Формат времени, который видит пользователь
    format:         Config.global.datePicker.longFormat
  };
  // Настройка календаря 'time_end'
  this.time_end     = {
    // Переменная определяющая начальное состояние календаря (false - скрыть, true - показать)
    openDatePicker: false,
    // Формат времени, который видит пользователь
    format:         Config.global.datePicker.longFormat
  };
}

// Унаследовать методы класса FormValidationController
ModalCountWpController.prototype = Object.create(FormValidationController.prototype);
ModalCountWpController.prototype.constructor = ModalCountWpController;

/**
 * Сохранить данные и закрыть модальное окно.
 */
ModalCountWpController.prototype.ok = function () {
  var self = this;

  self.clearErrors();

  if (self.method == 'POST') {
    self.Server.CountWorkplace.save({ count_workplace: self.data },
      function success(response) {
        self.$uibModalInstance.close();

        self.Flash.notice(response.full_message);
      },
      function error(response) {
        self.Error.response(response);
        self.errorResponse(response);
      }
    )
  }
  else {
    self.Server.CountWorkplace.update({ count_workplace_id: self.data.count_workplace_id}, { count_workplace: self.data },
      function success(response) {
        self.$uibModalInstance.close();

        self.Flash.notice(response.full_message);
      },
      function error(response) {
        self.Error.response(response);
        self.errorResponse(response);
      }
    )
  }
};

/**
 * Закрыть модальное окно по нажатии кнопки "Закрыть".
 */
ModalCountWpController.prototype.cancel = function () {
  this.$uibModalInstance.dismiss();
};

/**
 * Показать календарь.
 *
 * @param type - тип календаря, time_start или time_end
 */
ModalCountWpController.prototype.openDatePicker = function (type) {
  this[type].openDatePicker = true;
};

// =====================================================================================================================
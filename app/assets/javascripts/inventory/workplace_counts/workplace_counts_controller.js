(function () {
  'use strict';

  app
    .controller('WorkplaceCountIndexCtrl', WorkplaceCountIndexCtrl)
    .controller('ModalWpCountController', ModalWpCountController);

  WorkplaceCountIndexCtrl.$inject = ['$controller', '$scope', '$compile', '$uibModal', 'DTOptionsBuilder', 'DTColumnBuilder', 'Config', 'Server', 'Flash', 'Error', 'WorkplaceCount'];
  ModalWpCountController.$inject = ['$uibModalInstance', 'data', 'Server', 'Config', 'Flash', 'Error', 'WorkplaceCount'];

  /**
   * Управление общей таблицей информации РМ по отделам.
   *
   * @class SVT.WorkplaceCountIndexCtrl
   */
  function WorkplaceCountIndexCtrl($controller, $scope, $compile, $uibModal, DTOptionsBuilder, DTColumnBuilder, Config, Server, Flash, Error, WorkplaceCount) {
    var self = this;

// =============================================== Инициализация =======================================================

    self.$scope = $scope;
    self.$uibModal = $uibModal;
    self.Config = Config;
    self.Server = Server;
    self.Flash = Flash;
    self.Error = Error;
    self.WorkplaceCount = WorkplaceCount;

    // Подключаем основные параметры таблицы
    $controller('DefaultDataTableCtrl', {});

    // Объект, содержащий данные о доступах пользователей к инвентаризации (workplace_count_id => data)
    self.wpCount = {};
    self.dtInstance = {};
    self.dtOptions = DTOptionsBuilder
      .newOptions()
      .withBootstrap()
      .withOption('stateSave', true)
      .withOption('ajax', {
        url: '/inventory/workplace_counts.json',
        error: function (response) {
          Error.response(response);
        }
      })
      .withOption('createdRow', createdRow)
      .withDOM(
        '<"row"' +
        '<"col-sm-4 col-md-3 col-lg-2 col-xlg-2 col-fhd-2"' +
        '<"#workplace_counts.new-record">>' +
        '<"col-sm-16 col-md-18 col-lg-19 col-xlg-19 col-fhd-19">' +
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
      DTColumnBuilder.newColumn('responsibles').withTitle('Ответственный').withOption('className', 'col-fhd-7'),
      DTColumnBuilder.newColumn('phones').withTitle('Телефон').withOption('className', 'col-fhd-2'),
      // DTColumnBuilder.newColumn('count_wp').withTitle('Кол-во РМ').withOption('className', 'col-fhd-3 text-center'),
      DTColumnBuilder.newColumn('date-range').withTitle('Время доступа').withOption('className', 'col-fhd-5' +
        ' text-center'),
      DTColumnBuilder.newColumn('status').withTitle('Статус').notSortable().withOption('className', 'col-fhd-1').renderWith(statusRecord),
      DTColumnBuilder.newColumn('waiting').withTitle('Ожидают').withOption('className', 'text-center col-fhd-2'),
      DTColumnBuilder.newColumn('ready').withTitle('Подтверждено').withOption('className', 'text-center col-fhd-2'),
      DTColumnBuilder.newColumn(null).withTitle('').notSortable().withOption('className', 'text-center col-fhd-1').renderWith(editRecord),
      DTColumnBuilder.newColumn(null).withTitle('').notSortable().withOption('className', 'text-center col-fhd-1').renderWith(delRecord)
    ];

// =============================================== Приватные функции ===================================================

    /**
     * Показать номер строки.
     */
    function renderIndex(data, type, full, meta) {
      // Сохранить данные сервиса (нужны для вывода пользователю информации об удаляемом элементе)
      self.wpCount[data.workplace_count_id] = data;
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
      if (data == 'allow')
        return '<span class="label label-success">Доступ открыт</span>';
      else
        return '<span class="label label-warning">Доступ закрыт</span>';
    }

    /**
     * Отрендерить ссылку на редактирование записи.
     */
    function editRecord(data, type, full, meta) {
      return '<a href="" class="default-color" disable-link=true ng-click="wpCount.openWpCountEditModal(' +
        data.workplace_count_id + ')" uib-tooltip="Редактировать запись"><i class="fa fa-pencil-square-o fa-1g"></a>';
    }

    /**
     * Отрендерить ссылку на удаление данных.
     */
    function delRecord(data, type, full, meta) {
      return '<a href="" class="text-danger" disable-link=true ng-click="wpCount.destroyRecord(' +
        data.workplace_count_id + ')" uib-tooltip="Удалить запись"><i class="fa fa-trash-o fa-1g"></a>';
    }

  }

  /**
   * Открытия модального окна для создания/редактирования отдела.
   *
   * @param data - данные, вставляемые в форму
   */
  WorkplaceCountIndexCtrl.prototype._openWpCountEditModal = function (data) {
    var self = this;

    var modalInstance = self.$uibModal.open({
      animation: self.Config.global.modalAnimation,
      backdrop: 'static',
      templateUrl: 'editWpCount.haml',
      controller: 'ModalWpCountController',
      controllerAs: 'modal',
      resolve: {
        data: data
      }
    });

    modalInstance.result.then(function () {
      // Обновить таблицу после того, как пользователь нажал кнопку "Готово".
      self.dtInstance.reloadData(null, self.Config.workplace_count.reloadPaging);
    }, function () {
      // Закрыли модальное окно (все остальные случаи)
      self.WorkplaceCount.clearData();
    });
  };

  /**
   * Создать пустой шаблон данных или загрухить данные с сервера создания или редактирования отдела.
   *
   * @param id - id отдела
   */
  WorkplaceCountIndexCtrl.prototype.openWpCountEditModal = function (id) {
    var self = this;

    if (id) {
      self.WorkplaceCount.getDivision(id).then(function (data) {
        self._openWpCountEditModal(data);
      });
    } else {
      self._openWpCountEditModal(self.WorkplaceCount.newDivision());
    }

  };

  /**
   * Удалить запись.
   *
   * @param id - id записи в объекте wpCount
   */
  WorkplaceCountIndexCtrl.prototype.destroyRecord = function (id) {
    var self = this;

    var confirm_str = "Вы действительно хотите удалить отдел \"" + self.wpCount[id].division + "\"?";

    if (!confirm(confirm_str))
      return false;

    self.Server.WorkplaceCount.delete({ workplace_count_id: id },
      // Success
      function (response) {
        self.Flash.notice(response.full_message);

        self.dtInstance.reloadData(null, self.Config.global.reloadPaging);
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
   * @class SVT.ModalWpCountController
   */
  function ModalWpCountController($uibModalInstance, data, Server, Config, Flash, Error, WorkplaceCount) {
    // Установить имя формы для класса ModalWpCountController
    this.setFormName('workplace_count');

    this.$uibModalInstance = $uibModalInstance;
    this.Server = Server;
    this.Flash = Flash;
    this.Error = Error;
    this.WorkplaceCount = WorkplaceCount;

    // Данные по отделу
    this.data = data.value;
    // Метод передачи данных (POST, PUT)
    this.method = data.method;
    // Общие настройки календаря
    this.dateOptions = Config.global.datePicker;
    // Настройка календаря 'time_start'
    this.time_start = {
      // Переменная определяющая начальное состояние календаря (false - скрыть, true - показать)
      openDatePicker: false,
      // Формат времени, который видит пользователь
      format: Config.global.datePicker.longFormat
    };
    // Настройка календаря 'time_end'
    this.time_end = {
      // Переменная определяющая начальное состояние календаря (false - скрыть, true - показать)
      openDatePicker: false,
      // Формат времени, который видит пользователь
      format: Config.global.datePicker.longFormat
    };
  }

// Унаследовать методы класса FormValidationController
  ModalWpCountController.prototype = Object.create(FormValidationController.prototype);
  ModalWpCountController.prototype.constructor = ModalWpCountController;

  /**
   * Добавить ответсвенного.
   */
  ModalWpCountController.prototype.addResponsible = function () {
    this.WorkplaceCount.addResponsible();
  };

  /**
   * Удалить ответственного.
   *
   * @param obj - удаляемый объект
   */
  ModalWpCountController.prototype.delResponsible = function (obj) {
    this.WorkplaceCount.delResponsible(obj);
  };

  /**
   * Сохранить данные и закрыть модальное окно.
   */
  ModalWpCountController.prototype.ok = function () {
    var self = this;

    self.clearErrors();

    if (self.method == 'POST') {
      self.Server.WorkplaceCount.save({ workplace_count: self.data },
        function success(response) {
          self.$uibModalInstance.close();

          self.Flash.notice(response.full_message);
        },
        function error(response) {
          self.Error.response(response);
          self.errorResponse(response);
        }
      )
    } else {
      self.Server.WorkplaceCount.update(
        { workplace_count_id: self.data.workplace_count_id },
        { workplace_count: self.data },
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
  ModalWpCountController.prototype.cancel = function () {
    this.$uibModalInstance.dismiss();
  };

  /**
   * Показать календарь.
   *
   * @param type - тип календаря, time_start или time_end
   */
  ModalWpCountController.prototype.openDatePicker = function (type) {
    this[type].openDatePicker = true;
  };
})();

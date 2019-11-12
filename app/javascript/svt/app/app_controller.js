import { app } from './app';

(function() {
  'use strict';

  app.controller('DefaultDataTableCtrl', DefaultDataTableCtrl);

  DefaultDataTableCtrl.$inject = ['DTDefaultOptions'];

  /**
   * Основные настройки таблиц angular-datatable.
   *
   * @class SVT.DefaultDataTableCtrl
   */
  function DefaultDataTableCtrl(DTDefaultOptions) {
    DTDefaultOptions
      .setLanguage({
        emptyTable: 'Данные отсутствуют',

        // Нумерация страниц
        paginate: {
          first   : 'Перв.',
          last    : 'Посл.',
          previous: 'Пред.',
          next    : 'След.'
        },
        search           : '',
        searchPlaceholder: 'Поиск',
        zeroRecords      : 'Данные отсутсвуют',
        lengthMenu       : 'Показано _MENU_ записей',
        processing       : 'Выполнение...',
        loadingRecords   : 'Загрузка данных с сервера...',
        info             : 'Записи с _START_ по _END_ из _TOTAL_',
        infoFiltered     : '(выборка из _MAX_ записей)',
        infoEmpty        : '0 записей'
      })
      .setDisplayLength(25)
      .setDOM('<"row"<"col-fhd-24"f>>t<"row"<"col-fhd-24"p>>');
  }
})();

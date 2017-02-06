(function() {
  app
    .controller('DefaultDataTableCtrl', DefaultDataTableCtrl);   // Основные настройки таблицы angular-datatable

  DefaultDataTableCtrl.$inject = ['DTDefaultOptions'];

  /**
   * Контроллер, содержащий основные настройки таблиц angular-datatable.
   *
   * @class Inv.DefaultDataTableCtrl
   * @param DTDefaultOptions
   */
  function DefaultDataTableCtrl(DTDefaultOptions) {
    DTDefaultOptions
      .setLanguage({
        emptyTable: 'Данные отсутствуют',
        paginate: { //Нумерация страниц
          first:    'Перв.',
          last:     'Посл.',
          previous: 'Пред.',
          next:     'След.'
        },
        search:             '',
        searchPlaceholder:  'Поиск',
        zeroRecords:        'Данные отсутсвуют',
        lengthMenu:         'Показано _MENU_ записей',
        processing:         'Выполнение...',
        loadingRecords:     'Загрузка данных с сервера...',
        info:               'Записи с _START_ по _END_ из _TOTAL_',
        infoFiltered:       '(выборка из _MAX_ записей)',
        infoEmpty:          '0 записей'
      })
      .setDisplayLength(25)
      .setDOM('<"row"<"col-fhd-24"f>>t<"row"<"col-fhd-24"p>>');
  }
})();
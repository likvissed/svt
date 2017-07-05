(function () {
  'use strict';

  /**
   * Конфигурационные данные.
   */
  var config = {
    // Глобальные настройки
    global: {
      // Анимация модальных окон
      modalAnimation: true,
      //Настройка для библиотеки DatePicker
      datePicker: {
        // Минимальная дата, возможная для установки
        minDate: new Date(),
        // Показывать/скрывать номер недели в году
        showWeeks:  false,
        // Локализация
        locale: 'ru',
        // Форматы даты. Пример: 17-февраля-2017
        longFormat: 'dd-MMMM-yyyy'
      },
      // При обновлении таблицы DataTables не сбрасывать нумерацию страниц.
      reloadPaging: false
    }
  };

  app
    .constant('Config', config);
})();
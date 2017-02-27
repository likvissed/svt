(function () {
  'use strict';

  /**
   * Конфигурационные данные
   *
   * @class Inv.Config
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
      }
    },
    workplace_count: {
      reloadPaging: false
    }
  };

  app
    .constant('Config', config);
})();
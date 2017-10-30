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
      // При обновлении таблицы DataTables не сбрасывать нумерацию страниц.
      reloadPaging: false,
      uibDatepickerConfig: {
        // Показывать/скрывать номер недели в году
        showWeeks: false
      },
      uibDatepickerPopupConfig: {
        // Форматы даты. Пример: 17-февраля-2017
        uibDatepickerPopup: 'dd-MMMM-yyyy'
      }
    }
  };

  app
    .constant('Config', config);
})();
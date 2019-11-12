import { app } from './app';

(function () {
  'use strict';

  /**
   * Конфигурационные данные.
   */
  let config = {
    // Глобальные настройки
    global: {
      // Анимация модальных окон
      modalAnimation     : true,
      // При обновлении таблицы DataTables не сбрасывать нумерацию страниц.
      reloadPaging       : false,
      uibPaginationConfig: {
        nextText           : 'След.',
        previousText       : 'Пред.',
        rotate             : true,
        boundaryLinkNumbers: true,
        itemsPerPage       : 25
      },
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

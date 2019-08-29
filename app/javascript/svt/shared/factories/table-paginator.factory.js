import { app } from '../../app/app';

(function() {
  app.factory('TablePaginator', TablePaginator);

  TablePaginator.$inject = ['Config'];

  /**
   * Фабрика для работы с нумерацией страниц на таблицах
   */
  function TablePaginator(Config) {
    let _pagination = {
      filteredRecords: 0,
      totalRecords   : 0,
      currentPage    : 1,
      maxSize        : 5
    };

    return {
      /**
       * Получить конфиг пагинатора
       */
      config: function() {
        return _pagination;
      },
      /**
       * Получить индекс записи, с которой необходимо показать данные.
       */
      startNum: function() {
        return (_pagination.currentPage - 1) * Config.global.uibPaginationConfig.itemsPerPage;
      },
      /**
       * Установить данные пагинатора
       *
       * @param data { recordsFiltered: int, recordsTotal: int }
       */
      setData: function(data) {
        _pagination.filteredRecords = data.recordsFiltered;
        _pagination.totalRecords = data.recordsTotal;
      }
    }
  }
})();

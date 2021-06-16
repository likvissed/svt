import { app } from '../../app/app';

(function() {
  'use strict';

  app.controller('StatisticsCtrl', StatisticsCtrl);

  StatisticsCtrl.$inject = ['$uibModal', '$uibModalInstance', 'Statistics'];

  function StatisticsCtrl($uibModal, $uibModalInstance, Statistics) {
    this.$uibModal = $uibModal;
    this.$uibModalInstance = $uibModalInstance;
    this.Statistics = Statistics;

    this.data = this.Statistics.data;
  }

  /**
   * Обновить статистику.
   */
  StatisticsCtrl.prototype.reloadData = function() {
    this.Statistics.get('ups_battery')
      .then(() => {
        this.data = this.Statistics.data;
      }
    )
  };

  /**
   * Закрыть модальное окно.
   */
  StatisticsCtrl.prototype.close = function() {
    this.$uibModalInstance.dismiss();
  };

  /**
   * Экспортировать таблицу статистики в файл csv
   */
  StatisticsCtrl.prototype.exportData = function(stat_data) {
    window.open(`/statistics/export/?format=csv&data=${JSON.stringify(stat_data)}`, '_blank');
  };
})();



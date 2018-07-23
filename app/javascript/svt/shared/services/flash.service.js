import { app } from '../../app/app';

(function() {
  app.service('Flash', Flash);

  Flash.$inject = ['$timeout'];

  /**
   * Сервис уведомления пользователей как об успешных операциях, так и об ошибочных.
   *
   * @class SVT.Flash
   */
  function Flash($timeout) {
    this.$timeout = $timeout;

    this.flash = {
      notice: '',
      alert:  ''
    };
  }

  /**
   * Показать notice уведомление и скрыть его через 2 секунды.
   *
   * @param message - сообщение, которое необходимо вывести.
   */
  Flash.prototype.notice = function(message) {
    this.flash.alert = null;
    this.flash.notice = message;

    this.$timeout(() => this.flash.notice = null, 2000);
  };

  /**
   * Показать alert уведомление.
   *
   * @param message - сообщение, которое необходимо вывести.
   */
  Flash.prototype.alert = function(message) {
    this.flash.notice = null;
    this.flash.alert = message;
  };
})();
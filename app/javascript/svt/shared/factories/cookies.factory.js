import { app } from '../../app/app';

(function() {
  app.factory('Cookies', Cookies);

  Cookies.$inject = ['$cookies'];

  /**
   * Сервис для работы с cookies.
   *
   * @class SVT.Cookies
   */
  function Cookies($cookies) {
    let obj;

    /**
     * Инициализация cookies указанного объекта.
     *
     * @param name
     */
    function init(name) {
      switch (name) {
        case 'workplace':
          obj = {
            // Фильтр по отделам
            tableDivisionFilter: '0',
            // Фильтр по статусам
            tableStatusFilter: 'all',
            // Фильтр по типам
            tableTypeFilter: '0',
            // Фильтр списка РМ по отделам
            tableListDivisionFilter: '0',
            // Флаг, определяющий, как показывать РМ: в виде списка или таблицы
            tableListTypeFilter: false
          };
          break;
      }

      if (angular.isUndefined($cookies.getObject(name))) {
        // Установить начальные значения переменных куки
        $cookies.putObject(name, obj);
      } else {
        // Проверяем, существуют ли в cookies все ключи объекта obj
        angular.forEach(obj, function(value, key) {
          if (angular.isUndefined($cookies.getObject(name)[key])) {
            setCookie(name, key, value);
          }
        });

        // Получить актуальные значения переменных куки
        obj = $cookies.getObject(name);
      }
    }

    /**
     * Получить объект cookies с указанным именем name.
     *
     * @param name - имя объекта
     * @param key - имя свойства объекта
     */
    function getCookie(name, key) {
      if (angular.isUndefined(key)) {
        return $cookies.getObject(name);
      }

      return angular.isUndefined($cookies.getObject(name)) ? 'Cookies отсутсвуют' : $cookies.getObject(name)[key];
    }

    /**
     * Установить объект cookies с указанным именем name.
     *
     * @param name - имя объекта
     * @param key - имя свойства объекта
     * @param value - устанавливаемое значение
     */
    function setCookie(name, key, value) {
      obj[key] = value;

      if (name == 'workplace') {
        $cookies.remove('workplace', { path: '/' });
        $cookies.remove('workplace', { path: '/invent' });
        $cookies.remove('workplace', { path: '/invent/workplaces' });
      }

      $cookies.putObject(name, obj);
    }

    return {
      /**
       * Страница /workplaces.
       */
      Workplace: {
        init: function() {
          init('workplace');
        },
        get: function(key) {
          return getCookie('workplace', key);
        },
        set: function(key, value) {
          setCookie('workplace', key, value);
        }
      }
    }
  }
})();
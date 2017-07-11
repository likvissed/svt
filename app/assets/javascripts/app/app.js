/**
 * @namespace SVT
 */
var app = angular
  .module('SVT', [
    'ngResource',
    'ngAnimate',
    'datatables',
    'datatables.bootstrap',
    'ui.bootstrap',
    'ngActionCable',
    'ngSanitize',
    'ui.select',
    'ngCookies'
  ]);  


app
  // Настройка ресурсов
  .config(['$resourceProvider', '$httpProvider', function($resourceProvider, $httpProvider) {
    // Don't strip trailing slashes from calculated URLs
    $resourceProvider.defaults.stripTrailingSlashes = false;
    // Настройка для отслеживания AJAX запросов (нужно для индикатора загрузки)
    $httpProvider.interceptors.push('myHttpInterceptor');
  }]);

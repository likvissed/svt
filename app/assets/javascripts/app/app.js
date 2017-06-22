/**
 * @namespace SVT
 */
var app = angular
  .module('SVT', [
    'ngResource',
    'ngAnimate',
    'datatables',
    'datatables.bootstrap',
    'ui.bootstrap'
  ]);  


app
  // Настройка ресурсов
  .config(['$resourceProvider', function($resourceProvider) {
    // Don't strip trailing slashes from calculated URLs
    $resourceProvider.defaults.stripTrailingSlashes = false;
  }]);

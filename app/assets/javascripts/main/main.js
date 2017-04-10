/**
 * @namespace Inv
 */
var app = angular
  .module('Inv', [
    'ngResource',
    'ngAnimate',
    'datatables',
    'ui.bootstrap'
  ]);

app
  // Настройка ресурсов
  .config(['$resourceProvider', function($resourceProvider) {
    // Don't strip trailing slashes from calculated URLs
    $resourceProvider.defaults.stripTrailingSlashes = false;
  }]);

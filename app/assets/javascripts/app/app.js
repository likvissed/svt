// /**
//  * @namespace SVT
//  */
// var app = angular
//   .module('SVT', [
//     'ngResource',
//     'ngAnimate',
//     'datatables',
//     'datatables.bootstrap',
//     'ui.bootstrap',
//     'ngActionCable',
//     'ngSanitize',
//     'ui.select',
//     'ngCookies',
//     'ngFileUpload'
//   ]);

// app
//   // Настройка ресурсов
//   .config(['$resourceProvider', '$httpProvider', function($resourceProvider, $httpProvider) {
//     // Don't strip trailing slashes from calculated URLs
//     $resourceProvider.defaults.stripTrailingSlashes = false;
//     // Настройка для отслеживания AJAX запросов (нужно для индикатора загрузки)
//     $httpProvider.interceptors.push('myHttpInterceptor');
//   }])
//   .config(['uibPaginationConfig', 'Config', function(uibPaginationConfig, Config) {
//     uibPaginationConfig.nextText = Config.global.uibPaginationConfig.nextText;
//     uibPaginationConfig.previousText = Config.global.uibPaginationConfig.previousText;
//     uibPaginationConfig.rotate = Config.global.uibPaginationConfig.rotate;
//     uibPaginationConfig.boundaryLinkNumbers = Config.global.uibPaginationConfig.boundaryLinkNumbers;
//     uibPaginationConfig.itemsPerPage = Config.global.uibPaginationConfig.itemsPerPage;
//   }])
//   .config(['uibDatepickerConfig', 'Config', function(uibDatepickerConfig, Config) {
//     uibDatepickerConfig.showWeeks = Config.global.uibDatepickerPopupConfig.showWeeks;
//   }])
//   .config(['uibDatepickerPopupConfig', 'Config', function(uibDatepickerPopupConfig, Config) {
//     uibDatepickerPopupConfig.uibDatepickerPopup = Config.global.uibDatepickerPopupConfig.uibDatepickerPopup;
//   }]);

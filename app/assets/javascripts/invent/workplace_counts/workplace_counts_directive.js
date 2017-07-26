(function () {
  'use strict';

  app
    .directive('createWorkplaceCountList', createWorkplaceCountList);

  function createWorkplaceCountList() {
    return {
      restrict: 'C',
      template: '<button type="file" class="btn btn-default btn-block btn-sm" ngf-select="uploadFile($file)" accept=".csv">Загрузить из файла</button>'
    }
  }
})();
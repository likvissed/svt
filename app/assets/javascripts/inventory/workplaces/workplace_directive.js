app
  .directive('fileUpload', fileUpload);

fileUpload.$inject = [];

function fileUpload(){
  return {
    link: function (scope, element, attrs) {
      element.on('change', function (event) {
        // Сохраняется сам файл, а также имя файла в массив данных
        scope.manually.setPcFile(event.target.files[0]);
      });
    }
  };
}

import { app } from '../../app/app';

(function() {
  'use strict';

  app.controller('WorkplaceEditCtrl', WorkplaceEditCtrl);

  WorkplaceEditCtrl.$inject = ['$timeout', '$uibModal', 'Workplace', 'WorkplaceItem', 'InventItem', 'Flash', 'Config', '$window'];

  /**
   * Редактирование данных о РМ. Подтверждение/отклонение введенных данных.
   *
   * @class SVT.WorkplaceEditCtrl
   */
  function WorkplaceEditCtrl($timeout, $uibModal, Workplace, WorkplaceItem, InventItem, Flash, Config, $window) {
    this.$timeout = $timeout;
    this.$uibModal = $uibModal;
    this.Flash = Flash;
    this.Config = Config;
    this.Workplace = Workplace;
    this.WorkplaceItem = WorkplaceItem;
    this.InventItem = InventItem;
    this.$window = $window;

    // Новые вложенные файлы рабочего места
    this.Workplace.formDataResult = new FormData();
  }

  WorkplaceEditCtrl.prototype.init = function(id) {
    this.additional = this.WorkplaceItem.getAdditional();

    this.Workplace.init(id).then(() => {
      // Список типов РМ
      this.wp_types = this.Workplace.wp_types;
      // Типы оборудования на РМ с необходимыми для заполнения свойствами
      this.eq_types = this.WorkplaceItem.getTypes();
      // Направления деятельности
      this.specs = this.Workplace.specs;
      // Список отделов, прикрепленных к пользователю
      this.divisions = this.Workplace.divisions;
      // Список площадок и корпусов
      this.iss_locations = this.Workplace.iss_locations;
      // Список пользователей отдела
      this.users = this.Workplace.users;
      // Список возможных статусов РМ
      this.statuses = this.Workplace.statuses;
      // Категории секретности комнат
      this.rooms_security_categories = this.Workplace.rooms_security_categories;
      // Сообщение в справке для защищаемых помещений
      this.message_for_security_category = this.Workplace.message_for_security_category;

      // Данные о рабочем месте
      this.workplace = this.Workplace.workplace;

      this.selectItem(this.workplace.items_attributes[this.additional.activeTab]);

      if (!id) { this.loadUsers(); }
    });
  };

  /**
   * Загрузить список работников отдела.
   */
  WorkplaceEditCtrl.prototype.loadUsers = function() {
    this.workplace.id_tn = null;
    this.Workplace.loadUsers().then(() => this.users = this.Workplace.users);
  };

  /**
   * Функция для исправления бага в компоненте typeahead ui.bootstrap. Она возвращает ФИО выбранного пользователя вместо
   * табельного номера.
   *
   * @param id_tn - id_tn выбранного ответственного.
   */
  WorkplaceEditCtrl.prototype.formatLabel = function(id_tn) {
    if (!this.users) { return ''; }

    for (let i = 0; i < this.users.length; i++) {
      if (id_tn === this.users[i].id) {
        return this.users[i].fullName;
      }
    }
  };

  /**
   * Установить workplace_type_id рабочего места.
   */
  WorkplaceEditCtrl.prototype.setWorkplaceType = function() {
    this.workplace.workplace_type_id = angular.copy(this.workplace.workplace_type.workplace_type_id);
  };

  /**
   * Установить location_site_id рабочего места.
   */
  WorkplaceEditCtrl.prototype.setLocationSite = function() {
    this.workplace.location_obj.site = this.iss_locations.find((el) => {
      return this.workplace.location_site_id == el.site_id;
    })
  };

  /**
   * Установить значение для location_room_id
   */
  WorkplaceEditCtrl.prototype.setLocationRoom = function() {
    this.workplace.location_room_id = this.workplace.location_obj.room.room_id;

    this.Workplace.findNameCategory();
  };

  /**
   * Установить начальное значение для корпуса при изменении площадки.
   */
  WorkplaceEditCtrl.prototype.setDefaultLocation = function(type) {
    this.Workplace.setDefaultLocation(type);
  };

  /**
   * Отправить данные на сервер для сохранения.
   */
  WorkplaceEditCtrl.prototype.saveWorkplace = function() {
    this.Workplace.saveWorkplace();
  };

  /**
   * Изменить значение секретности комнаты
   */
  WorkplaceEditCtrl.prototype.changeSecurityCategory = function() {
    this.Workplace.changeSecurityCategory();
  };

  /**
   * Выбрать технику для редактирования.
   */
  WorkplaceEditCtrl.prototype.selectItem = function(item) {
    this.InventItem.setItem(item);
  };

  /**
   * Запустить диалоговое окно "Выбор типа устройства".
   */
  WorkplaceEditCtrl.prototype.showSelectItemType = function() {
    let modalInstance = this.$uibModal.open({

      animation   : this.Config.global.modalAnimation,
      templateUrl : 'newItem.slim',
      controller  : 'SelectItemTypeCtrl',
      controllerAs: 'select',
      size        : 'md',
      backdrop    : 'static',

      resolve: {
        data: () => {
          return { eq_types: this.eq_types };
        }
      }
    });

    modalInstance.result.then(
      (result) => {
        if (result.item_id) {
          // Для б/у оборудования с другого РМ
          this.Workplace.addExistingItem(result);
        } else {
          // Для нового оборудования
          this.Workplace.createItem(result);
        }
      },
      () => this.Workplace.setFirstActiveTab()
    );
  };

  /**
   * Удалить выбранное оборудование из состава РМ.
   *
   * @param item - удаляемый элемент.
   * @param $event - объект события.
   */
  WorkplaceEditCtrl.prototype.delItem = function(item, $event) {
    $event.stopPropagation();
    $event.preventDefault();

    this.Workplace.delItem(item);
  };

  /**
   * Удалить технику из БД.
   *
   * @param item
   */
  WorkplaceEditCtrl.prototype.destroyItem = function(item) {
    let confirm_str = `ВНИМАНИЕ! Техника будет удалена без возможности восстановления! Вы действительно хотите удалить  "${item.type.short_description}"?`;

    if (!confirm(confirm_str)) { return false; }

    this.WorkplaceItem.destroyItem(item).then(() => this.Workplace.delItem(item));
  };

  /**
   * Удалить РМ.
   *
   * @param id
   */
  WorkplaceEditCtrl.prototype.destroyWp = function() {
    let confirm_str = 'ВНИМАНИЕ! Вместе с рабочим местом будет удалена вся входящая в него техника! Вы действительно хотите удалить рабочее место?';

    if (!confirm(confirm_str)) { return false; }

    this.Workplace.destroyWorkplace();
  };

  /**
   * Открыть модальное окно назначения расположения перед отправлением на склад или на списание
   *
   * @param item
   */
  WorkplaceEditCtrl.prototype.openAssignLocation = function(item, type) {
    this.$uibModal.open({
      templateUrl : 'WorkplaceAssignLocationItemCtrl.slim',
      controller  : 'WorkplaceAssignLocationItemCtrl',
      controllerAs: 'edit',
      backdrop    : 'static',
      size        : 'md',
      resolve     : {
        items: function() {
          return {
            item: item,
            type: type
          };
        }
      }
    });
  };

  /**
   * Добавить загруженный файл на рабочее место
   */
  WorkplaceEditCtrl.prototype.addFile = function(file) {
    // Если файл не был выбран в окне загрузки
    if (!file) {
      this.Flash.alert('Загрузка файла не удалась. Попробуйте снова');

      return false;
    }
    // Перевести размер загруженного файла из байт в Мб
    let file_size = file.size / 1024 / 1024;
    if (file_size > 100) {
      this.Flash.alert('Невозможно загрузить файл, размером больше 100 мегабайт');

      return false;
    }

    let new_attachment = angular.copy(this.workplace.new_attachment);
    new_attachment.filename = file.name;
    // Добавить поле form_index для получения индекса при удалении вложения
    new_attachment.form_index = this.Workplace.formDataResult.getAll('attachments[]').length;

    // Добавить файл в массив вложенных файлов рабочего места
    this.Workplace.formDataResult.append(
      'attachments[]',
      file,
      file.name
    );
    this.workplace.attachments_attributes.push(new_attachment);
  };

  /**
   * Скачать файл, прикрепленный к рабочему месту
   */
  WorkplaceEditCtrl.prototype.downloadFile = function(attachment_id) {
    this.$window.open(`/invent/attachments/download/${attachment_id}`, '_blank');
  };

  /**
   * Удалить файл с рабочего места
   */
  WorkplaceEditCtrl.prototype.deleteFile = function(attachment) {
    if (attachment.id) {
      attachment._destroy = 1;
    } else {
      let index = this.workplace.attachments_attributes.indexOf(attachment);
      this.workplace.attachments_attributes.splice(index, 1);

      let name = 'attachments[]';

      // Получить все значения для новых вложений
      let keep_form_data = this.Workplace.formDataResult.getAll(name);

      keep_form_data.splice(attachment.form_index, 1);
      this.Workplace.formDataResult.delete(name);
      // Заполнить массив вложенных файлов
      keep_form_data.forEach((value) => this.Workplace.formDataResult.append(name, value));

      // Массив всех новых вложенных атрибутов
      let array_new_attachments_attributes = this.workplace.attachments_attributes.filter(function(attr){
        return attr.id === null;
      })
      // Обновить form_index для новых вложенных атрибутов
      array_new_attachments_attributes.forEach((value, index) => {
        if (!attachment.id) {
          value.form_index = index;
        }
      });
    }
  };
})();

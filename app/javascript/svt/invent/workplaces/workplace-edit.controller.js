import { app } from '../../app/app';

(function() {
  'use strict';

  app.controller('WorkplaceEditCtrl', WorkplaceEditCtrl);

  WorkplaceEditCtrl.$inject = ['$timeout', '$uibModal', 'Workplace', 'WorkplaceItem', 'InventItem', 'Flash', 'Config'];

    /**
   * Редактирование данных о РМ. Подтверждение/отклонение введенных данных.
   *
   * @class SVT.WorkplaceEditCtrl
   */
  function WorkplaceEditCtrl($timeout, $uibModal, Workplace, WorkplaceItem, InventItem, Flash, Config) {
    this.$timeout = $timeout;
    this.$uibModal = $uibModal;
    this.Flash = Flash;
    this.Config = Config;
    this.Workplace = Workplace;
    this.WorkplaceItem = WorkplaceItem;
    this.InventItem = InventItem;
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

    for (let i = 0; i < this.users.length; i ++) {
      if (id_tn === this.users[i].id_tn) {
        return this.users[i].fio;
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
    this.workplace.location_site_id = angular.copy(this.workplace.location_site.site_id);
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
      animation: this.Config.global.modalAnimation,
      templateUrl: 'newItem.slim',
      controller: 'SelectItemTypeCtrl',
      controllerAs: 'select',
      size: 'md',
      backdrop: 'static',
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
    let confirm_str = "ВНИМАНИЕ! Техника будет удалена без возможности восстановления! Вы действительно хотите удалить " + item.type.short_description + "?";

    if (!confirm(confirm_str)) { return false; }

    this.WorkplaceItem.destroyItem(item).then(() => this.Workplace.delItem(item));
  };

  /**
   * Удалить РМ.
   *
   * @param id
   */
  WorkplaceEditCtrl.prototype.destroyWp = function() {
    let confirm_str = "ВНИМАНИЕ! Вместе с рабочим местом будет удалена вся входящая в него техника! Вы действительно хотите удалить рабочее место?";

    if (!confirm(confirm_str)) { return false; }

    this.Workplace.destroyWorkplace();
  };

  /**
   * Отправить технику на склад
   *
   * @param item
   */
  WorkplaceEditCtrl.prototype.sendItemToStock = function(item) {
    let confirm_str = "ВНИМАНИЕ! Техника будет перемещена на склад! Вы действительно хотите переместить на склад " + item.type.short_description + "?";

    if (!confirm(confirm_str)) { return false; }

    this.InventItem.sendToStock().then(() => this.Workplace.delItem(item));
  };

  /**
   * Пометить технику на списание.
   *
   * @param item
   */
  WorkplaceEditCtrl.prototype.sendItemToWriteOff = function(item) {
    let confirm_str = "ВНИМАНИЕ! Техника будет перемещена на склад и помечена на списание! Вы действительно хотите переместить на склад " + item.type.short_description + " и создать ордер на списание?";

    if (!confirm(confirm_str)) { return false; }

    this.InventItem.sendToWriteOff().then(() => this.Workplace.delItem(item));
  };
})();

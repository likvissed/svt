import { app } from '../../app/app';

(function() {
  'use strict';

  app
    .service('InventItem', InventItem);

  InventItem.$inject = ['Server', 'Flash', 'Error', 'WorkplaceItem'];

  function InventItem(Server, Flash, Error, WorkplaceItem) {
    this.Server = Server;
    this.Flash = Flash;
    this.Error = Error;
    this.WorkplaceItem = WorkplaceItem;

    this.additional = WorkplaceItem.getAdditional();
    this.data = {};
  }

  // /**
  //  * Загрузить доступную Б/У технику указанного типа.
  //  *
  //  * @param type_id - тип загружаемой техники
  //  */
  // InventItem.prototype.loadAvaliableItems = function(type_id) {
  //   return this.Server.Invent.Item.avaliable(
  //     { type_id: type_id },
  //     function(response) {},
  //     (response, status) => this.Error.response(response, status)
  //   ).$promise;
  // };

  /**
   * Создать объект для отправки на сервер
   */
  InventItem.prototype._getObjectToSend = function() {
    let obj = angular.copy(this.data.item);
    this.WorkplaceItem.delProperties(obj);
    return obj;
  };

  /**
   * Получить технику
   */
  InventItem.prototype.edit = function(id) {
    return this.Server.Invent.Item.edit(
      { item_id: id, with_init_props: true },
      (data) => {
        this.data.item = data.item;

        this.WorkplaceItem.setTypes(data.prop_data.eq_types);
        this.WorkplaceItem.setPriorities(data.prop_data.priorities);
        this.WorkplaceItem.setAdditional('pcAttrs', data.prop_data.file_depending);
        this.WorkplaceItem.setAdditional('singleItems', data.prop_data.single_pc_items);
        this.WorkplaceItem.setAdditional('pcTypes', data.prop_data.type_with_files);
        this.WorkplaceItem.setAdditional('secretExceptions', data.prop_data.secret_exceptions);
        this.WorkplaceItem.addProperties(this.data.item);
      },
      (response, status) => this.Error.response(response, status)
    ).$promise;
  };

  /**
   * Установить объект техники.
   */
  InventItem.prototype.setItem = function(item) {
    this.data.item = item;
  };

  /**
   * Получить данные от системы Аудит по инвентарному номеру.
   */
  InventItem.prototype.getAuditData = function() {
    this.Server.Invent.Item.pcConfigFromAudit(
      { invent_num: this.data.item.invent_num },
      (data) => this.WorkplaceItem.setPcProperties(this.data.item, data),
      (response, status) => this.Error.response(response, status)
    );
  };

  /**
   * Отправить файл на сервер для расшифровки. Возвращает расшифрованные данные в виде строки.
   *
   * @param file - загружаемый файл
   */
  InventItem.prototype.matchUploadFile = function(file) {
    let formData = new FormData();

    formData.append('pc_file', file);

    return this.Server.Invent.Item.pcConfigFromUser(
      formData,
      (response) => {},
      (response, status) => this.Error.response(response, status)
    ).$promise;
  };

  /**
   * Обновить данные выбранной техники
   */
  InventItem.prototype.update = function() {
    return this.Server.Invent.Item.update(
      { item_id: this.data.item.id },
      { item: this._getObjectToSend() },
      (response) => {
        this.Flash.notice(response.full_message);
        this.item = null;
      },
      (response, status) => {
        this.Error.response(response, status);
        this.errorResponse(response);
      }
    ).$promise;
  };

  /**
   * Заполнить конфигурацию ПК дефолтными данными.
   */
  InventItem.prototype.FillPcWithDefaultData = function() {
    let result = this.additional.pcAttrs.reduce((res, el) => {
      res[el] = ['NO_DATA_MANUAL_INPUT'];
      return res;
    }, {});

    this.WorkplaceItem.setPcProperties(this.data.item, result);
  };
})();

import { app } from '../../app/app';
import { FormValidationController } from '../../shared/functions/form-validation';

(function() {
  'use strict';

  app
    .controller('ModelsCtrl', ModelsCtrl)
    .controller('EditModelCtrl', EditModelCtrl);

  ModelsCtrl.$inject = ['$uibModal', '$rootScope', 'Model', 'ActionCableChannel', 'TablePaginator', 'Server', 'Config', 'Flash', 'Error'];
  EditModelCtrl.$inject = ['$uibModalInstance', 'Model', 'Vendors', 'Server', 'Flash', 'Error'];

  function ModelsCtrl($uibModal, $rootScope, Model, ActionCableChannel, TablePaginator, Server, Config, Flash, Error) {
    this.$uibModal = $uibModal;
    this.$rootScope = $rootScope;
    this.Model = Model;
    this.ActionCableChannel = ActionCableChannel;
    this.TablePaginator = TablePaginator;
    this.Server = Server;
    this.Config = Config;
    this.Flash = Flash;
    this.Error = Error;

    this.selectedTableFilters = {};

    this.pagination = TablePaginator.config();
    this._loadModels(true);
    this._initActionCable();
  }

  /**
   * Инициировать подключение к каналу ModelsChannel
   */
  ModelsCtrl.prototype._initActionCable = function() {
    let consumer = new this.ActionCableChannel('Invent::ModelsChannel');

    consumer.subscribe(() => this._loadModels());

    this.$rootScope.$on('ModelsCtrl::UpdateTableFilters', (event, vendors) => {
      this.filters.vendors = vendors;
      this._checkCurrentVendorFilter();
    });
  };

  /**
   * Проверить, нужно ли сбросить фильтр. Нужно в том случае, если выбран фильтр по вендору, но после этого выбранный вендор был удален.
   */
  ModelsCtrl.prototype._checkCurrentVendorFilter = function() {
    // Выходим из функции, если фильтр не выбран или если после удаления вендора текущий фильтр до сих пор находится в списке существующих
    // вендоров (значит был удален вендор, который не был в активном фильтре)
    if (!this.selectedTableFilters.vendor || this.filters.vendors.find((el) => this.selectedTableFilters.vendor.vendor_id == el.vendor_id)) {
      return true;
    }

    this.clearFilter('vendor');
    this.reloadModels();
  };

  ModelsCtrl.prototype._getFiltersToSend = function() {
    let obj = angular.copy(this.selectedTableFilters);

    if (obj.type) {
      obj.type_id = obj.type.type_id;
      delete(obj.type);
    }
    if (obj.vendor) {
      obj.vendor_id = obj.vendor.vendor_id;
      delete(obj.vendor);
    }

    return obj;
  };

  /**
   * Загрузить список моделей.
   *
   * @param init - определяет, нужно ли загружать данные для инициализации фильтров
   */
  ModelsCtrl.prototype._loadModels = function(init) {
    this.Server.Invent.Model.query(
      {
        start: this.TablePaginator.startNum(),
        length: this.Config.global.uibPaginationConfig.itemsPerPage,
        init_filters: init,
        filters: this._getFiltersToSend()
      },
      (response) => {
        this.models = response.data;
        // Данные для составления нумерации страниц
        this.TablePaginator.setData(response);

        if (init) {
          this.filters = response.filters;
        }
      },
      (response, status) => {
        this.Error.response(response, status);
      }
    )
  };

  /**
   * Открыть модальное окно для создания/редактирования моделей
   */
  ModelsCtrl.prototype._openEditModal = function() {
    this.$uibModal.open({
      templateUrl: 'editModelModal.slim',
      controller: 'EditModelCtrl',
      controllerAs: 'edit',
      size: 'md',
      backdrop: 'static'
    });
  };

  /**
   * Очистить выбранный фильтр
   *
   * @param filter_type
   */
  ModelsCtrl.prototype.clearFilter = function(filter_type) {
    switch(filter_type) {
      case 'vendor':
        delete(this.selectedTableFilters.vendor);
        this.selectedTableFilters.vendor_id = null;

        break;
      case 'type':
        delete(this.selectedTableFilters.type);
        this.selectedTableFilters.type_id = null;

        break;
    };

    this.reloadModels();
  }

  /**
   * Загрузить список моделей заново.
   */
  ModelsCtrl.prototype.reloadModels = function() {
    this._loadModels();
  };

  /**
   * Открыть форму создания модели.
   */
  ModelsCtrl.prototype.newModel = function() {
    this.Server.Invent.Model.newModel(
      (response) => {
        this.Model.initData(response);
        this._openEditModal();
      },
      (response, status) => {
        this.Error.response(response, status);
      }
    );
  };

  /**
   * Загрузить данные модели.
   *
   * @param model
   */
  ModelsCtrl.prototype.editModel = function(model) {
    this.Server.Invent.Model.edit(
      { model_id: model.model_id },
      (response) => {
        this.Model.initData(response);
        this._openEditModal();
      },
      (response, status) => {
        this.Error.response(response, status);
      }
    );
  };

  /**
   * Удалить модель.
   *
   * @param model
   */
  ModelsCtrl.prototype.destroyModel = function(model) {
    let confirm_str = "Вы действительно хотите удалить модель \"" + model.item_model + "\"?";

    if (!confirm(confirm_str)) { return false; }

    this.Server.Invent.Model.delete(
      { model_id: model.model_id },
      (response) => {
        this.Flash.notice(response.full_message);
      },
      (response, status) => {
        this.Error.response(response, status);
      });
  };

// =====================================================================================================================

  function EditModelCtrl($uibModalInstance, Model, Vendors, Server, Flash, Error) {
    this.setFormName('model');

    this.$uibModalInstance = $uibModalInstance;
    this.Model = Model;
    this.Server = Server;
    this.Flash = Flash;
    this.Error = Error;

    this.model = Model.model;
    this.types = Model.types;
    this.vendors = angular.copy(Vendors.vendors);

    this._createModelPropertyListGetterSetter();
    this._addInitialValues();
  }

  // Унаследовать методы класса FormValidationController
  EditModelCtrl.prototype = Object.create(FormValidationController.prototype);
  EditModelCtrl.prototype.constructor = EditModelCtrl;

  EditModelCtrl.prototype._createModelPropertyListGetterSetter = function() {
    let model_prop_list;

    this.model.createModelPropertyListGetterSetter = (property) => {
      property.modelPropertyListGetterSetter = (property_list_id) => {
        model_prop_list = this.model.model_property_lists_attributes.find((attr) => {
          return attr.property_id == property.property_id;
        });

        if (angular.isDefined(property_list_id)) {
          model_prop_list.property_list_id = property_list_id;
        }

        return model_prop_list ? model_prop_list.property_list_id : null;
      };

      return property.modelPropertyListGetterSetter;
    }
  };

  /**
   * Установить начальные значения на списки.
   */
  EditModelCtrl.prototype._addInitialValues = function() {
    this.types.unshift(angular.copy(this.Model.toSelect.type));
    this.vendors.unshift(this.Model.toSelect.vendor);

    this.types.forEach((type) => {
      if (!type.properties) { return true; }

      type.properties.forEach((prop) => {
        if (!prop.property_lists) { return true; }

        prop.property_lists.unshift(angular.copy(this.Model.toSelect.attr));
      });
    });
  };

  /**
   * Установить массив model_property_lists, который зависит от выбранного типа техники.
   */
  EditModelCtrl.prototype.setModelPropertyList = function() {
    this.model.type_id = this.model.type.type_id;
    this.Model.setModelPropertyListAttributes();
  };

  /**
   * Создать модель.
   */
  EditModelCtrl.prototype.ok = function() {
    let model = this.Model.getObjectToSend();

    if (this.model.model_id) {
      this.Server.Invent.Model.update(
        { model_id: this.model.model_id },
        { model: model },
        (response) => {
          this.Flash.notice(response.full_message);
          this.$uibModalInstance.close();
        },
        (response, status) => {
          this.Error.response(response, status);
          this.errorResponse(response);
        }
      )
    } else {
      this.Server.Invent.Model.save(
        { model: model },
        (response) => {
          this.Flash.notice(response.full_message);
          this.$uibModalInstance.close();
        },
        (response, status) => {
          this.Error.response(response, status);
          this.errorResponse(response);
        }
      );
    }
  };

  /**
   * Закрыть модальное окно.
   */
  EditModelCtrl.prototype.cancel = function() {
    this.$uibModalInstance.dismiss();
  };
})();
import { app } from '../../app/app';

(function () {
  'use strict';

  app
    .controller('WarehouseLocationCtrl', WarehouseLocationCtrl);

    WarehouseLocationCtrl.$inject = ['$uibModal', '$uibModalInstance', 'Flash', 'Error', 'Server', 'items'];

  function WarehouseLocationCtrl($uibModal, $uibModalInstance, Flash, Error, Server, items) {
    this.$uibModal = $uibModal;
    this.$uibModalInstance = $uibModalInstance;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;
    this.item = items.item;
    this.location_sites = items.location_sites;

    this.selectIssSite = { site_id: null, name: 'Выберите площадку' };
    this.selectIssBuilding = { building_id: null, name: 'Выберите корпус' };

    this.selectIssRoomManually = { room_id: -1, name: 'Ввести комнату вручную...' };
    this.selectIssRoom = { room_id: null, name: 'Выберите комнату' };

    // Добавить для каждого значения дефолтные данные
    this.location_sites.forEach((site) => {
      site.iss_reference_buildings.forEach((building) => {
        building.iss_reference_rooms.unshift(this.selectIssRoomManually);
        building.iss_reference_rooms.unshift(this.selectIssRoom);
      });
      site.iss_reference_buildings.unshift(this.selectIssBuilding);
    });

    this.location_sites = [this.selectIssSite].concat(this.location_sites);

    this._findElementForLocation();
  }

  /**
   * Найти и присвоить уже существующие значения расположения
   */
  WarehouseLocationCtrl.prototype._findElementForLocation = function() {
    // find site
    this.location_site = this.item.location.site_id ? (
      this.location_sites.find((el) => {
        return this.item.location.site_id == el.site_id;
      })
    ) : (
      this.selectIssSite
    );

    // find building
    this.location_building = this.item.location.building_id ? (
      this.location_site.iss_reference_buildings.find((el) => {
        return this.item.location.building_id == el.building_id;
      })
    ) : (
      this.selectIssBuilding
    );

    this.location_room = {
      room_id: this.item.location.room_id,
      name   : ''
    };
  };

  /**
   * Сохранить расположение для техники
   */
  WarehouseLocationCtrl.prototype.saveLocation = function() {
    this.Server.Warehouse.Item.update(
      { id: this.item.id },
      { item: this.item },
      (response) => {
        this.Flash.notice(response.full_message);
        this.$uibModalInstance.close();
      },
      (response, status) => {
        this.Error.response(response, status);
      }
    );
  };

  WarehouseLocationCtrl.prototype.close = function() {
    this.$uibModalInstance.dismiss();
  };

  /**
   * Установить site_id для item.location и начальные значения для корпуса и комнаты
   */
  WarehouseLocationCtrl.prototype.setLocationSite = function() {
    this.item.location.site_id = angular.copy(this.location_site.site_id);

    this.location_building = this.selectIssBuilding;
    this.location_room = this.selectIssRoom;

    this.item.location.building_id = null;
    this.item.location.room_id = null;
  };

  /**
   * Установить building_id для item.location и начальное значение для комнаты
   */
  WarehouseLocationCtrl.prototype.setLocationBuilding = function() {
    if (this.location_building) {
      this.item.location.building_id = angular.copy(this.location_building.building_id);
    }
    this.location_room = this.selectIssRoom;
    this.location_room.room_name = '';

    this.item.location.room_id = null;
  };

  /**
   * Установить room_id для item.location
   */
  WarehouseLocationCtrl.prototype.setLocationRoom = function() {
    this.item.location.room_id = angular.copy(this.location_room.room_id);
  };
})();

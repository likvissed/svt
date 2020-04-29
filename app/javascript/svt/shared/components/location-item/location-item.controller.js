import { app } from '../../../app/app';

app.controller('LocationItemCtrl', LocationItemCtrl);

LocationItemCtrl.$inject = ['Server', 'Error'];

function LocationItemCtrl(Server, Error) {
  this.Server = Server;
  this.Error = Error;

  this.selectedIss = {
    site        : { site_id: null, name: 'Выберите площадку' },
    building    : { building_id: null, name: 'Выберите корпус' },
    room        : { room_id: null, name: 'Выберите комнату' },
    roomManually: { room_id: -1, name: 'Ввести комнату вручную...' }
  };

  // Значения, содержащиеся в ng-model
  this.selected_object = {
    site    : '',
    building: '',
    room    : ''
  };

  this.loadLocationSites();
}

/**
 * Загрузить все значения расположений, корпусов и комнат
 */
LocationItemCtrl.prototype.loadLocationSites = function() {
  this.location_sites = [];

  this.Server.Warehouse.Item.loadLocations(
    (response) => {
      this.location_sites = response.iss_locations;
      this.successCallback();
    },
    (response, status) => {
      this.Error.response(response, status);
    }
  );
};

LocationItemCtrl.prototype.successCallback = function() {
  // Добавить для каждого значения дефолтные данные
  this.location_sites.forEach((site) => {
    site.iss_reference_buildings.forEach((building) => {
      building.iss_reference_rooms.unshift(this.selectedIss.roomManually);
      building.iss_reference_rooms.unshift(this.selectedIss.room);
    });
    site.iss_reference_buildings.unshift(this.selectedIss.building);
  });
  this.location_sites = [this.selectedIss.site].concat(this.location_sites);

  this.findElementForLocation();
};

/**
 * Найти и присвоить уже существующие значения расположения в selected_object
 */
LocationItemCtrl.prototype.findElementForLocation = function() {
  // find site
  this.selected_object.site = this.selectedItem.location.site_id ? (
    this.location_sites.find((el) => {
      return this.selectedItem.location.site_id == el.site_id;
    })
  ) : (
    this.selectedIss.site
  );

  // find building
  this.selected_object.building = this.selectedItem.location.building_id ? (
    this.selected_object.site.iss_reference_buildings.find((el) => {
      return this.selectedItem.location.building_id == el.building_id;
    })
  ) : (
    this.selectedIss.building
  );

  this.selected_object.room = {
    room_id  : this.selectedItem.location.room_id,
    room_name: ''
  };
};

/**
 * Установить site_id для selectedItem.location и начальные значения для корпуса и комнаты
 */
LocationItemCtrl.prototype.setLocationSite = function() {
  this.selectedItem.location.site_id = angular.copy(this.selected_object.site.site_id);

  this.selected_object.building = this.selectedIss.building;
  this.selected_object.room = this.selectedIss.room;

  this.selectedItem.location.building_id = null;
  this.selectedItem.location.room_id = null;
};

/**
 * Установить building_id для selectedItem.location и начальное значение для комнаты
 */
LocationItemCtrl.prototype.setLocationBuilding = function() {
  if (this.selected_object.building) {
    this.selectedItem.location.building_id = angular.copy(this.selected_object.building.building_id);
  }
  this.selected_object.room = this.selectedIss.room;
  this.selected_object.room.room_name = '';

  this.selectedItem.location.room_id = null;
};

/**
 * Установить room_id для selectedItem.location
 */
LocationItemCtrl.prototype.setLocationRoom = function() {
  this.selectedItem.location.room_id = angular.copy(this.selected_object.room.room_id);
};

import { app } from '../../../app/app';

app.controller('LocationItemCtrl', LocationItemCtrl);

LocationItemCtrl.$inject = ['Server', 'Error'];

function LocationItemCtrl(Server, Error) {
  this.Server = Server;
  this.Error = Error;

  this.not_chosen = 'Не выбрано';

  this.selected_iss = {
    site    : { site_id: null, name: 'Выберите площадку' },
    building: { building_id: null, name: 'Выберите корпус' }
  };

  // Наименование «Корпус - комната»  выбранного из расположения техники
  if (!this.selectedItem.location) {
    this.selectedItem.names_building_room = this.not_chosen;
  }

  this.loadLocationSites();
}

/**
 * Загрузить все значения расположений, корпусов и комнат
 */
LocationItemCtrl.prototype.loadLocationSites = function() {
  this.location_sites = [];

  this.Server.Warehouse.Location.loadLocations(
    (response) => {
      this.location_sites = response.iss_locations;
      this.new_location = response.new_location;

      this.addDefaultData();
    },
    (response, status) => {
      this.Error.response(response, status);
    }
  );
};

// Добавить дефолтные данные
LocationItemCtrl.prototype.addDefaultData = function() {
  this.location_sites.forEach((site) => {
    site.iss_reference_buildings.unshift(this.selected_iss.building);
  });
  this.location_sites = [this.selected_iss.site].concat(this.location_sites);

  this.findElementForLocation();
};

/**
 * Найти и присвоить уже существующие значения расположения в selectedItem
 */
LocationItemCtrl.prototype.findElementForLocation = function() {
  // Назначить пустой объект Location для техники, если расположение отсутствует
  if (!this.selectedItem.location) { this.selectedItem.location = this.new_location; }

  this.selectedItem.location_obj = {};

  // find site
  this.selectedItem.location_obj.site = this.selectedItem.location.site_id ? (
    this.location_sites.find((el) => {
      return this.selectedItem.location.site_id == el.site_id;
    })
  ) : (
    this.selected_iss.site
  );

  // find building
  this.selectedItem.location_obj.building = this.selectedItem.location.building_id ? (
    this.selectedItem.location_obj.site.iss_reference_buildings.find((el) => {
      return this.selectedItem.location.building_id == el.building_id;
    })
  ) : (
    this.selected_iss.building
  );

  // find room
  this.selectedItem.location_obj.room = this.selectedItem.location.room_id ? (
    this.selectedItem.location_obj.building.iss_reference_rooms.find((el) => {
      return this.selectedItem.location.room_id == el.room_id;
    })
  ) : (
    ''
  );

  // Назначить names_building_room
  this.getNameBuildingRoom();
};

/**
 *  Получить для names_building_room наименование, как «Корпус - комната» из расположения техники
 */
LocationItemCtrl.prototype.getNameBuildingRoom = function() {
  this.selectedItem.names_building_room = this.selectedItem.location.building_id && this.selectedItem.location.room_id &&
   this.selectedItem.location_obj.room ? (
    this.selectedItem.location_obj.room.name
  ) : (
    this.not_chosen
  );
};

LocationItemCtrl.prototype.setDefaultLocations = function() {
  this.selectedItem.location.room_id = null;

  this.findElementForLocation();
};

LocationItemCtrl.prototype.setLocationRoom = function() {
  this.selectedItem.location.room_id = this.selectedItem.location_obj.room.room_id;
  this.getNameBuildingRoom();
};

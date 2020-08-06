import { app } from '../../../app/app';

app.controller('LocationItemCtrl', LocationItemCtrl);

LocationItemCtrl.$inject = ['Server', 'Error'];

function LocationItemCtrl(Server, Error) {
  this.Server = Server;
  this.Error = Error;

  this.not_chosen = 'Не выбрано';

  this.selected_iss = {
    site        : { site_id: null, name: 'Выберите площадку' },
    building    : { building_id: null, name: 'Выберите корпус' },
    room        : { room_id: null, name: 'Выберите комнату' },
    roomManually: { room_id: -1, name: 'Ввести комнату вручную...' }
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
      console.log('response', response);
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
    site.iss_reference_buildings.forEach((building) => {
      building.iss_reference_rooms.unshift(this.selected_iss.roomManually);
      building.iss_reference_rooms.unshift(this.selected_iss.room);
    });
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

  this.selectedItem.location.name = '';

  // Назначить names_building_room
  this.getNameBuildingRoom();
};

/**
 *  Получить для names_building_room наименование, как «Корпус - комната» из расположения техники
 */
LocationItemCtrl.prototype.getNameBuildingRoom = function() {
  this.selectedItem.names_building_room = this.selectedItem.location.building_id && this.selectedItem.location.room_id &&
   this.selectedItem.location_obj.building ? (
    this.getNameRoom()
  ) : (
    this.not_chosen
  );
};

/**
 *  Получить наименование комнаты
 */
LocationItemCtrl.prototype.getNameRoom = function() {
  // find room
  let object_room = this.selectedItem.location_obj.building.iss_reference_rooms.find((el) => {
    return this.selectedItem.location.room_id == el.room_id;
  });

  let room_name = this.selectedItem.location.room_id == -1 ? (
    this.selectedItem.location
  ) : (
    object_room
  );

  if (room_name) {
    room_name = room_name.name;
  } else {
    // Если room_id задан, но комнаты уже нет
    room_name = this.not_chosen
    this.selectedItem.location.room_id = null;
  }

  // Если выбрали "Ввести комнату вручную", но в поле ввода еще не введен текст
  if (room_name === '') {
    return this.not_chosen
  } else { return `${this.selectedItem.location_obj.building.name}-${room_name}` }

};

LocationItemCtrl.prototype.setLocationSite = function() {
  this.findElementForLocation();

  this.getNameBuildingRoom();
};

LocationItemCtrl.prototype.setLocationBuilding = function() {
  this.selectedItem.location.room_id = null;
  this.findElementForLocation();

  this.getNameBuildingRoom();
};

LocationItemCtrl.prototype.setLocationRoom = function() {
  this.getNameBuildingRoom();
};

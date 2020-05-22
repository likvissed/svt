import { app } from '../../app/app';

(function () {
  'use strict';

  app.controller('WarehouseEditLocationCtrl', WarehouseEditLocationCtrl);

  WarehouseEditLocationCtrl.$inject = ['$uibModalInstance', 'Flash', 'Error', 'Server', 'items', '$timeout'];

  function WarehouseEditLocationCtrl($uibModalInstance, Flash, Error, Server, items, $timeout) {

    this.$uibModalInstance = $uibModalInstance;
    this.Flash = Flash;
    this.Error = Error;
    this.Server = Server;
    this.item = items.item;
    this.$timeout = $timeout;

    this.item.count_for_invent_num = this.item.count;
    this.item.activeTab = 0;
    this.activeTab = 0;

    this.items_attributes = [];
    this.items_attributes.push(this.item);
  }

  /**
   * Сохранить расположение для техники
   */
  WarehouseEditLocationCtrl.prototype.saveLocation = function() {
    if (this.items_attributes.length == 1) {
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
    } else if (this.validLocations()) {
      this.Server.Warehouse.Item.split(
        { id: this.item.id },
        { items: this.items_attributes },
        (response) => {
          this.Flash.notice(response.full_message);
          this.$uibModalInstance.close();
        },
        (response, status) => {
          this.Error.response(response, status);
        }
      );
    }
  };

  /**
   * Проверка распределения суммарного количества техники
   * и заполненного расположения для всех позиций
   */
  WarehouseEditLocationCtrl.prototype.validLocations = function() {
    let count_items = this.calculationValue();

    let not_chosen = this.items_attributes.find((el) => {
      return el.names_building_room == 'Не выбрано';
    });

    if (this.item.count != count_items) {
      this.Flash.alert(`Количество распределенной техники не соответствует количеству на складе - ${this.item.count} шт.`);

      return false;
    } else if (not_chosen) {
      this.Flash.alert('Необходимо заполнить расположение для всех позиций техники');

      return false;
    } else { return true }
  };

  WarehouseEditLocationCtrl.prototype.close = function() {
    this.$uibModalInstance.dismiss();
  };


  /**
   *  Имеется ли больше одной единицы техники на складе
   */
  WarehouseEditLocationCtrl.prototype.hasMoreItem = function() {
    return this.item.count > 1 && this.item.status == 'non_used';
  };


  /**
   * Добавление нового элемента item и обнуление его расположения
   */
  WarehouseEditLocationCtrl.prototype.addLocation = function() {
    let new_item = angular.copy(this.item);

    new_item.location = '';
    new_item.location_id = 0;
    new_item.count_for_invent_num = 1;

    // получить последний номер activeTab и увеличить на единицу для новой позиции
    new_item.activeTab = this.items_attributes.slice(-1)[0].activeTab + 1;

    if (this.changeCountForInventNum()) {
      this.items_attributes.push(new_item);
    }

    this.setActiveTab();
  };

  /**
   * Сделать активным последний существующий таб
   */
  WarehouseEditLocationCtrl.prototype.setActiveTab = function() {
    this.$timeout(() => this.activeTab = this.items_attributes.length - 1, 0);
  };

  /**
   * Удаление позиции техники
   */
  WarehouseEditLocationCtrl.prototype.reduceLocation = function(index) {
    this.items_attributes.splice(index, 1);

    // перезаписать все activeTab для корректного вывода вкладок, так как <item.activeTab == $index>
    this.items_attributes.forEach(function (item, i) { item.activeTab = i; });

    this.setActiveTab();
  };

  /**
   * Подсчет суммарного значения во всех полях ввода для "Количество техники" на форме
   */
  WarehouseEditLocationCtrl.prototype.calculationValue = function() {
    let count_items = 0;

    this.items_attributes.forEach((item) => { count_items += parseInt(item.count_for_invent_num) });

    return count_items;
  };

  /**
   * Проверка введенного количества техники и сравнение с суммарным числом
   */
  WarehouseEditLocationCtrl.prototype.changeCountForInventNum = function() {
    let ind = this.items_attributes.findIndex((item) => item.count_for_invent_num > 1);
    let count_items = this.calculationValue();

    if (ind >= 0) {
      // Уменьшаем значение на единицу при добавлении нового элемента
      this.items_attributes[ind].count_for_invent_num -= 1;

      return true;

    } else if (this.item.count == count_items) {
      this.Flash.alert('Количество техники разбито максимально');

      return false;

    } else if (this.item.count > count_items) {

      return true;
    }
  };

  /**
   * Изменение введенного числа пользователем в поле "Количество техники"
   *
   *  1 - введенное значение больше суммарного количества техники на складе
   *  2 - введенное значение <= 0 (+ запрет отрицательных чисел)
   *  3 - суммарное значение полей "Количество техники" уже превышает общее количество на складе
   */
  WarehouseEditLocationCtrl.prototype.changeValidCountItems = function(count_for_invent_num, index) {
    if (count_for_invent_num > this.item.count || count_for_invent_num <= 0 || this.calculationValue() > this.item.count) {
      this.items_attributes[index].count_for_invent_num = 1;
    }
  };
})();

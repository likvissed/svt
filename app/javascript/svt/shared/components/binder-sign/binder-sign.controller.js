import { app } from '../../../app/app';

app.controller('BinderSignCtrl', BinderSignCtrl);

BinderSignCtrl.$inject = ['Server', 'Error'];

function BinderSignCtrl(Server, Error) {
  this.Server = Server;
  this.Error = Error;

  this.selected = {
    sign: { sign_id: null, short_description: 'Выберите признак' }
  };

  this.binders = this.selectedItem.binders;

  this.loadSigns();
}

BinderSignCtrl.prototype.loadSigns = function() {
  this.signs = [];
  this.long_description_signs = [];

  this.Server.Invent.Sign.loadSigns(
    (response) => {
      this.signs = response.signs;

      this.new_binder = response.new_binder;
      this.new_binder.warehouse_item_id = this.selectedItem.id;

      this.prepareData();
    },
    (response, status) => {
      this.Error.response(response, status);
    }
  );
}

BinderSignCtrl.prototype.prepareData = function() {
  this.signs = [this.selected.sign].concat(this.signs);

  this.binders.forEach((binder, index) => {
    this.onChangeSign(index);
  });
};

BinderSignCtrl.prototype.onAddBinder = function() {
  this.binders.push(angular.copy(this.new_binder));
};

BinderSignCtrl.prototype.onChangeSign = function(index) {
  let sign = this.signs.find((el) => {
    return this.binders[index].sign_id == el.sign_id;
  })

  // Изменить описание признака
  this.long_description_signs[index] = sign.long_description;
};

BinderSignCtrl.prototype.onDeleteBinder = function(value, index) {
  if (value.id) {
    value._destroy = 1;
  } else {
    this.binders.splice(index, 1);
  }

  this.long_description_signs.splice(index, 1);
};

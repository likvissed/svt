module Invent
  class SignsController < ApplicationController
    before_action :check_access

    def load_signs
      signs = Sign.all
      # Можно использовать любой из классов binder, тк данные идентичны
      new_binder = Warehouse::Binder.new

      render json: { signs: signs, new_binder: new_binder }
    end

    protected

    def check_access
      authorize %i[invent sign], :ctrl_access?
    end
  end
end

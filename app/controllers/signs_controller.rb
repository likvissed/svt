class SignsController < ApplicationController
  before_action :check_access

  def load_signs
    signs = Sign.all
    new_binder = Binder.new

    render json: { signs: signs, new_binder: new_binder }
  end

  protected

  def check_access
    authorize %i[sign], :ctrl_access?
  end
end

class Warehouse::ApplicationController < ApplicationController
  before_action :check_access

  protected

  def check_access
    authorize [:warehouse, controller_name.singularize.to_sym], :ctrl_access?
  end
end
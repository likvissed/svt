class UserIssesController < ApplicationController
  def users_from_division
    render json: UserIss.select(:id_tn, :fio).where(dept: params[:division])
  end
end
module Invent
  class ModelsController < ApplicationController
    def index
      @models = Model.by_type_id(params[:type_id])

      render json: @models
    end
  end
end

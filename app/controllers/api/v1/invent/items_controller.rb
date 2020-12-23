module Api
  module V1
    module Invent
      class ItemsController < ApplicationController
        skip_before_action :authenticate_user!

        def index
          result = if params[:invent_num].present?
                     ::Invent::Item
                       .where(invent_num: params[:invent_num], status: :in_workplace)
                       .includes(%i[type model])
                       .as_json(
                         include: {
                           type: {
                             except: %i[create_time modify_time]
                           }
                         },
                         except: %i[create_time modify_time],
                         methods: :short_item_model
                       )
                   else
                     []
                   end

          render json: result
        end
      end
    end
  end
end

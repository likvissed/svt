module Api
  module V2
    module Invent
      class ItemsController < ApplicationController
        skip_before_action :authenticate_user!

        def search_barcode
          @barcode = Barcode
                       .includes(codeable: %i[type model barcode_item workplace])
                       .find_by(codeable_type: 'Invent::Item', id: params[:barcode])

          barcode_item = @barcode
                           .as_json(include: {
                                      codeable: {
                                        include: %i[type barcode_item workplace],
                                        except: %i[create_time modify_time],
                                        methods: :short_item_model
                                      }
                                    })

          result = barcode_item.present? && barcode_item['codeable']['status'] == 'in_workplace' ? barcode_item['codeable'] : {}

          render json: result
        end
      end
    end
  end
end

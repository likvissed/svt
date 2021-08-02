module Api
  module V2
    module Invent
      class ItemsController < ApplicationController
        skip_before_action :authenticate_user!
        def barcode
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

        def search_items
          workplace_count = params[:dept].present? ? ::Invent::WorkplaceCount.find_by(division: params[:dept]) : ''

          if params[:dept].present? && workplace_count.blank?
            message = "Отдел №#{params[:dept]} не существует"
            render  json: { error: message }, status: :not_found
          elsif params[:fio].blank? && params[:invent_num].blank? && params[:barcode].blank? && params[:dept].blank?
            message = 'Требуемые параметры не найдены'
            render  json: { error: message }, status: :not_found
          elsif params[:barcode].present? && params[:barcode].scan(/\D/).empty? == false
            message = 'Параметр barcode содержит не только цифры'
            render  json: { error: message }, status: :not_found
          else
            filtering_params = {}
            filtering_params[:responsible] = params[:fio]
            filtering_params[:invent_num] = params[:invent_num]
            filtering_params[:barcode_item] = params[:barcode]
            filtering_params[:workplace_count_id] = workplace_count.try(:workplace_count_id)

            result = ::Invent::Item
                       .filter(filtering_params)
                       .includes(%i[type model barcode_item workplace])
                       .as_json(
                         include: [
                           :barcode_item,
                           :workplace,
                           {
                             type: {
                               except: %i[create_time modify_time]
                             }
                           }
                         ],
                         except: %i[create_time modify_time],
                         methods: :short_item_model
                       )

            render status: :ok, json: result
          end
        end
      end
    end
  end
end

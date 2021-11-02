module Api
  module V3
    module Warehouse
      class RequestsController < ApplicationController
        skip_before_action :authenticate_user!
        # skip_before_action :verify_authenticity_token

        def new
          @form = ::Api::V3::Warehouse::Requests::NewOfficeEquipmentForm.new(::Warehouse::Request.new)

          case params['category']
          when 1
            request = ::Warehouse::Request.new(
              number_***REMOVED***: params['number_***REMOVED***'],

              user_tn: params['parametrs']['user_tn'],
              user_fio: params['parametrs']['user_fio'],
              user_dept: params['parametrs']['user_dept'],
              user_phone: params['parametrs']['user_phone']
            )

            params['parametrs']['columns'].each do |item|
              request.request_items.build(
                name: item['name'],
                reason: item['reason'],
                count: item['count'],
                properties: item['properties']
              )
            end

            # Если имеются прикрепленные файлы
            if params['files'].present?
              params['files'].each do |file|
                request.attachments.build(document: file['doc'])
              end
            end

            # fo = File.new "/home/lika/Загрузки/123211.pdf"
            # request.attachments.build(document: fo)

            # Преобразование в json params
            request_json = request.as_json
            request_json['request_items'] = request.request_items.as_json
            request_json['attachments'] = request.attachments.as_json if request.attachments.present?
            Rails.logger.info "request json: #{request_json}".red
          when 2
          when 3
          else
            render json: { full_message: 'Неверная категория заявки' }, status: 422
          end

          if @form.validate(request_json)
            @form.save
            # Rails.logger.info "success: #{@form.inspect}".green
            render json: { full_message: 'Заявка создана' }, status: 200
          else
            # Rails.logger.info "error: #{@form.inspect}".red
            render json: { full_message: @form.errors.full_messages.join('. ') }, status: 422
          end
        end
      end
    end
  end
end

module Api
  module V3
    module Warehouse
      class RequestsController < ApplicationController
        skip_before_action :authenticate_user!
        # skip_before_action :verify_authenticity_token

        def new_office_equipment
          @form = ::Api::V3::Warehouse::Requests::NewOfficeEquipmentForm.new(::Warehouse::Request.new)

          request = ::Warehouse::Request.new(
            status: 'new',
            category: 'office_equipment',
            number_***REMOVED***: params['id'],

            user_tn:  params['parameters']['common']['tn'],
            user_fio: params['parameters']['common']['fio']
          )

          user = find_user(request.user_tn)
          request.user_dept = user.first.try(:[], 'departmentForAccounting')
          request.user_phone = user.first.try(:[], 'phoneText')
          request.user_id_tn = user.first.try(:[], 'id')

          params['parameters']['table_data'].each do |data|
            request.request_items.build(
              type_name: data['type'],
              name: 'Системный блок',
              count: 1,
              reason: data['reason'],
              invent_num: data['invent_num'],
              properties: data['properties']
            )
          end

          # Если имеются прикрепленные файлы
          if params['parameters']['files'].present?
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
          Rails.logger.info "request json: #{request_json}".yellow

          if @form.validate(request_json)
            @form.save

            render json: { id: @form.model.request_id }, status: 200
          else
            render json: { full_message: @form.errors.full_messages.join('. ') }, status: 422
          end
        end

        # Поиск пользователя в НСИ
        def find_user(tn)
          UsersReference.info_users("personnelNo==#{tn}")
        end

        # Ответ от пользователя
        def answer_from_user
          request = ::Warehouse::Request.find_by(request_id: params[:id])

          return Rails.logger.info "Заявка не найдена: #{params[:id]}".red if request.blank?

          if params[:answer] == true
            request.update(status: :on_signature)

            # Описать этап №5
          else
            ::Warehouse::Requests::Close.new(request.user_id_tn, params[:id]).run
          end
        end
      end
    end
  end
end

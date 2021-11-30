module Api
  module V3
    module Warehouse
      class RequestsController < ApplicationController
        skip_before_action :authenticate_user!
        skip_before_action :verify_authenticity_token

        # Api с орбиты для создания заявки
        def new_office_equipment
          @form = ::Api::V3::Warehouse::Requests::NewOfficeEquipmentForm.new(::Warehouse::Request.new)

          request = ::Warehouse::Request.new(
            status: 'new',
            category: 'office_equipment',
            number_***REMOVED***: params['id'],

            number_***REMOVED***: JSON.parse(params['parameters'])['common']['***REMOVED***_id'],

            user_tn: JSON.parse(params['parameters'])['common']['tn']
          )

          user = find_user("personnelNo==#{request.user_tn}")
          request.user_fio = user.first.try(:[], 'fullName')
          request.user_dept = user.first.try(:[], 'departmentForAccounting')
          request.user_phone = user.first.try(:[], 'phoneText')
          request.user_id_tn = user.first.try(:[], 'id')

          JSON.parse(params['parameters'])['table_data'].each do |data|
            name = case data['type']
                   when 'pc'
                     'Системный блок'
                   else
                     'Неизвестный тип'
                   end

            request.request_items.build(
              type_name: data['type'],
              name: name,
              count: 1,
              reason: data['reason'],
              invent_num: data['invent_num'],
              description: data['description']
            )
          end

          # Если имеются прикрепленные файлы
          if params['files'].present?
            params['files'].each { |file| request.attachments.build(document: file) }
          end

          # Преобразование в json params
          request_json = request.as_json
          request_json['request_items'] = request.request_items.as_json
          request_json['attachments'] = request.attachments.as_json if request.attachments.present?

          if @form.validate(request_json)
            @form.save

            render json: { id: @form.model.request_id }, status: 200
          else
            render json: { full_message: @form.errors.full_messages.join('. ') }, status: 422
          end
        end

        # Api для орбиты для ответа от пользователя
        def answer_from_user
          request = ::Warehouse::Request.find_by(request_id: params[:id])

          raise "Заявка не найдена: #{params[:id]}" if request.blank?
          raise "Расходного ордера на выдачу ВТ не существует: #{params[:id]}" if request.order.blank?

          if params[:answer] == true
            request.update(status: :in_work)
          else
            request.update(status: :closed)

            request.order.destroy if request.order.present?

            Orbita.add_event(request.request_id, request.user_id_tn, 'close')
          end

          ActionCable.server.broadcast 'requests', nil
        end

        # Api для ssd о подписанном/отклоненном документе от начальника
        def answer_from_owner
          request = ::Warehouse::Request.find_by(ssd_id: params[:process_id])
          raise "Заявка не найдена c process_id: #{params[:process_id]}" if request.blank?

          owner_id_tn = find_user("login==#{params[:sign_***REMOVED***_user]}").first.try(:[], 'id') # CGI.escape

          if params[:status] == 'SIGNED'
            raise "Файл отсутствует для заявки c process_id: #{params[:process_id]}" if params[:files].blank?

            params[:files].original_filename = 'Рекомендации.pdf'
            request.attachments.build(document: params[:files], is_public: false)

            request.status = :create_order

            request.save

            message = params[:sign_comment].present? ? "Рекомендации подписаны, комментарий: '#{params[:sign_comment]}'" : 'Рекомендации подписаны'
            Orbita.add_event(request.request_id, owner_id_tn, 'workflow', { message: message })
          else
            request.update(status: :closed)

            Orbita.add_event(request.request_id, owner_id_tn, 'workflow', { message: "Рекомендации отклонены, комментарий: '#{params[:sign_comment]}'" })
            Orbita.add_event(request.request_id, owner_id_tn, 'close')
          end

          ActionCable.server.broadcast 'requests', nil
        end

        def request_files
        end

        private

        # Поиск пользователя в НСИ
        def find_user(search)
          UsersReference.info_users(search)
        end
      end
    end
  end
end

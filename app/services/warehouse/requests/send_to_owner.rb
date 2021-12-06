module Warehouse
  module Requests
    # Отправить файл на подпись в ССД выбранному руководителю
    class SendToOwner < Warehouse::ApplicationService
      def initialize(current_user, request_id, owner, new_request_params)
        @current_user = current_user
        @request_id = request_id
        @owner = owner
        @new_request_params = new_request_params

        super
      end

      def run
        load_request
        save_recommendations
        load_request_params
        generate_report
        find_login
        send_file
        send_into_***REMOVED***

        broadcast_requests

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_request
        @request = Request.includes(
          :request_items,
          :attachments
        ).find(@request_id)

        authorize @request, :send_to_owner?
      end

      def save_recommendations
        @form = Requests::SaveRecommendationForm.new(Request.find(@request_id))

        if @form.validate(@new_request_params)
          @form.save

          load_request
        else
          error[:full_message] = @form.errors.full_messages.join('. ')

          raise 'Данные не обновлены'
        end
      end

      def load_request_params
        @request_params = @request.as_json(
          include: [
            :request_items,
            :attachments
          ]
        )
      end

      def generate_report
        output = TemplateReport.new.to_pdf(@request_params)

        t = Tempfile.new(['Рекомендация_', '.pdf'])
        t.binmode
        t.write(output)
        t.rewind
        t.close

        @file = File.open(t.path)
      end

      def find_login
        @login_current_user = UsersReference.info_users("personnelNo==#{@current_user.tn}").first.try(:[], 'login')
        @login_owner = UsersReference.info_users("personnelNo==#{@owner['personnelNo']}").first.try(:[], 'login')

        return if @login_owner.present?

        error[:full_message] = "Не найдена учетная запись в ЛК для пользователя: #{@owner['fullName']}"
        raise 'Не удалось найти логин выбранного руководителя'
      end

      def send_file
        response = SSD.send_for_signature(@request_id, [@file], @login_current_user, @login_owner, "1202*#{@request_id}")

        update_status(response)
      end

      def update_status(response_from_ssd)
        @request.update(
          status: :on_signature,
          ssd_id: response_from_ssd['process_id'],
          ssd_definition: response_from_ssd['definition_id']
        )
      end

      def send_into_***REMOVED***
        # Добавить сформированный файл рекомендаций для руководителя в Орбиту
        @file = File.open(@file)
        Orbita.add_event(@request_id, @current_user.id_tn, 'add_files', { is_public: false }, [@file])

        arr_fio = @owner['fullName'].split(' ')
        user_initial = "#{arr_fio[0]} #{arr_fio[1][0]}.#{arr_fio[2][0]}."

        Orbita.add_event(@request_id, @current_user.id_tn, 'workflow', { message: "Отправлен список рекомендаций на подпись в ССД: #{user_initial}" })
      end
    end
  end
end

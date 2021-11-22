module Warehouse
  module Requests
    class AssignNewExecutor < Warehouse::ApplicationService
      def initialize(current_user, request_id, executor)
        @current_user = current_user
        @request_id = request_id
        @executor = executor

        super
      end

      def run
        load_request
        check_executor

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_request
        @request = Request.find(@request_id)

        authorize @request, :assign_new_executor?
      end

      def check_executor
        return if @request.executor_fio == @executor['fullname']

        @old_user_tn = @request.executor_tn

        @request.executor_fio = @executor['fullname']
        @request.executor_tn = @executor['tn']

        if @request.save
          Orbita.add_event(@request_id, @current_user.id_tn, 'add_workers', { tns: [@executor['tn']] })
          Orbita.add_event(@request_id, @current_user.id_tn, 'del_workers', { tns: [@old_user_tn] })
        end
      end
    end
  end
end

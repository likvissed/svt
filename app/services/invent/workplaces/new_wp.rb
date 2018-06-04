module Invent
  module Workplaces
    class NewWp < BaseService
      def initialize(current_user)
        @current_user = current_user

        super
      end

      def run
        init_workplace
        load_properties

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def init_workplace
        @workplace = Workplace.new
        authorize @workplace, :new?
        set_workplace_params
      end

      def set_workplace_params
        data[:workplace] = @workplace.as_json(methods: :disabled_filters)
        data[:workplace]['items_attributes'] = []
      end

      def load_properties
        properties = LkInvents::InitProperties.new(@current_user)
        return data[:prop_data] = properties.data if properties.run

        raise 'Ошибка сервиса LkInvents::InitProperties'
      end
    end
  end
end

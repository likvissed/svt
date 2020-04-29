module Warehouse
  module Supplies
    class NewSupply < BaseService
      def initialize(current_user)
        @current_user = current_user

        super
      end

      def run
        init_supply
        init_operation
        load_types
        add_location

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def init_supply
        data[:supply] = Supply.new
        authorize data[:supply], :new?
      end

      def init_operation
        data[:operation] = data[:supply].operations.build(shift: 0)
      end

      def load_types
        data[:eq_types] = Invent::Type.all
      end

      def add_location
        data[:location] = Location.new
      end
    end
  end
end

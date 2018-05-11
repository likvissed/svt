module Invent
  module Vendors
    class Create < Invent::ApplicationService
      def initialize(vendor_params)
        @error = {}
        @vendor_params = vendor_params
      end

      def run
        create_vendor
        broadcast_vendors

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def create_vendor
        vendor = Vendor.new(@vendor_params)
        return if vendor.save

        error[:object] = vendor.errors
        error[:full_message] = vendor.errors.full_messages.join('. ')
        raise 'Модель не сохранена'
      end
    end
  end
end

module Invent
  module Vendors
    class Destroy < Invent::ApplicationService
      def initialize(vendor_id)
        @id = vendor_id

        super
      end

      def run
        find_vendor
        destroy_vendor
        broadcast_vendors

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_vendor
        @vendor = Vendor.find(@id)
      end

      def destroy_vendor
        return if @vendor.destroy

        vendor_errors = @vendor.errors.full_messages
        model_errors = @vendor.models.map { |m| m.errors.full_messages }
        error[:full_message] = [vendor_errors, model_errors].flatten.join('. ')

        raise 'Вендор не удален'
      end
    end
  end
end

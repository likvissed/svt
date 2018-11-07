module Invent
  module Models
    class BaseService < Invent::ApplicationService
      protected

      def load_types
        data[:types] = Invent::Type.all
                         .includes(properties: :property_lists)
                         .as_json(include: { properties: { include: :property_lists } }).each do |type|
          type['properties'].delete_if { |prop| %w[list list_plus].exclude?(prop['property_type']) }
        end
      end
    end
  end
end

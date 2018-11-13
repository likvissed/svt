module Invent
  module Models
    class Index < BaseService
      def initialize(params)
        @params = params

        super
      end

      def run
        load_models
        limit_records
        prepare_to_render
        load_filters if need_init_filters?

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_models
        data[:recordsTotal] = Model.count
        @models = Model.all
        run_filters if params[:filters]
      end

      def run_filters
        @models = @models.filter(filtering_params)
      end

      def limit_records
        data[:recordsFiltered] = @models.count
        @models = @models
                    .by_type_id(params[:type_id])
                    .includes(:vendor, :type, model_property_lists: %i[property property_list])
                    .order(model_id: :desc)
                    .limit(params[:length])
                    .offset(params[:start])
      end

      def prepare_to_render
        data[:data] = @models.as_json(include: [:vendor, :type, model_property_lists: { include: %i[property property_list] }]).each do |model|
          model['all_properties'] = model['model_property_lists'].map do |prop_list|
            "#{prop_list['property']['short_description']}: #{prop_list['property_list']['short_description']}"
          end.join('; ')
        end
      end

      def load_filters
        data[:filters] = {}
        data[:filters][:types] = Type.select(:type_id, :short_description)
        data[:filters][:vendors] = Vendor.all.order(:vendor_name)
      end

      def filtering_params
        JSON.parse(params[:filters]).slice('vendor_id', 'type_id', 'item_model')
      end
    end
  end
end

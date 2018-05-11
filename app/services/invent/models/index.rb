module Invent
  module Models
    class Index < Invent::ApplicationService
      def initialize(params)
        @data = {}
        @start = params[:start]
        @length = params[:length]
        @type_id = params[:type_id]
        @init_filters = params[:init_filters] == 'true'
        @conditions = JSON.parse(params[:filters]) if params[:filters]
      end

      def run
        load_models
        limit_records
        prepare_to_render
        load_filters if @init_filters

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
        run_filters if @conditions
      end

      def run_filters
        @models = @models.where(vendor_id: @conditions['vendor_id']) unless @conditions['vendor_id'].to_i.zero?
        @models = @models.where(type_id: @conditions['type_id']) unless @conditions['type_id'].to_i.zero?
        @models = @models.where('item_model LIKE ?', "%#{@conditions['item_model']}%") if @conditions['item_model'].present?
      end

      def limit_records
        data[:recordsFiltered] = @models.count
        @models = @models.by_type_id(@type_id).includes(:vendor, :type, model_property_lists: [:property, :property_list]).order(model_id: :desc).limit(@length).offset(@start)
      end

      def prepare_to_render
        data[:data] = @models.as_json(include: [:vendor, :type, model_property_lists: { include: [:property, :property_list] }]).each do |model|
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
    end
  end
end

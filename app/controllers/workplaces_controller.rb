class WorkplacesController < ApplicationController

  protect_from_forgery except: :create

  def index
    respond_to do |format|
      format.html
      format.json do
        @workplaces = Workplace
                        .left_outer_joins(:user_iss)
                        .left_outer_joins(:workplace_type)
                        .left_outer_joins(:inv_items)
                        .select('invent_workplace.*, invent_workplace_type.short_description as wp_type, user_iss
.fio_initials as responsible, count(invent_item.item_id) as count')

        render json: @workplaces
      end
    end
  end

  def create
    @workplace = Workplace.new(workplace_params)
    logger.info "WORKPLACE: #{@workplace.inspect}".red
    @workplace.inv_items.each_with_index do |item, index|
      logger.info "ITEM [#{index}]: #{item.inspect}".green

      item.inv_property_values.each_with_index do |val, index|
        logger.info "PROP_VALUE [#{index}]: #{val.inspect}".cyan
      end
    end
    # logger.info "INV_PROPERTY_VALUES: #{@workplace.inspect}"
    # if @workplace.save
    #   render json: { full_message: 'ok' }, status: :ok
    # else
    #   render json: { full_message: @workplace.errors.full_messages.join(', ') }, status: :unprocessable_entity
    # end
  end

  # Получить состав рабочего места
  def show_workplace_structure
  # Вывести состав указанного РМ
  # SELECT
  #   i.item_id, i.type_id, i.parent_id, i.workplace_id,
  #   t.name, t.short_description as type_short_descr,
  #   p.property_id, p.name as prop_name, p.short_description as prop_short_descr, p.type,
  #   CASE p.type
  #     WHEN 'int' THEN pv.value_int
  #     WHEN 'date' THEN pv.value_date
  #     WHEN 'float' THEN pv.value_float
  #     WHEN 'list' THEN pv.value_list
  #     WHEN 'string' THEN pv.value_string
  #     WHEN 'longstring' THEN pv.value_longstring
  #   END as value
  # FROM invent_item i
  # LEFT OUTER JOIN invent_type t
  #   USING(type_id)
  # LEFT OUTER JOIN invent_property p ON
  #   p.type_id = t.type_id
  # LEFT OUTER JOIN invent_property_value pv ON
  #   pv.item_id = i.item_id AND pv.property_id = p.property_id
  # WHERE workplace_id = 2;

  # Получить все типы объектов с их свойствами и значениями
  # SELECT
  #   t.*,
  #   i.*,
  #   p.*,
  #   p.name as prop_name,
  #   CASE type
  #     WHEN 'int' THEN pv.value_int
  #     WHEN 'date' THEN pv.value_date
  #     WHEN 'float' THEN pv.value_float
  #     WHEN 'list' THEN pv.value_list
  #     WHEN 'string' THEN pv.value_string
  #     WHEN 'longstring' THEN pv.value_longstring
  #   END as value
  # FROM invent_type t
  # LEFT OUTER JOIN invent_item i
  #   USING(type_id)
  # LEFT OUTER JOIN invent_property p ON
  #   p.type_id = t.type_id
  # LEFT OUTER JOIN invent_property_value pv ON
  #   pv.item_id = i.item_id AND pv.property_id = p.property_id

  # WHERE i.workplace_id = 1
  # LIMIT 1
  end

  private

  def workplace_params
    params.require(:workplace).permit(
      :workplace_count_id,
      :workplace_type_id,
      :id_tn,
      :location,
      :comment,
      :status,
      inv_items_attributes: [
        :id,
        :parent_id,
        :type_id,
        :workplace_id,
        :location,
        :model_name,
        :invent_num,
        :_destroy,
        inv_property_values_attributes: [
          :id,
          :property_id,
          :item_id,
          :value,
          :_destroy
        ]
      ]
    )
  end
end

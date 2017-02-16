class WorkplacesController < ApplicationController

  def index
    respond_to do |format|
      format.html
      format.json do
        # @workplaces = Workplace.all
        render json: [
          { name: 'Место-***REMOVED***-1', type: 'Конструкторское', responsible: '***REMOVED*** Р.Ф.', location: '3а-321а', count: 4},
          { name: 'Место-***REMOVED***-2', type: 'Офисное', responsible: '***REMOVED*** Р.Ф.', location: '3а-321а', count: 2}
        ]
      end
    end
  end

  def create

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

end

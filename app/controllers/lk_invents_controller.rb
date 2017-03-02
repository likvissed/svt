class LkInventsController < ApplicationController
  # Получить список отделов, закрепленных за пользователем и список всех типов оборудования с их параметрами
  def init
    # Получить список отделов
    @workplace_count = WorkplaceResponsible
      .left_outer_joins(:user_iss, :workplace_count)
      .select('invent_workplace_count.workplace_count_id, invent_workplace_count.division')
      .where('user_iss.tn = ?', params[:tn])

    # Получить список типов оборудования с их свойствами и возможными значениями
    @inv_types = InvType
                   .joins('LEFT OUTER JOIN invent_property USING(type_id)')
                   .joins('LEFT OUTER JOIN invent_model USING(type_id)')
                   .joins('LEFT OUTER JOIN invent_model_property_list ON invent_model_property_list.model_id =
invent_model.model_id')
                   .select('invent_type.type_id, invent_type.name, invent_type.short_description as type_short_descr,
invent_property.property_id, invent_property.name as prop_name, invent_property.short_description as
prop_short_descr, invent_property.property_order, invent_property.property_type, invent_property.mandatory,
invent_property.multiple, invent_property.uniq')

#     @inv_types = InvType
#                    .left_outer_joins(:inv_properties)
#                    .select('invent_type.type_id, invent_type.name, invent_type.short_description as type_short_descr,
# invent_property.property_id, invent_property.name as prop_name, invent_property.short_description as
# prop_short_descr, invent_property.property_order, invent_property.property_type, invent_property.mandatory,
# invent_property.multiple, invent_property.uniq')
                   # .where('invent_type.name != "unknown"')

    # SELECT
    #   t.name, t.short_description as type_short_descr,
    #   p.property_id, p.name as prop_name, p.short_description as prop_short_descr, p.type, p.mandatory, p.multiple, p.uniq
    # FROM invent_type t
    # LEFT OUTER JOIN invent_property p ON
    #   t.type_id = p.type_id
    # WHERE t.name != 'unknown';

    # Получить список типов РМ
    @wp_types = WorkplaceType.all

    data = {
      divisions:  @workplace_count,
      eq_types:   transform(@inv_types),
      wp_types:   @wp_types
    }
    render json: data, status: :ok
  end

  # Получить данные по выбранном отделу (список РМ, макс. число, список работников отдела)
  def show_division_data
    # Получить рабочие места указанного отдела
    @workplaces = WorkplaceCount
                    .joins('RIGHT OUTER JOIN invent_workplace USING(workplace_count_id)')
                    .joins('LEFT OUTER JOIN user_iss ON invent_workplace.id_tn = user_iss.id_tn')
                    .joins('LEFT OUTER JOIN invent_workplace_type ON invent_workplace.workplace_type_id =
invent_workplace_type.workplace_type_id')
                    .select('invent_workplace.*, invent_workplace_type.name as type_name, invent_workplace_type
.short_description as type_short_descr, user_iss.fio_initials as fio, user_iss.tn as user_tn, user_iss.duty')
                    .where(division: params[:division])

    # SELECT
    #   invent_workplace.*,
    #   invent_workplace_type.name as type_name,
    #   invent_workplace_type.short_description as type_short_descr,
    #   user_iss.fio_initials as fio,
    #   user_iss.tn as user_tn
    # FROM `invent_workplace_count`
    # RIGHT OUTER JOIN
    #   invent_workplace USING(workplace_count_id)
    # LEFT OUTER JOIN invent_workplace_type ON
    #   invent_workplace.workplace_type_id = invent_workplace_type.workplace_type_id
    # LEFT OUTER JOIN `user_iss` ON
    #   `user_iss`.`id_tn` = `invent_workplace_count`.`id_tn`
    # WHERE `invent_workplace_count`.`division` = '***REMOVED***'

    # Получить список работников указанного отдела
    @users = UserIss
               .select(:id_tn, :fio)
               .where(dept: params[:division])
               .where('tn < 100000')

    data = {
      workplaces: @workplaces,
      users:      @users
    }

    render json: data, status: :ok
  end

  protected

  # Преобразовать объект InvType в специальный массив вида:
  # [
  #   {
  #     name: 'monitor',
  #     short_descr: 'монитор',
  #     ...
  #
  #     property_attrs: [
  #       {
  #         name: 'diagonal',
  #         descr: 'Диагональ',
  #         type: list,
  #       },
  #       ...
  #     ]
  #   },
  #   { ... }
  # ]
  def transform(types)
    # Выходной массив
    res_arr = []

    types.each do |type|
      index = res_arr.index { |hash| hash[:name] == type['name'] }

      # Хэш со свойством текущего типа оборудования
      prop = {
        property_id:    type.property_id,
        name:           type.prop_name,
        short_descr:    type.prop_short_descr,
        order:          type.property_order,
        type:           type.property_type,
        mandatory:      type.mandatory,
        multiple:       type.multiple,
        uniq:           type.uniq
      }

      # Если тип оборудования уже есть в массиве res_arr (индекс найден), то добавить к типу новое свойство
      # Иначе добавить новый тип в массив
      if index
        res_arr[index][:property_attrs].push(prop)
      else
        res_arr.push(
          {
            type_id:        type.type_id,
            name:           type.name,
            short_descr:    type.type_short_descr,
            property_attrs: [prop]
          }
        )
      end
    end

    res_arr
  end
end
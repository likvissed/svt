class Warehouse::ApplicationService < ApplicationService;
  protected

  # Подготовить технику для редактирования
  def prepare_to_edit_item(item)
    item['property_values_attributes'] = item['property_values']

    item.delete('property_values')
    item.delete('inv_type')

    item['property_values_attributes'].each do |prop_val|
      prop_val['id'] = prop_val['warehouse_property_value_id']

      prop_val.delete('property') if prop_val['property'].present?
      prop_val.delete('warehouse_property_value_id')
    end
  end
end

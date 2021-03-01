module Invent
  # Проверка на валидность создаваемой модели
  shared_examples ':wrong_rm_pk_composition error' do
    it 'includes :wrong_rm_pk_composition error' do
      subject.valid?
      expect(subject.errors.details[:base].any? { |hash| hash[:error] == :wrong_rm_pk_composition })
        .to be_truthy
    end
  end

  shared_examples ':wrong_rm_mob_composition error' do
    it 'includes :wrong_rm_mob_composition error' do
      subject.valid?
      expect(subject.errors.details[:base].any? { |hash| hash[:error] == :wrong_rm_mob_composition })
        .to be_truthy
    end
  end

  shared_examples ':wrong_rm_net_print_composition error' do
    it 'includes :wrong_rm_net_print_composition error' do
      subject.valid?
      expect(subject.errors.details[:base].any? { |hash| hash[:error] == :wrong_rm_net_print_composition })
        .to be_truthy
    end
  end

  shared_examples ':wrong_rm_server_composition error' do
    it 'includes :wrong_rm_server_composition error' do
      subject.valid?
      expect(subject.errors.details[:base].any? { |hash| hash[:error] == :wrong_rm_server_composition })
        .to be_truthy
    end
  end

  shared_examples 'includes error' do |error_name|
    it "includes the :#{error_name} error" do
      subject.valid?
      expect(subject.errors.details[:base].any? { |hash| hash[:error] == error_name.to_sym }).to be_truthy
    end
  end

  shared_examples 'property_value is creating' do
    let(:property_with_assign_barcode) { Invent::Property.where(assign_barcode: true).pluck(:property_id) }
    let(:new_item) do
      item = build(:item, :with_property_values, type_name: :printer)
      item_json = item.as_json
      item_json['barcode_item_attributes'] = {}
      item_json['property_values_attributes'] = Array.wrap(item.property_values.as_json)
      item_json['property_values_attributes'].each do |prop_val|
        prop_val['value'] = '' if property_with_assign_barcode.include?(prop_val['property_id'])
      end
      item_json
    end

    it 'not all created property_values' do
      sent_property_value = new_item['property_values_attributes'].find do |prop_val|
        property_with_assign_barcode.include?(prop_val['property_id'])
      end

      subject.run

      new_item['property_values_attributes'].each do |prop_val|
        expect(sent_property_value['property_id']).not_to eq prop_val['property_id']
      end
    end
  end
end

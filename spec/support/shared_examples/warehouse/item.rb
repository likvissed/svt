module Warehouse
  shared_examples 'field is not blank' do
    it 'key property_values_attributes is not blank' do
      subject.run

      expect(subject.data[:item]['property_values_attributes']).not_to be_empty
    end
  end

  shared_examples 'check key prop_data' do
    %w[mb ram video cpu hdd].each do |value|
      it "key file_depending includes '#{value}'" do
        subject.run

        expect(subject.data[:prop_data][:file_depending]).to include(value)
      end
    end

    %w[type network_connection activation_key].each do |value|
      it "key name for properties not includes '#{value}'" do
        subject.run

        subject.data[:prop_data][:eq_types]['properties'].each do |prop|
          expect(prop['name']).not_to eq(value)
        end
      end
    end
  end

  shared_examples 'calls service Invent::LkInvents::InitProperties' do
    it 'receive :load_types for Invent::LkInvents::InitProperties service' do
      expect_any_instance_of(Invent::LkInvents::InitProperties).to receive(:load_types)

      subject.run
    end

    it 'receive :prepare_eq_types_to_render for Invent::LkInvents::InitProperties service' do
      expect_any_instance_of(Invent::LkInvents::InitProperties).to receive(:prepare_eq_types_to_render)

      subject.run
    end
  end

  shared_examples 'value for keys :file_depending and :type_with_files' do
    let(:constant_property) { Invent::Property::FILE_DEPENDING }
    let(:constant_type) { Invent::Type::TYPE_WITH_FILES }

    it 'sets attribute file_depending value of constant' do
      subject.run

      expect(subject.data[:prop_data][:file_depending]).to eq(constant_property)
    end

    it 'sets attribute type_with_files value of constant' do
      subject.run

      expect(subject.data[:prop_data][:type_with_files]).to eq(constant_type)
    end
  end

  shared_examples 'add new property_value' do
    let(:value) { 'ConfigMgr Remote Control Driver' }
    let(:param_property_value) { { property_id: property.find_by(name: 'video').property_id, value: value } }

    it 'add record of PropertyValue' do
      subject.run

      expect(PropertyValue.where(warehouse_item_id: item.id).find_by(value: param_property_value[:value])).to be_truthy
    end

    it 'add new PropertyValue with property video' do
      subject.run

      expect(PropertyValue.where(warehouse_item_id: item.id).find_by(value: param_property_value[:value]).value).to eq(value)
    end

    it 'increments count of PropertyValue' do
      expect { subject.run }.to change { PropertyValue.count }.by(1)
    end
  end

  shared_examples 'property_value invalid' do
    context 'absent value property_id in property_value' do
      let(:param_property_value) { { property_id: nil, value: 'HP 2100' } }

      its(:run) { is_expected.to be_falsey }
    end
  end

  shared_examples 'add a location in item' do
    it 'assign present location for item' do
      subject.run

      expect(item.reload.location_id).to eq location.id
    end
  end

  shared_examples 'update :invent_num_start and :invent_num_end for items' do
    it 'assign new invent_num_start and invent_num_end for items' do
      subject.run

      expect(Item.first.invent_num_start).to eq item.invent_num_start
      expect(Item.first.invent_num_end).to eq item.invent_num_start + items_attributes.first['count_for_invent_num'] - 1

      expect(Item.last.invent_num_start).to eq Item.first.invent_num_end + 1
      expect(Item.last.invent_num_end).to eq Item.first.invent_num_end + items_attributes.last['count_for_invent_num']
    end
  end

  shared_examples 'update :count for items' do
    it 'assign new count for items' do
      subject.run

      expect(Item.first.count).to eq items_attributes.first['count_for_invent_num']
      expect(Item.last.count).to eq items_attributes.last['count_for_invent_num']
    end
  end
end

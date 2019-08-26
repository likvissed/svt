module Invent
  shared_examples 'includes field property_list_not_fixed' do
    it 'includes key :property_list_not_fixed' do
      subject.run

      expect(subject.data).to include(:property_list_not_fixed)
    end

    it 'attribute :property_list_id match of PropertyList' do
      subject.run

      expect(subject.data[:property_list_not_fixed].property_list_id).to eq PropertyList.find_by(value: 'not_fixed').property_list_id
    end
  end
end

module Warehouse
  shared_examples 'fields is not blank' do
    it 'field :property_values_attributes is not blank' do
      subject.run

      expect(subject.data[:property_values_attributes]).not_to be_empty
    end

    it 'field :type is not blank' do
      subject.run

      expect(subject.data[:type][:properties]).not_to be_empty
    end
  end
end

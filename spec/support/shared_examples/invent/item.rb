module Invent
  shared_examples 'for #get_value specs' do
    context 'and when property is Integer' do
      it 'returns value from the property_value table' do
        expect(subject.get_value(property.property_id)).to eq expected_value
      end
    end

    context 'and when property is instance of Property class' do
      it 'returns value from the property_value table' do
        expect(subject.get_value(property)).to eq expected_value
      end
    end
  end
end
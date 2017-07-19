module Invent
  # Проверка на валидность создаваемой модели
  shared_examples 'item_valid_model' do
    it 'should be valid' do
      expect(item).to be_valid
    end
  end

  # Проверка на невалидность создаваемой модели
  shared_examples 'item_not_valid_model' do
    it 'should not be valid' do
      expect(item).not_to be_valid
    end
  end
end

module Inventory
  # Проверка на валидность создаваемой модели
  RSpec.shared_examples "workplace_valid_model" do
    it "should be valid" do
      expect(workplace).to be_valid
    end
  end

# Проверка на невалидность создаваемой модели
  RSpec.shared_examples "workplace_not_valid_model" do
    it "should not be valid" do
      expect(workplace).not_to be_valid
    end
  end
end
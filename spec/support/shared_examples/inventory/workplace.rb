module Inventory
  # Проверка на валидность создаваемой модели
  shared_examples ':wrong_rm_pk_composition error' do
    it 'includes :wrong_rm_pk_composition error' do
      expect(subject.errors.details[:base].any? { |hash| hash[:error] == :wrong_rm_pk_composition })
        .to be_truthy
    end
  end

  shared_examples ':wrong_rm_mob_composition error' do
    it 'includes :wrong_rm_mob_composition error' do
      expect(subject.errors.details[:base].any? { |hash| hash[:error] == :wrong_rm_mob_composition })
        .to be_truthy
    end
  end

  shared_examples ':wrong_rm_net_print_composition error' do
    it 'includes :wrong_rm_net_print_composition error' do
      expect(subject.errors.details[:base].any? { |hash| hash[:error] == :wrong_rm_net_print_composition })
        .to be_truthy
    end
  end

  shared_examples ':wrong_rm_server_composition error' do
    it 'includes :wrong_rm_server_composition error' do
      expect(subject.errors.details[:base].any? { |hash| hash[:error] == :wrong_rm_server_composition })
        .to be_truthy
    end
  end

  shared_examples 'includes error' do |error_name|
    it "includes the :#{error_name} error" do
      expect(subject.errors.details[:base].any? { |hash| hash[:error] == error_name.to_sym }).to be_truthy
    end
  end

end

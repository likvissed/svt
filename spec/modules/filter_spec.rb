require 'feature_helper'

describe 'Filter' do
  subject do
    Class.new(ApplicationRecord) do
      extend Filter
      self.abstract_class = true

      scope :filter_1, ->(param) {}
    end
  end

  describe '#filter' do
    context 'when params is empty' do
      it 'returns ActiveRecord::Relation' do
        allow(subject).to receive(:where).and_return(subject.none)
        expect(subject.filter).to be_kind_of(ActiveRecord::Relation)
      end
    end

    context 'when params exists' do
      let(:param) { { filter_1: 'value_1' } }
      let(:relation) { subject.all }

      it 'runs method defined in key with param defined iv value' do
        allow(subject).to receive(:where).and_return(relation)
        expect(relation).to receive(:filter_1).with(param[:filter_1])
        subject.filter(param)
      end
    end
  end
end

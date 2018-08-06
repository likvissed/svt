require 'feature_helper'

describe 'Filter' do
  subject do
    Class.new(ApplicationRecord) do
      extend Filter
      self.abstract_class = true

      scope :filter_1, -> (param) {}
    end
  end

  describe '#filter' do
    context 'when filter value has String or Fixnum type' do
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

    context 'when filter value has Array type' do
      let(:param) { { filter_1: [{ value_1: 1 }, { value_2: 2 }] } }
      let(:relation) { subject.all }

      it 'runs filter as many times as many elements in array with corresponding params' do
        allow(subject).to receive(:where).and_return(relation)
        param[:filter_1].each do |val|
          allow(relation).to receive(:filter_1).and_return(relation)
          expect(relation).to receive(:filter_1).with(val)
          subject.filter(param)
        end
      end
    end
  end
end
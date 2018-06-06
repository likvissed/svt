require 'feature_helper'

module Invent
  module Workplaces
    RSpec.describe Edit, type: :model do
      let(:user) { create(:user) }
      let(:workplace_count) { create(:active_workplace_count, users: [user]) }
      let!(:workplace) do
        create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
      end
      subject { Edit.new(user, workplace.workplace_id) }

      describe 'format html' do
        context 'when workplace is found' do
          it 'fills the @data with founded workplace object' do
            subject.run :html
            expect(subject.data).to eq workplace
          end
          it { expect(subject.run(:html)).to be_truthy }
        end

        context 'when workplace is not found' do
          subject { Edit.new(user, 0) }

          it 'raises RecordNotFound error' do
            expect { subject.run :html }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end

      describe 'format json' do
        it 'fills the @data with %w[wp_data prop_data] keys' do
          subject.run :json
          expect(subject.data).to include(:wp_data, :prop_data)
        end
      end

      describe 'another format' do
        it { expect(subject.run(:xml)).to be_falsey }
      end
    end
  end
end

require 'feature_helper'

module Invent
  module Workplaces
    RSpec.describe ListWp, type: :model do
      let(:user) { create(:user) }
      let(:workplace_count) { create(:active_workplace_count, users: [user]) }
      let(:workplace_count_***REMOVED***) { create(:active_workplace_count, division: ***REMOVED***, users: [user]) }
      let!(:workplace) do
        create(
          :workplace_pk,
          :add_items,
          items: [:pc, monitor: [diagonal: { property_list: nil, value: 'Manually diagonal' }]],
          workplace_count: workplace_count
        )
      end
      let!(:workplace_***REMOVED***) { create(:workplace_mob, :add_items, items: %i[notebook], status: :confirmed, workplace_count: workplace_count_***REMOVED***) }
      let(:params) { { start: 0, length: 25 } }
      subject { ListWp.new(user, params) }
      before { subject.run }

      it { is_expected.to be_truthy }

      context 'when there are many workplaces' do
        let!(:workplace_***REMOVED***) { create_list(:workplace_mob, 30, :add_items, items: %i[notebook], status: :confirmed, workplace_count: workplace_count_***REMOVED***) }

        it 'loads workplaces specified into length param' do
          expect(subject.data[:data].count).to eq params[:length]
        end
      end

      it 'adds %i[workplace_id workplace items] fields' do
        expect(subject.data[:data].first).to include(:workplace_id, :workplace, :items)
      end

      context 'with init_filters' do
        subject do
          params[:init_filters] = 'true'
          ListWp.new(user, params)
        end

        it 'assigns %i[divisions statuses types buildings] to the :filters key' do
          expect(subject.data[:filters]).to include(:divisions, :statuses, :types, :buildings)
        end

        it 'loads site for corresponding room' do
          expect(subject.data[:filters][:buildings].first[:site_name]).to eq IssReferenceBuilding.first.iss_reference_site.name
        end

        its(:run) { is_expected.to be_truthy }
      end

      # it 'wraps the values entered manually with <span class=\'manually\'></span> tag' do
      #   expect(subject.data[:workplaces].first[:items].last).to match(%r{<span class='manually-val'>Модель: #{workplace.items.first.item_model}</span>})
      #   expect(subject.data[:workplaces].first[:items].last).to match(%r{<span class='manually-val'>Диагональ экрана: Manually diagonal</span>})
      # end

      context 'when user_iss was fired' do
        let!(:workplace) do
          build(
            :workplace_pk,
            :add_items,
            items: [:pc, monitor: [diagonal: { property_list: nil, value: 'Manually diagonal' }]],
            id_tn: '382_121_111',
            workplace_count: workplace_count
          ).save(validate: false)
        end

        it 'adds "Ответственный не найден" string and wraps it with <span class=\'manually\'></span> tag' do
          expect(subject.data[:data].last[:workplace]).to match(%r{<span class='manually-val'>Ответственный не найден</span>})
        end
      end
    end
  end
end

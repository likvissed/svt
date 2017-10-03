require 'spec_helper'

module Invent
  module LkInvents
    RSpec.describe ShowDivisionData, type: :model do
      let(:user) { build :user }
      let(:workplace_count) { create(:active_workplace_count, users: [user]) }
      let!(:workplace) do
        create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
      end

      subject { ShowDivisionData.new(user,workplace_count.division) }

      include_examples 'run methods', %w[load_workplace load_users]

      context 'when @data is filling' do
        let!(:data_keys) { %i[workplaces users] }
        before { subject.run }

        it 'fills the @data with %i[workplaces users] keys' do
          expect(subject.data.keys).to include *data_keys
        end

        it 'puts the :workplaces at least with %w[short_description fio duty location status] keys' do
          expect(subject.data[:workplaces].first).to include(
            'short_description', 'fio', 'duty', 'location', 'status'
          )
        end

        it 'puts the :users at least with %w[id_tn fio] keys' do
          expect(subject.data[:users].first.as_json).to include('id_tn', 'fio')
        end

        context 'and when responsible user was dismissed' do
          let(:dismissed_user) { build :invalid_user }
          let!(:workplace) do
            w = build :workplace_pk,
                      :add_items,
                      items: %i[pc monitor],
                      workplace_count: workplace_count,
                      id_tn: dismissed_user.id_tn
            w.save(validate: false)
            w
          end

          it 'must add "Ответственный не найден" to the fio field' do
            expect(subject.data[:workplaces].first['fio']).to match 'Ответственный не найден'
          end
        end
      end
    end
  end
end

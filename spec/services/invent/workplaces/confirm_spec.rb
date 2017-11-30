module Invent
  module Workplaces
    RSpec.describe Confirm, type: :model do
      let(:user) { create(:user) }
      let(:workplace_count) { create(:active_workplace_count, users: [user]) }
      let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count) }
      let(:type) { 'confirm' }
      subject { Confirm.new(type, [workplace.workplace_id]) }

      context 'with valid type' do
        context 'with "confirm" type' do
          it 'sets "confirmed" status' do
            subject.run
            workplace.reload
            expect(workplace.status).to eq 'confirmed'
          end

          it 'set description to the @data variable' do
            subject.run
            expect(subject.data).to eq 'Данные подтверждены'
          end

          its(:run) { is_expected.to be_truthy }
        end

        context 'with "disapprove" type' do
          let(:type) { 'disapprove' }

          it 'sets "disapprove" status' do
            subject.run
            workplace.reload
            expect(workplace.status).to eq 'disapproved'
          end

          it 'set description to the @data variable' do
            subject.run
            expect(subject.data).to eq 'Данные отклонены'
          end

          its(:run) { is_expected.to be_truthy }
        end
      end

      context 'with invalid type' do
        let(:type) { 'invalid' }

        it 'adds :unknown_action error' do
          subject.run
          expect(subject.errors.details[:base]).to include(error: :unknown_action)
        end

        its(:run) { is_expected.to be_falsey }
      end

      # FIXME: Тест не работает. Нужно застабить локальную переменную errors_arr
      # context 'when workplace was not updated' do
      #   let!(:workplace) do
      #      wp = build(:workplace_pk, :add_items, items: %i[pc monitor], id_tn: '382_111', workplace_count: workplace_count)
      #      wp.save(validate: false)
      #      wp
      #   end
      #   let(:workplaces) { Workplace.all }
      #   before do
      #     allow(Workplace).to receive(:where).and_return(workplaces)
      #     workplaces.each do |wp|
      #       allow(wp).to receive(:status).and_return(false)
      #     end

      #     # expect(workplaces.first).to receive(:update_attribute).with('status', :confirmed).and_return(true)
      #   end

      #   it 'adds :error_update_status error' do
      #     subject.run
      #     puts subject.errors.details
      #   end
      # end
    end
  end
end

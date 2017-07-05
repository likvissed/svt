module Inventory
  module Workplaces
    RSpec.describe Confirm, type: :model do
      let(:user) { create :user }
      let(:workplace_count) { create :active_workplace_count, users: [user] }
      let!(:workplace) { create :workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count }
      subject { Confirm.new(type, [workplace.workplace_id]) }
      
      context 'with valid type' do
        context 'with "confirm" type' do
          let(:type) { 'confirm' }
          
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
        
        it 'adds error message to the service' do
          subject.run
          puts subject.errors.full_messages.inspect
          expect(subject.errors.full_messages.first).to eq 'Указанное действие неразрешено'
        end
        
        its(:run) { is_expected.to be_falsey }
      end
    end
  end
end
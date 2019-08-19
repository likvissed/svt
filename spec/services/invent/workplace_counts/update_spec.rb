require 'feature_helper'

module Invent
  module WorkplaceCounts
    RSpec.describe Update, type: :model do
      let!(:current_user) { create(:user) }
      let(:new_user) { build(:***REMOVED***_user) }
      let(:workplace_count) do
        wc = build(:active_workplace_count)
        wc.save(validate: false)
        wc.as_json
      end
      before do
        workplace_count[:user_ids] = []
        workplace_count[:users_attributes] = [new_user.as_json.symbolize_keys]
      end
      subject { Update.new(current_user, workplace_count['workplace_count_id'], workplace_count) }

      describe '#run' do
        context 'with valid workplace_count params' do
          it 'increments count of User' do
            expect { subject.run }.to change { User.count }.by(1)
          end

          it 'returns true' do
            expect(subject.run).to be true
          end
        end

        context 'when updates params workplace_count' do
          let(:division) { 777 }
          let(:time_start) { '2017-01-02' }
          let(:time_end) { '2022-05-09' }

          %w[division time_start time_end].each do |attr|
            before { workplace_count[attr] = send(attr) }

            it "update params '#{attr}'" do
              subject.run

              expect(workplace_count[attr]).to eq send(attr)
            end
          end
        end

        context 'when tn does not exist' do
          before { allow_any_instance_of(User).to receive(:tn).and_return(1) }

          it 'returns with error :user_not_found' do
            subject.run

            expect(subject.error).to include(full_message: 'Табельный номер "1" не существует, проверьте корректность введенного номера')
          end

          it 'returns false' do
            expect(subject.run).to be false
          end
        end

        context 'when adds new user' do
          include_examples 'user phone is changing'
        end

        context 'when adds present user' do
          let(:new_user) { create(:***REMOVED***_user) }

          include_examples 'user phone is changing'
        end
      end
    end
  end
end

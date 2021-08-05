require 'feature_helper'

module Invent
  module WorkplaceCounts
    RSpec.describe Update, type: :model do
      skip_users_reference

      let(:emp_user) { build(:emp_***REMOVED***) }
      let(:result_user_reference) { emp_user }

      let!(:current_user) { create(:user) }
      let(:new_user) { build(:***REMOVED***_user) }
      let(:workplace_count) do
        wc = build(:active_workplace_count)
        wc.save(validate: false)
        wc.as_json
      end
      before do
        allow_any_instance_of(Update).to receive(:find_user_reference).and_return(result_user_reference)

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
          let(:add_error_subject) do
            sub = subject
            sub.errors.details[:tn] = [{ error: :user_not_found, tn: 1 }]
            sub
          end

          it 'returns with error :user_not_found' do
            allow(subject).to receive(:run).and_return(add_error_subject)

            expect(subject.errors.details[:tn]).to include(error: :user_not_found, tn: 1)
          end

          it 'returns false' do
            allow(subject).to receive(:run).and_return(false)

            expect(subject.run).to be false
          end
        end

        context 'when adds new user' do
          context 'and when assigned a new role to user' do
            let(:role_id) { Role.find_by(name: '***REMOVED***_user').id }
            let(:user) { User.find_by(tn: new_user.tn) }

            it 'change the role as :***REMOVED***_user' do
              subject.run

              expect(user.role_id).to eq role_id
            end
          end

          include_examples 'user phone is changing'
        end

        context 'when adds present user' do
          let(:role_id) { Role.find_by(name: 'admin').id }
          let(:new_user) { create(:***REMOVED***_user, role_id: role_id) }

          context 'and when assigned an existing role to user' do
            before { workplace_count[:users_attributes].first[:id] = nil }

            it 'change the role as :admin' do
              subject.run

              expect(new_user.role_id).to eq role_id
            end
          end

          include_examples 'user phone is changing'
        end
      end
    end
  end
end

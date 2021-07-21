require 'feature_helper'

module Invent
  module LkInvents
    RSpec.describe InitProperties, type: :model do
      skip_users_reference

      let(:user) { build(:user) }

      context 'with current_user' do
        let!(:workplace_count) { create(:active_workplace_count, users: [user]) }
        subject { InitProperties.new(user) }

        include_examples 'run methods', %w[load_divisions load_types load_workplace_types load_workplace_specializations load_locations prepare_eq_types_to_render load_constants load_security_categories]

        its(:data) { is_expected.not_to be_nil }

        it 'does not exclude fields with mandatory=false property' do
          subject.run
          expect(subject.data[:eq_types].find { |type| type['name'] == 'printer' }['properties'].count)
            .to eq Type.find_by(name: :printer).properties.count
        end

        context 'when @data is filling' do
          let!(:data_keys) { %i[divisions eq_types wp_types specs iss_locations statuses move_item_types file_depending date_props single_pc_items type_with_files message_for_security_category] }
          before { subject.run }

          it 'fills the @data hash with %i[divisions eq_types wp_types specs iss_locations statuses move_item_types file_depending date_props single_pc_items type_with_files message_for_security_category] keys' do
            expect(subject.data.keys).to include(*data_keys)
          end

          it 'puts the :divisions at least with %w[workplace_count_id division allowed_time] keys' do
            expect(subject.data[:divisions].first.keys).to include(
              'workplace_count_id', 'division', 'allowed_time'
            )
          end

          it 'puts the Property::FILE_DEPENDING array into the :file_depending key' do
            expect(subject.data[:file_depending]).to eq Property::FILE_DEPENDING
          end

          it 'puts the Type::SINGLE_PC_ITEMS array into the :single_pc_items key' do
            expect(subject.data[:single_pc_items]).to eq Type::SINGLE_PC_ITEMS
          end

          it 'puts the Type::TYPE_WITH_FILES array into the :type_with_files key' do
            expect(subject.data[:type_with_files]).to eq Type::TYPE_WITH_FILES
          end

          it 'puts the Type::SECURITY_ROOM array into the :message_for_security_category key' do
            expect(subject.data[:message_for_security_category]).to eq WorkplaceType::SECURITY_ROOM
          end

          it_behaves_like '@data into init_properties_service is filleable'
        end
      end

      context 'with division' do
        subject { InitProperties.new(nil, user.division) }

        its(:data) { is_expected.not_to be_nil }

        context 'when @data is filling' do
          let(:result_subject) do
            sub = subject
            sub.data[:users] = [build(:emp_***REMOVED***)]
            sub
          end
          let!(:data_keys) { %i[eq_types wp_types specs iss_locations users rooms_security_categories] }
          before do
            allow_any_instance_of(BaseService).to receive(:load_users).and_return(result_subject)
            subject.run
          end

          it 'fills the @data hash with %i[divisions eq_types wp_types specs iss_locations rooms_security_categories] keys' do
            expect(subject.data.keys).to include(*data_keys)
          end

          it_behaves_like '@data into init_properties_service is filleable'

          it 'puts the :users at least with %w[lastName firstName middleName id professionForDocuments fullName] keys' do
            expect(subject.data[:users].first.as_json.keys).to include('lastName', 'firstName', 'middleName', 'id', 'professionForDocuments', 'fullName')
          end
        end
      end
    end
  end
end

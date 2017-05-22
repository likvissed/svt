require 'spec_helper'

module Inventory
  module LkInvents
    RSpec.describe InitProperties, type: :model do
      let(:user) { build(:user) }

      context 'with id_tn' do
        let!(:workplace_count) { create(:active_workplace_count, user: user) }
        subject { InitProperties.new(user.id_tn) }

        %w[load_divisions load_inv_types load_workplace_types load_workplace_specializations load_locations exclude_mandatory_fields].each do |method|
          it "runs #{method} method" do
            expect(subject).to receive(method.to_sym)
            subject.run
          end
        end

        its(:data) { is_expected.not_to be_nil }

        context 'when @data is filling' do
          let!(:data_keys) { %i[divisions eq_types wp_types specs iss_locations] }
          before { subject.run }

          it 'fills the @data hash with %i[divisions eq_types wp_types specs iss_locations] keys' do
            expect(subject.data.keys).to include *data_keys
          end

          it 'puts the :divisions at least with %w[workplace_count_id division allowed_time] keys' do
            expect(subject.data[:divisions].first.keys).to include(
              'workplace_count_id', 'division', 'allowed_time'
            )
          end

          it_behaves_like '@data into init_properties_service is filleable'
        end

        context 'when service runs with "mandatory: true"' do
          it 'does not run exclude_mandatory_fields method' do
            expect(subject).not_to receive(:exclude_mandatory_fields)
            subject.run(true)
          end
        end
      end

      context 'with division' do
        subject { InitProperties.new(nil, user.division) }

        its(:data) { is_expected.not_to be_nil }

        context 'when @data is filling' do
          let!(:data_keys) { %i[eq_types wp_types specs iss_locations users] }
          before { subject.run }

          it 'fills the @data hash with %i[divisions eq_types wp_types specs iss_locations] keys' do
            expect(subject.data.keys).to include *data_keys
          end

          it_behaves_like '@data into init_properties_service is filleable'

          it 'puts the :users at least with %w[id_tn fio] keys' do
            expect(subject.data[:users].first.as_json.keys).to include('id_tn', 'fio')
          end
        end
      end
    end
  end
end

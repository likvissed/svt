require 'feature_helper'

module Warehouse
  module Requests
    RSpec.describe Index, type: :model do
      skip_users_reference

      let(:current_user) { create(:user) }
      let!(:params) { { start: 0, length: 25 } }
      let!(:requests) { create_list(:request_category_one, 25) }

      subject { Index.new(current_user, params) }

      it 'includes :recordsTotal, :recordsFiltered and :filters fields' do
        subject.run

        expect(subject.data).to include(:recordsTotal, :recordsFiltered, :filters)
      end

      it 'includes attributes for request' do
        subject.run

        %w[category user_tn user_id_tn user_fio user_dept user_phone number_***REMOVED*** number_***REMOVED*** executor_fio executor_tn comment status
           request_items attachments status_translated category_translate].each do |i|
          expect(subject.data[:data].last.key?(i)).to be_truthy
        end
      end

      it 'category for request is present' do
        subject.run

        expect(subject.data[:data].last['category']).to eq('office_equipment')
      end
    end
  end
end

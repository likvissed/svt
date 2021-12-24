require 'feature_helper'

module Warehouse
  module Requests
    RSpec.describe Index, type: :model do
      skip_users_reference

      let(:current_user) { create(:user) }
      let!(:params) { { start: 0, length: 25 } }
      let!(:requests) { create_list(:request_category_one, 25) }

      subject { Index.new(current_user, params) }
      before { subject.run }

      it 'includes :recordsTotal and :recordsFiltered fields' do
        expect(subject.data).to include(:data, :recordsTotal, :recordsFiltered)
      end

      it 'includes attributes for request' do
        %w[category user_tn user_id_tn user_fio user_dept user_phone number_***REMOVED*** number_***REMOVED*** executor_fio executor_tn comment status
           request_items attachments label_status category_translate].each do |i|
          expect(subject.data[:data].last.key?(i)).to be_truthy
        end
      end

      it 'category for request is present' do
        expect(subject.data[:data].last['category']).to eq('office_equipment')
      end

      context 'with init_filters' do
        subject do
          params[:init_filters] = 'true'
          Index.new(current_user, params)
        end

        it 'assigns %i[divisions statuses] to the :filters key' do
          expect(subject.data[:filters]).to include(:categories, :statuses)
        end
      end
    end
  end
end

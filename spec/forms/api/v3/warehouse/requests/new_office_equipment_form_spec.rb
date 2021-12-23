require 'feature_helper'

module Api
  module V3
    module Warehouse
      module Requests
        RSpec.describe NewOfficeEquipmentForm, type: :model do
          subject { described_class.new(::Warehouse::Request.new) }

          describe 'validations' do
            it { is_expected.to validate_presence_of(:number_***REMOVED***) }
            it { is_expected.to validate_presence_of(:number_***REMOVED***) }
            it { is_expected.to validate_presence_of(:status) }
            it { is_expected.to validate_presence_of(:category) }

            it { is_expected.to validate_presence_of(:user_tn) }
            it { is_expected.to validate_presence_of(:user_fio) }
            it { is_expected.to validate_presence_of(:user_dept) }
          end
        end
      end
    end
  end
end

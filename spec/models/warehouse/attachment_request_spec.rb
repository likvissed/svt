require 'feature_helper'

module Warehouse
  RSpec.describe AttachmentRequest, type: :model do
    it { is_expected.to belong_to(:request).with_foreign_key('request_id').inverse_of(:attachments) }
  end
end

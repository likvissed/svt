require 'feature_helper'

module Warehouse
  RSpec.describe Request, type: :model do
    it { is_expected.to have_many(:attachments).with_foreign_key('request_id').class_name('AttachmentRequest').dependent(:destroy).inverse_of(:request) }
    it { is_expected.to have_many(:request_items).with_foreign_key('request_id').dependent(:destroy).inverse_of(:request) }

    it { is_expected.to have_one(:order).with_foreign_key('request_id').inverse_of(:request).dependent(:nullify) }
  end
end

require 'feature_helper'

module Invent
  RSpec.describe Attachment, type: :model do
    it { is_expected.to belong_to(:workplace).with_foreign_key('workplace_id').inverse_of(:attachments) }
  end
end

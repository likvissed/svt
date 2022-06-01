require 'feature_helper'

RSpec.describe BindingSign, type: :model do
  it { is_expected.to belong_to(:bindable) }
  it { is_expected.to belong_to(:sign).class_name('Invent::Sign').with_foreign_key('invent_sign_id').required }

  it { is_expected.to validate_presence_of(:bindable_type) }
end

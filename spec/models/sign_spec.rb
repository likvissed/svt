require 'feature_helper'

RSpec.describe Sign, type: :model do
  it { is_expected.to have_many(:binders).class_name('Binder') }
end

require 'feature_helper'

module Invent
  RSpec.describe Sign, type: :model do
    it { is_expected.to have_many(:bindings).with_foreign_key('invent_sign_id').class_name('BindingSign') }
  end
end

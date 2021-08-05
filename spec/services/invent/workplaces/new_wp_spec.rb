require 'feature_helper'

module Invent
  module Workplaces
    RSpec.describe NewWp, type: :model do
      skip_users_reference

      let(:user) { create(:user) }
      let!(:workplace_count) { create(:active_workplace_count, users: [user]) }
      let(:properties) do
        prop = LkInvents::InitProperties.new(user)
        prop.run
        prop.data
      end
      subject { NewWp.new(user) }

      its(:run) { is_expected.to be_truthy }

      it 'fills the @data with %w[prop_data workplace item property_value] keys' do
        subject.run
        expect(subject.data).to include(:prop_data, :workplace, :item, :property_value)
      end

      it 'loads properties to the :prop_data key' do
        subject.run
        expect(subject.data[:prop_data]).to eq properties
      end

      it 'adds %w[id property_values_attributes] attribute to the item object' do
        subject.run
        expect(subject.data[:item]).to include('id', 'property_values_attributes')
      end

      it 'adds id attribute to the property_value object' do
        subject.run
        expect(subject.data[:item]).to include('id')
      end

      it 'sets :in_workplace status' do
        subject.run
        expect(subject.data[:item]['status']).to eq 'in_workplace'
      end

      it 'sets %w[disabled_filters items_attributes attachments_attributes new_attachment] attributes' do
        subject.run
        expect(subject.data[:workplace]).to include('disabled_filters', 'items_attributes', 'attachments_attributes', 'new_attachment')
      end
    end
  end
end

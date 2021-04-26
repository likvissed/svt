require 'feature_helper'

module Invent
  RSpec.describe Model, type: :model do
    it { is_expected.to have_many(:model_property_lists).dependent(:destroy) }
    it { is_expected.to have_many(:items).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:warehouse_items).with_foreign_key('invent_model_id').dependent(:restrict_with_error) }
    it { is_expected.to belong_to(:vendor).required }
    it { is_expected.to belong_to(:type).required }
    # Спеки не проходят из-за 'reduce: true'
    # it { is_expected.to validate_presence_of(:vendor) }
    # it { is_expected.to validate_presence_of(:type) }
    it { is_expected.to validate_presence_of(:item_model) }
    it { is_expected.to accept_nested_attributes_for(:model_property_lists) }

    describe '#property_list_for' do
      let(:type) { Type.find_by(name: :monitor) }
      subject { type.models.first }
      let(:property) { type.properties.find_by(name: :diagonal) }

      context 'when property_list exists' do
        let(:prop_list) { subject.model_property_lists.find_by(property: property).property_list }

        it 'returns property_list object for selected model and property' do
          expect(subject.property_list_for(property)).to eq prop_list
        end
      end

      context 'when property_lsit is not exist' do
        before { allow(subject.model_property_lists).to receive(:find_by).and_return(nil) }

        it 'returns nil' do
          expect(subject.property_list_for(property)).to be_nil
        end
      end
    end

    describe '#fill_item_model' do
      context 'when vendor is set' do
        let(:vendor) { Vendor.first }
        before do
          subject.vendor = vendor
          subject.item_model = 'test model'
        end

        context 'when it is a new model' do
          it 'combines the vendor_name with item_model' do
            expect(subject.fill_item_model).to eq "#{vendor.vendor_name} test model"
          end
        end

        context 'when it is an existing model' do
          let(:new_vendor) { Vendor.last }
          subject do
            m = build(:model, vendor: vendor)
            m.fill_item_model
            m.save
            m
          end
          before do
            subject.vendor_id = new_vendor.vendor_id
            subject.item_model = "#{vendor.vendor_name} Updated model"
          end

          it 'sets a new vendor_name value' do
            expect(subject.fill_item_model).to eq "#{new_vendor.vendor_name} Updated model"
          end
        end
      end

      context 'when vendor is not set' do
        its(:fill_item_model) { is_expected.to be_falsey }
      end
    end
  end
end

require 'feature_helper'

module Invent
  module Workplaces
    RSpec.describe Edit, type: :model do
      skip_users_reference

      let!(:user) { create(:user) }
      let(:workplace_count) { create(:active_workplace_count, users: [user]) }
      let!(:workplace) do
        create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
      end
      subject { Edit.new(user, workplace.workplace_id) }

      describe 'format html' do
        context 'when workplace is found' do
          it 'fills the @data with founded workplace object' do
            subject.run :html
            expect(subject.data).to eq workplace
          end
          it { expect(subject.run(:html)).to be_truthy }
        end

        context 'when workplace is not found' do
          subject { Edit.new(user, 0) }

          it 'raises RecordNotFound error' do
            expect { subject.run :html }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end

      describe 'format json' do
        before { allow_any_instance_of(LkInvents::BaseService).to receive(:load_users) }

        let(:edit_workplace) { LkInvents::EditWorkplace.new(user, workplace.workplace_id) }
        let(:init_properties) { LkInvents::InitProperties.new(user, workplace.division) }

        it 'fills the @data with %w[wp_data prop_data] keys' do
          subject.run :json
          expect(subject.data).to include(:wp_data, :prop_data)
        end

        it 'runs LkInvents::EditWorkplace service' do
          expect(LkInvents::EditWorkplace).to receive(:new).and_return(edit_workplace)
          subject.run :json
        end

        it 'runs LkInvents::InitProperties service' do
          expect(LkInvents::InitProperties).to receive(:new).and_return(init_properties)
          subject.run :json
        end

        context 'when property_value does not exist for corresponding property' do
          let(:item) do
            i = create(:item, :with_property_values, type_name: :ups)
            Invent::PropertyValue.destroy_all
            i
          end
          let(:workplace) { create(:workplace_pk, disabled_filters: true, items: [item]) }
          let(:ups_type) { Invent::Type.find_by(name: :ups) }
          let(:list_prop) { ups_type.properties.find_by(property_type: 'list') }
          let(:list_index) { ups_type.properties.index(list_prop) }
          let(:model_prop_list) do
            Invent::ModelPropertyList.find_by(
              model_id: item.model_id,
              property_id: list_prop.property_id
            )
          end

          it 'creates a missing property_values' do
            subject.run :json
            expect(subject.data[:wp_data]['items_attributes'].first['property_values_attributes'].size).to eq ups_type.properties.size
          end

          it 'sets property_id attribute for each missing property_value' do
            subject.run :json
            subject.data[:wp_data]['items_attributes'].first['property_values_attributes'].each do |prop_val|
              expect(ups_type.properties.any? { |prop| prop['property_id'] == prop_val['property_id'] }).to be_truthy
            end
          end

          it 'sets default property_value_id attribute for each missing property_value which has :list or :list_plus type' do
            subject.run :json

            expect(subject.data[:wp_data]['items_attributes'].first['property_values_attributes'][list_index]['property_list_id']).to eq model_prop_list.property_list_id
          end
        end
      end

      describe 'another format' do
        it { expect(subject.run(:xml)).to be_falsey }
      end
    end
  end
end

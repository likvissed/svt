require 'feature_helper'

module Invent
  module LkInvents
    RSpec.describe EditWorkplace, type: :model do
      let(:user) { create(:user) }

      context 'when workplace is found' do
        let(:workplace_count) { create(:active_workplace_count, users: [user]) }
        let!(:workplace) do
          create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
        end
        subject { EditWorkplace.new(user, workplace.workplace_id) }

        include_examples 'run methods', %w[load_workplace]

        context 'when @data is filling' do
          before { subject.run }

          it 'fills @data at least with %w[items_attributes attachments_attributes new_attachment] keys' do
            expect(subject.data).to include('items_attributes', 'attachments_attributes', 'new_attachment')
          end

          it 'fills each items_attribute at least with %w[warehouse_orders id property_values_attributes] keys' do
            subject.data['items_attributes'].each do |item|
              expect(item).to include('warehouse_orders', 'id', 'property_values_attributes', 'barcode_item_attributes')
            end
          end

          context 'and when workplace have attachment' do
            let(:attachment) { create(:attachment, workplace: workplace) }
            before { workplace.attachments = [attachment] }

            it 'fills each attachments_attributes with %w[id workplace_id filename document] keys' do
              subject.data['attachments_attributes'].each do |att|
                expect(att).to include('id', 'workplace_id', 'filename', 'document')
              end
            end
          end

          it 'fills each property_values_attribute at least with "id" key' do
            subject.data['items_attributes'].each do |item|
              item['property_values_attributes'].each do |prop_val|
                expect(prop_val).to include('id')
              end
            end
          end

          it 'fills each barcode_item_attributes keys from barcode' do
            subject.data['items_attributes'].each do |item|
              expect(item['barcode_item_attributes']).to include('id', 'codeable_id', 'codeable_type')
            end
          end
        end
      end

      context 'when workplace is not found' do
        subject { EditWorkplace.new(user, 0) }

        it 'raises RecordNotFound error' do
          expect { subject.run }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end

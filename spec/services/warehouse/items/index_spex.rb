require 'feature_helper'

module Warehouse
  module Items
    RSpec.describe Index, type: :model do
      let(:params) { { start: 0, length: 25, filters: {}.to_json } }
      let!(:item_1) { create(:used_item, count: 0, count_reserved: 0) }
      let!(:item_2) { create(:new_item, warehouse_type: :without_invent_num, count: 10) }
      let!(:items) { create_list(:used_item, 30) }
      subject { Index.new(params) }

      it 'loads items specified into length param' do
        subject.run
        expect(subject.data[:data].count).to eq params[:length]
      end

      it 'adds :translated_used field' do
        subject.run
        expect(subject.data[:data].first).to include('translated_used')
      end

      let(:operation) { build(:order_operation, item: items.first, shift: -1) }
      let!(:order) { create(:order, operation: :out, operations: [operation]) }
      it 'loads all :processing orders with :out operation' do
        subject.run
        expect(subject.data[:orders].count).to eq 1
      end

      it 'adds :main_info field to each order' do
        subject.run
        expect(subject.data[:orders].first).to include(:main_info)
      end

      context 'when sets init_filters attribute' do
        before { params[:init_filters] = 'true' }

        it 'loads all unique entries' do
          subject.run
          expect(subject.data[:filters][:item_types]).to eq Item.pluck(:item_type).uniq
        end
      end

      context 'when :showOnlyPresence filters is set' do
        before { params[:filters] = { showOnlyPresence: true }.to_json }

        it 'loads only records where count > count_reserved' do
          subject.run
          subject.data[:data].each do |i|
            expect(i['count']).to be > i['count_reserved']
          end
        end
      end

      context 'when :used filter is set' do
        context 'and when is equal "true"' do
          before { params[:filters] = { used: true }.to_json }

          it 'loads only records where used is true' do
            subject.run
            subject.data[:data].each do |i|
              expect(i['used']).to be_truthy
            end
          end
        end

        context 'and when is equal "false"' do
          before { params[:filters] = { used: false }.to_json }

          it 'loads only records where used is true' do
            subject.run
            subject.data[:data].each do |i|
              expect(i['used']).to be_falsey
            end
          end
        end

        context 'and when is equal "all"' do
          before { params[:filters] = { used: 'all' }.to_json }

          let(:truthy) { subject.data[:data].find { |i| i['used'] == true } }
          let(:falsey) { subject.data[:data].find { |i| i['used'] == false } }
          it 'loads all records' do
            subject.run
            expect(truthy).not_to be_empty
            expect(falsey).not_to be_empty
          end
        end
      end

      context 'when :item_type filter is set' do
        before { params[:filters] = { item_type: item_2.item_type }.to_json }

        it 'loads only records with specified item_type' do
          subject.run
          subject.data[:data].each do |i|
            expect(i['item_type']).to eq item_2.item_type
          end
        end
      end
    end
  end
end

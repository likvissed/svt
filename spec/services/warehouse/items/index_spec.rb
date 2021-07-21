require 'feature_helper'

module Warehouse
  module Items
    RSpec.describe Index, type: :model do
      skip_users_reference

      let(:params) { { start: '0', length: '25', filters: {}.to_json } }
      let!(:item_1) { create(:used_item, count: 0, count_reserved: 0) }
      let!(:items) { create_list(:used_item, 51) }
      let(:barcode) { 'qwerty12345' }
      let!(:item_2) { create(:new_item, warehouse_type: :without_invent_num, count: 10, barcode: barcode) }
      before { allow_any_instance_of(Order).to receive(:find_employee_by_workplace).and_return([build(:emp_***REMOVED***)]) }
      subject { Index.new(params) }

      context 'when items with location' do
        let(:location) { create(:location) }
        let!(:items) { create_list(:used_item, 25, location: location) }
        let(:site_name) { IssReferenceSite.find(location.site_id).name }
        let(:building_name) { IssReferenceBuilding.find(location.building_id).name }
        let(:room_name) { IssReferenceRoom.find(location.room_id).name }

        it 'name for location is present' do
          subject.run

          expect(subject.data[:data].last['location_name']).to eq "Пл. '#{site_name}', корп. #{building_name}, комн. #{room_name}"
        end

        it 'includes :inv_item, :supplies and :location fields' do
          subject.run

          expect(subject.data[:data].last).to include('inv_item', 'supplies', 'location')
        end
      end

      it 'name location is present' do
        subject.run

        expect(subject.data[:data].last['location_name']).to eq 'Не назначено'
      end

      it 'loads items specified into length param' do
        subject.run
        expect(subject.data[:data].count).to eq params[:length].to_i
      end

      it 'adds :translated_used field' do
        subject.run
        expect(subject.data[:data].first).to include('translated_status')
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

      context 'when :status filter is set' do
        let(:status) { :used }
        let(:status_translated) { Item.translate_enum(:status, status) }
        before { params[:filters] = { status: status }.to_json }

        it 'loads only records with specified status' do
          subject.run
          subject.data[:data].each do |i|
            expect(i['translated_status']).to match(/#{status_translated}/)
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

      context 'when :item_model filter is set' do
        before { params[:filters] = { item_model: item_2.item_model }.to_json }

        it 'loads only records with specified item_type' do
          subject.run
          subject.data[:data].each do |i|
            expect(i['item_model']).to eq item_2.item_model
          end
        end
      end

      context 'when :barcode filter is set' do
        before { params[:filters] = { barcode: barcode }.to_json }

        it 'loads only records with specified barcode' do
          subject.run
          subject.data[:data].each do |i|
            expect(i['barcode']).to eq barcode
          end
        end
      end

      context 'when invent_num filter is set' do
        before { params[:filters] = { invent_num: '76' }.to_json }

        it 'loads only records with specified barcode' do
          subject.run
          subject.data[:data].each do |i|
            expect(i['inv_item']['invent_num']).to match(/76/)
          end
        end
      end

      # context 'when invent_item_id filter is set' do
      #   before { params[:filters] = { invent_item_id: item_1.invent_item_id }.to_json }

      #   it 'loads only records with specified barcode' do
      #     subject.run
      #     subject.data[:data].each do |i|
      #       expect(i['invent_item_id']).to eq item_1.invent_item_id
      #     end
      #   end
      # end

      context 'when :selected_order_id is set' do
        context 'and when params[:start] is equal 0' do
          context 'and when items count of selected order more than params[:length] attribute' do
            30.times do |i|
              let(:"operation_#{i}") { build(:order_operation, item: Item.last(i + 1).first) }
            end
            let(:order) { build(:order, operation: :out, without_operations: true) }
            before do
              30.times do |i|
                order.operations << eval("operation_#{i}")
              end
              order.save
              params[:selected_order_id] = order.id
            end

            it 'loads only items which belongs to orders' do
              subject.run
              expect(subject.data[:data].any? { |i| order.items.any? { |oi| oi.id == i['id'] } }).to be_truthy
            end

            it 'loads items specified into length param' do
              subject.run
              expect(subject.data[:data].count).to eq params[:length].to_i
            end
          end

          context 'and when count of items of selected order less than params[:length] attribute' do
            let(:operation_1) { build(:order_operation, item: Item.first) }
            let(:operation_2) { build(:order_operation, item: Item.first(2).last) }
            let!(:order) { create(:order, operation: :out, operations: [operation_1, operation_2]) }
            before { params[:selected_order_id] = order.id }

            it 'loads at first all items which belongs to selected order' do
              subject.run
              subject.data[:data].each_with_index do |i, index|
                expect(i['id']).to eq order.items[index].id
                break if index == order.items.count - 1
              end
            end

            it 'loads other items (total count: params[:length] - order.items.count)' do
              subject.run
              expect(subject.data[:data].count).to eq params[:length].to_i
            end

            it 'does not load items that have already been loaded' do
              subject.run
              expect(subject.data[:data].uniq { |i| i['id'] }.count).to eq params[:length].to_i
            end
          end
        end

        context 'and when params[:start] is not equal 0' do
          context 'and when items count of selected order more than params[:length] attribute' do
            30.times do |i|
              let(:"operation_#{i}") { build(:order_operation, item: Item.last(i + 1).first) }
            end
            let(:order) { build(:order, operation: :out, without_operations: true) }
            before do
              30.times do |i|
                order.operations << eval("operation_#{i}")
              end
              order.save
              params[:start] = 25
              params[:selected_order_id] = order.id
            end

            let(:selected_order_items) { order.items.first(5) }
            it 'loads the remaining items which belongs to order' do
              subject.run
              expect(selected_order_items.any? { |oi| subject.data[:data].first(5).any? { |i| i['id'] == oi.id } }).to be_truthy
            end

            it 'loads other items' do
              subject.run
              expect(subject.data[:data].count).to eq params[:length].to_i
            end
          end

          context 'and when count of items of selected order less than params[:length] attribute' do
            let(:operation_1) { build(:order_operation, item: Item.first(30).last) }
            let(:operation_2) { build(:order_operation, item: Item.first(31).last) }
            let(:operation_3) { build(:order_operation, item: Item.first(32).last) }
            let(:operation_4) { build(:order_operation, item: Item.first(33).last) }
            let(:operation_5) { build(:order_operation, item: Item.first(34).last) }
            let!(:order) { create(:order, operation: :out, operations: [operation_1, operation_2, operation_3, operation_4, operation_5]) }
            before do
              params[:start] = 25
              params[:selected_order_id] = order.id
            end

            it 'does not load items which belongs to order by priority' do
              subject.run
              expect(subject.data[:data].any? { |i| order.items.any? { |oi| oi.id == i['id'] } }).to be_falsey
            end

            it 'loads items specified into length param' do
              subject.run
              expect(subject.data[:data].count).to eq params[:length].to_i
            end
          end
        end
      end
    end
  end
end

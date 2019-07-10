require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe Edit, type: :model do
      let(:order) { create(:order, :default_workplace) }

      context 'when :check_unreg flag is not set' do
        subject { Edit.new(order.id, false) }
        before { subject.run }

        its(:run) { is_expected.to be_truthy }

        it 'fills the @data with %i[order operation divisions eq_types] keys' do
          expect(subject.data).to include(:order, :operation, :divisions, :eq_types)
        end

        it 'adds "operations_attributes" field to order' do
          expect(subject.data[:order]).to include('operations_attributes')
        end

        it 'loads all operations attributes' do
          expect(subject.data[:order]['operations_attributes'].count).to eq order.operations.count
        end

        it 'loads inv_item_ids array for each operations attributes' do
          expect(subject.data[:order]['operations_attributes'].first['inv_item_ids']).to eq order.inv_items.pluck(:invent_item_id)
        end

        it 'adds full_item_model key' do
          expect(subject.data[:order]['operations_attributes'].first['inv_items'].first['full_item_model']).to eq order.operations.first.item.item_model
        end

        it 'loads type for each inv_item' do
          expect(subject.data[:order]['operations_attributes'].first['inv_items'].first['type']).to eq order.operations.first.item.inv_type.as_json
        end

        it 'adds consumer key' do
          expect(subject.data[:order]['consumer']).to eq subject.data[:order]['consumer_fio']
        end

        it 'adds fio_user_iss key' do
          expect(subject.data[:order]['fio_user_iss']).to eq order.inv_workplace.user_iss.fio
        end
      end

      context 'when :check_unreg flag is set' do
        subject { Edit.new(order.id, true) }

        it 'adds :unreg attribute' do
          subject.run
          expect(subject.data[:order]['operations_attributes'].first).to include('unreg')
        end

        context 'when host has unreg status' do
          let(:data) { { class: 4 }.as_json }
          before { allow(HostIss).to receive(:by_invent_num).and_return(data) }

          it 'sets "true" value to :unreg variable' do
            subject.run
            expect(subject.data[:order]['operations_attributes'].first['unreg']).to be_truthy
          end
        end

        context 'when host has reg status' do
          let(:data) { { class: 2 }.as_json }
          before { allow(HostIss).to receive(:by_invent_num).and_return(data) }

          it 'sets "false" value to :unreg variable' do
            subject.run
            expect(subject.data[:order]['operations_attributes'].first['unreg']).to be_falsey
          end
        end

        context 'when host is not found' do
          let(:data) { nil }
          before { allow(HostIss).to receive(:by_invent_num).and_return(data) }

          it 'sets nil value to :unreg variable' do
            subject.run
            expect(subject.data[:order]['operations_attributes'].first['unreg']).to be_nil
          end
        end

        context 'when inv_workplace absence' do
          let(:order) { create(:order) }

          it 'sets nil value to :fio_user_iss variable' do
            subject.run

            expect(subject.data[:order]['fio_user_iss']).to be_nil
          end
        end
      end
    end
  end
end

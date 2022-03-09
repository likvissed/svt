require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe Index, type: :model do
      skip_users_reference

      let!(:params) { { start: 0, length: 25 } }
      before do
        allow_any_instance_of(Order).to receive(:find_employee_by_workplace).and_return([build(:emp_***REMOVED***)])
        allow_any_instance_of(Order).to receive(:set_consumer_dept_in)
      end

      %i[in out].each do |op_type|
        context "when :operation attribute has :#{op_type} value" do
          let(:additional) { { operation: op_type, status: :processing } }
          let!(:orders) { create_list(:order, 30, operation: op_type) }
          subject { Index.new(params, additional) }

          it 'loads supplies specified into length param' do
            subject.run
            expect(subject.data[:data].count).to eq params[:length]
          end

          it 'loads order with :in operation' do
            subject.run
            expect(subject.data[:data].first['operation']).to eq op_type.to_s
          end

          it 'adds %w[status_translated operation_translated operations_to_string attachment_filename] fields' do
            subject.run
            expect(subject.data[:data].first).to include('status_translated', 'operation_translated', 'operations_to_string', 'attachment_filename')
          end

          context 'with init_filters' do
            subject do
              params[:init_filters] = 'true'
              Index.new(params, additional)
            end
            before { subject.run }

            it 'assigns %i[divisions operations item_types] to the :filters key' do
              expect(subject.data[:filters]).to include(:divisions, :operations, :item_types)
            end

            its(:run) { is_expected.to be_truthy }
          end

          context 'with init_filters' do
            subject do
              params[:init_filters] = 'true'
              Index.new(params, additional)
            end
            before { subject.run }

            it 'assigns %i[divisions operations item_types] to the :filters key' do
              expect(subject.data[:filters]).to include(:divisions, :operations, :item_types)
            end

            its(:run) { is_expected.to be_truthy }
          end

          context 'with filters' do
            let(:filter) { {} }
            subject do
              params[:filters] = filter
              Index.new(params, additional)
            end

            context 'and with :id filter' do
              let(:filter) { { id: orders.first.id }.to_json }

              it 'returns filtered data' do
                subject.run

                expect(subject.data[:data].count).to eq 1
                expect(subject.data[:data].first['id']).to eq orders.first.id
              end
            end

            context 'and with :invent_workplace_id filter' do
              if op_type == :out
                let(:filter) { { invent_workplace_id: orders.first.invent_workplace_id }.to_json }

                it 'returns filtered data' do
                  subject.run

                  expect(subject.data[:data].count).to eq 1
                  expect(subject.data[:data].first['invent_workplace_id']).to eq orders.first.invent_workplace_id
                end
              end
            end

            context 'and with :creator_fio filter' do
              let(:filter) { { creator_fio: orders.first.creator_fio }.to_json }
              let(:fio) { 'new_fio' }
              before { orders.first.update(creator_fio: fio) }

              it 'returns filtered data' do
                subject.run

                expect(subject.data[:data].count).to eq 1
                expect(subject.data[:data].first['creator_fio']).to eq fio
              end
            end
          end
        end
      end
    end
  end
end

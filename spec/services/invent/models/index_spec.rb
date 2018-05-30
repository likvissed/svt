require 'feature_helper'

module Invent
  module Models
    RSpec.describe Index, type: :model do
      let(:params) { { start: 0, length: 25 } }

      subject { Index.new(params) }
      before { subject.run }

      its(:run) { is_expected.to be_truthy }

      it 'loads models specified into length param' do
        expect(subject.data[:data].count).to eq params[:length]
      end

      it 'adds :all_properties field' do
        expect(subject.data[:data].first).to include('all_properties')
      end

      context 'with init_filters' do
        subject do
          params[:init_filters] = 'true'
          Index.new(params)
        end

        it 'assigns %i[types vendors] to the :filters key' do
          expect(subject.data[:filters]).to include(:types, :vendors)
        end

        its(:run) { is_expected.to be_truthy }
      end

      context 'with filters' do
        let(:filter) { {} }
        subject do
          params[:filters] = filter
          Index.new(params)
        end

        context 'and with :vendor filter' do
          let(:vendor_id) { Vendor.first.vendor_id }
          let(:filter) { { vendor_id: vendor_id }.to_json }

          it 'returns filtered data' do
            subject.data[:data].each do |model|
              expect(model['vendor_id']).to eq vendor_id
            end
          end
        end

        context 'and with :type filter' do
          let(:type_id) { Type.find_by(name: :monitor).type_id }
          let(:filter) { { type_id: type_id }.to_json }

          it 'returns filtered data' do
            subject.data[:data].each do |model|
              expect(model['type_id']).to eq type_id
            end
          end
        end

        context 'and with :item_model filter' do
          let(:filter) { { item_model: 'Phaser' }.to_json }

          it 'returns filtered data' do
            expect(subject.data[:data].count).to eq 6
          end
        end
      end
    end
  end
end

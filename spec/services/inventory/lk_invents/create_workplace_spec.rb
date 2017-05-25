require 'spec_helper'

module Inventory
  module LkInvents
    RSpec.describe CreateWorkplace, type: :model do
      let!(:workplace_count) { create(:active_workplace_count, user: build(:user)) }

      context 'with valid workplace params' do
        let(:workplace) do
          # Устанавливаем iss_reference_room = nil, так как пользователь с личного кабинета присылает не id, а строковое
          # значение (номер) комнаты.
          tmp = build(
            :workplace_pk,
            :add_items,
            items: %i[pc monitor],
            iss_reference_room: nil,
            workplace_count: workplace_count
          ).as_json(
            include: {
              inv_items: {
                include: :inv_property_values
              }
            },
            methods: :location_room_name
          ).with_indifferent_access

          tmp[:inv_items_attributes] = tmp[:inv_items]
          tmp[:inv_items_attributes].each do |item|
            item[:inv_property_values_attributes] = item[:inv_property_values]

            item.delete(:inv_property_values)
          end

          tmp.delete(:inv_items)

          tmp.with_indifferent_access
        end
        let(:room) do
          IssReferenceRoom
            .where(building_id: workplace[:location_building_id])
            .where(name: workplace[:location_room_name])
            .first
        end
        let(:item_count) do
          count = 0
          workplace[:inv_items_attributes].each { |item| count += item[:inv_property_values_attributes].count }
          count
        end
        subject { CreateWorkplace.new(workplace) }

        it 'sets location_room_id variable' do
          subject.run
          expect(subject.workplace_params[:location_room_id]).to eq room.room_id
        end

        it 'creates a @workplace variable' do
          subject.run
          expect(subject.workplace).to be_an_instance_of Workplace
        end

        include_examples 'run methods', %w[create_or_get_room log_data save_workplace]
        include_examples 'not run methods', 'set_file_into_params'

        it 'saves the new workplace in the database' do
          expect { subject.run }.to change(Workplace, :count).by(1)
        end

        it 'saves the new items in the database' do
          expect { subject.run }.to change(InvItem, :count).by(workplace[:inv_items_attributes].count)
        end

        it 'saves the new property_values in the database' do
          expect { subject.run }.to change(InvPropertyValue, :count).by(item_count)
        end

        it 'fills the @data at least with %w[short_description fio duty location status] keys' do
          subject.run
          expect(subject.data).to include('short_description', 'fio', 'duty', 'location', 'status')
        end

        its(:run) { is_expected.to be_truthy }

        context 'with file' do
          let(:file) do
            Rack::Test::UploadedFile.new(
              Rails.root.join('spec', 'files', 'old_pc_config.txt'),
              'text/plain'
            )
          end
          subject { CreateWorkplace.new(workplace, file) }

          include_examples 'run methods', 'set_file_into_params'

          it 'adds file key to workplace' do
            subject.run
            expect(
              subject.workplace_params[:inv_items_attributes].any? do |item|
                item[:inv_property_values_attributes].any? { |prop_val| prop_val.key?(:file) }
              end
            ).to be_truthy
          end

          its(:run) { is_expected.to be_truthy }
        end
      end

      context 'with invalid workplace params' do
        let(:workplace) do
          # Устанавливаем iss_reference_room = nil, так как пользователь с личного кабинета присылает не id, а строковое
          # значение (номер) комнаты.
          tmp = build(
            :workplace,
            id_tn: nil,
            workplace_specialization: nil,
            iss_reference_room: nil,
            workplace_count: workplace_count
          ).as_json(
            include: {
              inv_items: {
                include: :inv_property_values
              }
            },
            methods: :location_room_name
          ).with_indifferent_access

          tmp[:inv_items_attributes] = tmp[:inv_items]
          tmp[:inv_items_attributes].each do |item|
            item[:inv_property_values_attributes] = item[:inv_property_values]

            item.delete(:inv_property_values)
          end

          tmp.delete(:inv_items)

          tmp.with_indifferent_access
        end
        subject { CreateWorkplace.new(workplace) }

        context 'with invalid file' do
          subject { CreateWorkplace.new(workplace, 'wrong_param') }

          include_examples 'not run methods', 'set_file_into_params'
        end

        its(:run) { is_expected.to be_falsey }
      end
    end
  end
end

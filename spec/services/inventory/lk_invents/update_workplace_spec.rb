require 'spec_helper'

module Inventory
  module LkInvents
    RSpec.describe EditWorkplace, type: :model do
      let!(:workplace_count) { create(:active_workplace_count, user: build(:user)) }
      let!(:old_workplace) do
        create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
      end

      context 'with valid workplace params' do
        let(:room) { create :iss_room }
        # ***REMOVED***
        let(:user) { UserIss.find_by(tn: 15173) }
        let(:new_workplace) { update_workplace_attributes(old_workplace.workplace_id) }
        subject { UpdateWorkplace.new(old_workplace.workplace_id, new_workplace) }

        it 'creates a @workplace variable' do
          subject.run
          expect(subject.workplace).to eq old_workplace
        end

        it 'sets location_room_id variable' do
          subject.run
          expect(subject.workplace_params[:location_room_id]).to eq room.room_id
        end

        include_examples 'run methods', %w[create_or_get_room update_workplace]
        include_examples 'not run methods', 'set_file_into_params'

        it 'changes workplace attributes' do
          subject.run
          old_workplace.reload
          expect(old_workplace.iss_reference_room).to eq room
          expect(old_workplace.id_tn).to eq user.id_tn
        end

        it 'changes inv_items count' do
          expect { subject.run }.to change(old_workplace.inv_items, :count)
                                      .by(new_workplace['inv_items_attributes'].count - old_workplace.inv_items.count)
        end

        it 'fills the @data at least with %w[short_description fio duty location status] keys' do
          subject.run
          expect(subject.data).to include('short_description', 'fio', 'duty', 'location', 'status')
        end

        its(:run) { is_expected.to be_truthy }

        context 'when the new workplace has a file' do
          let(:file) do
            Rack::Test::UploadedFile.new(
              Rails.root.join('spec', 'files', 'new_pc_config.txt'),
              'text/plain'
            )
          end
          subject { UpdateWorkplace.new(old_workplace.workplace_id, new_workplace, file) }

          include_examples 'run methods', 'set_file_into_params'

          it 'adds "file" key to workplace' do
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
        let(:new_workplace) do
          wp = EditWorkplace.new(old_workplace.workplace_id)
          wp.run
          # Меняем общие аттрибуты рабочего места
          wp.data['id_tn'] = nil
          wp.data['workplace_specialization'] = nil
          wp.data['location_room_name'] = nil

          # Меняем состав рабочего места
          new_mon = wp.data['inv_items_attributes'].deep_dup.last
          new_mon['id'] = nil
          new_mon['item_model'] = 'Monitor model 2'
          new_mon['inv_property_values_attributes'].each { |prop_val| prop_val['id'] = nil }

          wp.data['inv_items_attributes'] << new_mon

          wp.data
        end
        subject { UpdateWorkplace.new(old_workplace.workplace_id, new_workplace) }

        context 'with invalid file' do
          subject { UpdateWorkplace.new(old_workplace.workplace_id, new_workplace, 'wrong_param') }

          include_examples 'not run methods', 'set_file_into_params'
        end

        its(:run) { is_expected.to be_falsey }
      end
    end
  end
end
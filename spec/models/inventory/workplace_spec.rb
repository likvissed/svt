require 'rails_helper'

module Inventory
  RSpec.describe Workplace, type: :model do
    it { should have_many(:inv_items).dependent(false) }
    it { should belong_to(:workplace_type) }
    it { should belong_to(:workplace_specialization) }
    it { should belong_to(:workplace_count) }
    it { should belong_to(:user_iss).with_foreign_key('id_tn') }
    it { should belong_to(:iss_reference_site).with_foreign_key('location_site_id') }
    it { should belong_to(:iss_reference_building).with_foreign_key('location_building_id') }
    it { should belong_to(:iss_reference_room).with_foreign_key('location_room_id') }

    it { should validate_presence_of(:id_tn) }
    it { should validate_presence_of(:workplace_count_id) }
    it { should validate_presence_of(:workplace_type_id) }
    it { should validate_presence_of(:workplace_specialization_id) }
    it { should validate_presence_of(:location_site_id) }
    it { should validate_presence_of(:location_building_id) }
    it { should validate_presence_of(:location_room_id) }

    it { should validate_numericality_of(:id_tn).is_greater_than(0).only_integer }
    it { should validate_numericality_of(:workplace_count_id).is_greater_than(0).only_integer }
    it { should validate_numericality_of(:workplace_type_id).is_greater_than(0).only_integer }
    it { should validate_numericality_of(:workplace_specialization_id).is_greater_than(0).only_integer }
    it { should validate_numericality_of(:location_site_id).is_greater_than(0).only_integer }
    it { should validate_numericality_of(:location_building_id).is_greater_than(0).only_integer }
    it { should validate_numericality_of(:location_room_id).is_greater_than(0).only_integer }

    it { should accept_nested_attributes_for(:inv_items).allow_destroy(true) }

    describe '#destroy_from_***REMOVED***' do
      let!(:workplace) { create(:full_workplace_rm_pk, :add_items, items: %i[pc monitor monitor]) }
      before { workplace.destroy_from_***REMOVED*** }

      it 'should destroy all items in workplace' do
        expect(workplace.inv_items.count).to eq(0)
      end

      it 'should destroy workplace' do
        expect(Workplace.where(workplace_id: workplace.id)).not_to exist
      end
    end

    describe '#check_id_tn' do
      context 'when id_tn is set and right' do
        include_examples 'workplace_valid_model' do
          let(:workplace) { build(:full_workplace_rm_pk, :add_items, items: %i[pc monitor monitor]) }
        end
      end

      context 'when id_tn is set, but wrong' do
        include_examples 'workplace_not_valid_model' do
          let(:workplace) { build(:workplace_with_wrong_id_tn, :add_items, items: %i[pc monitor monitor]) }
        end
      end
    end

    describe '#check_workplace_conditions' do
      context 'when workplace has rm_pk type' do
        context 'and when notebook is set' do
          include_examples 'workplace_not_valid_model' do
            let(:workplace) { build(:full_workplace_rm_pk, :add_items, items: [:notebook]) }
          end
        end

        context 'and when tablet is set' do
          include_examples 'workplace_not_valid_model' do
            let(:workplace) { build(:full_workplace_rm_pk, :add_items, items: [:tablet]) }
          end
        end

        context 'and when pc and allin1 are not set' do
          include_examples 'workplace_not_valid_model' do
            let(:workplace) { build(:full_workplace_rm_pk) }
          end
        end

        context 'and when monitor and allin1 are not set' do
          include_examples 'workplace_not_valid_model' do
            let(:workplace) { build(:full_workplace_rm_pk, :add_items, items: [:pc]) }
          end
        end

        context 'and when printer with network connection is set' do
          include_examples 'workplace_not_valid_model' do
            let(:workplace) do
              build(
                :full_workplace_rm_pk,
                :add_items,
                items: [
                  :pc, :monitor, { printer: [{ connection_type: { inv_property_list: InvProperty.find_by(name:
                  :connection_type).inv_property_lists.find_by(value: :network) } }] }
                ]
              )
            end
          end
        end

        context 'and when the one pc and at least one monitor are sets' do
          include_examples 'workplace_valid_model' do
            let(:workplace) { build(:full_workplace_rm_pk, :add_items, items: %i[pc monitor monitor]) }
          end
        end

        context 'and when allin1 is set' do
          include_examples 'workplace_valid_model' do
            let(:workplace) { build(:full_workplace_rm_pk, :add_items, items: [:allin1]) }
          end
        end

        context 'and when printer with local connection is set' do
          include_examples 'workplace_valid_model' do
            let(:workplace) do
              build(
                :full_workplace_rm_pk,
                :add_items,
                items: [:pc, :monitor, { printer: [{ connection_type: { inv_property_list: InvProperty.find_by(name:
                  :connection_type).inv_property_lists.find_by(value: :local) } }] }]
              )
            end
          end
        end
      end

      context 'when workplace has rm_mob type' do
        context 'and when count of items is equal zero' do
          include_examples 'workplace_not_valid_model' do
            let(:workplace) { build(:full_workplace_rm_mob) }
          end
        end

        context 'and when user sets items that not part of array InvItem::ALLOWED_MOB_TYPES' do
          InvType.all.reject do |type_obj|
            InvItem::ALLOWED_MOB_TYPES.find { |type_name| type_obj['name'] == type_name }
          end.each do |mob_type|
            include_examples 'workplace_not_valid_model' do
              let(:workplace) { build(:full_workplace_rm_mob, :add_items, items: [mob_type.name.to_sym]) }
            end
          end
        end

        context 'and when user sets not one allowed item' do
          InvItem::ALLOWED_MOB_TYPES.each do |type_name|
            include_examples 'workplace_not_valid_model' do
              let(:workplace) { build(:full_workplace_rm_mob, :add_items, items: [type_name.to_sym, type_name.to_sym]) }
            end
          end
        end

        context 'and when user sets only one allowed item' do
          InvItem::ALLOWED_MOB_TYPES.each do |type_name|
            include_examples 'workplace_valid_model' do
              let(:workplace) { build(:full_workplace_rm_mob, :add_items, items: [type_name.to_sym]) }
            end
          end
        end
      end

      context 'when workplace has rm_net_print type' do
        context 'and when count of items is equal zero' do
          include_examples 'workplace_not_valid_model' do
            let(:workplace) { build(:full_workplace_rm_net_print) }
          end
        end

        context 'and when count of items is not equal zero' do
          let!(:network_connection) do
            {
              connection_type:
                { inv_property_list: InvProperty.find_by(name: :connection_type).inv_property_lists.find_by(value:
                                                                                                              :network) }
            }
          end
          let!(:local_connection) do
            {
              connection_type:
                { inv_property_list: InvProperty.find_by(name: :connection_type).inv_property_lists
                                       .find_by(value: :local) }
            }
          end

          context 'and when user sets one printer with network connection' do
            include_examples 'workplace_valid_model' do
              let(:workplace) do
                build(:full_workplace_rm_net_print, :add_items, items: [{ printer: [network_connection] }])
              end
            end
          end

          context 'and when user sets two printers with network connection' do
            include_examples 'workplace_not_valid_model' do
              let(:workplace) do
                build(
                  :full_workplace_rm_net_print,
                  :add_items,
                  items: [{ printer: [network_connection] }, { mfu: [network_connection] }]
                )
              end
            end
          end

          context 'and when user sets one printer with network connection and any another item.' do
            include_examples 'workplace_not_valid_model' do
              let(:workplace) do
                build(:full_workplace_rm_net_print, :add_items, items: [{ printer: [network_connection] }, :pc])
              end
            end
          end

          context 'and when user sets two 3d-printers' do
            include_examples 'workplace_not_valid_model' do
              let(:workplace) { build(:full_workplace_rm_net_print, :add_items, items: %i[3d_printer 3d_printer]) }
            end
          end

          context 'and when user sets only one 3d-printer' do
            include_examples 'workplace_valid_model' do
              let(:workplace) { build(:full_workplace_rm_net_print, :add_items, items: [:'3d_printer']) }
            end
          end

          context 'and when user sets one 3d_printer and any another item' do
            include_examples 'workplace_not_valid_model' do
              let(:workplace) { build(:full_workplace_rm_net_print, :add_items, items: %i[3d_printer pc]) }
            end
          end

          context 'and when user sets two print_servers' do
            include_examples 'workplace_not_valid_model' do
              let(:workplace) { build(:full_workplace_rm_net_print, :add_items, items: %i[print_server print_server]) }
            end
          end

          context 'and when user sets one print_server and any printer with network connection' do
            include_examples 'workplace_not_valid_model' do
              let(:workplace) do
                build(:full_workplace_rm_net_print, :add_items, items: [:print_server, { printer: [network_connection] }])
              end
            end
          end

          context 'and when user sets one print_server and any printer with local connection' do
            include_examples 'workplace_valid_model' do
              let(:workplace) do
                build(:full_workplace_rm_net_print, :add_items, items: [:print_server, { printer: [local_connection] }])
              end
            end
          end

          context 'and when user did not set any printer' do
            include_examples 'workplace_not_valid_model' do
              let(:workplace) { build(:full_workplace_rm_net_print, :add_items, items: [:pc]) }
            end
          end
        end
      end

      context 'when workplace has rm_server type' do
        context 'and when notebook is set' do
          include_examples 'workplace_not_valid_model' do
            let(:workplace) { build(:full_workplace_rm_server, :add_items, items: [:notebook]) }
          end
        end

        context 'and when tablet is set' do
          include_examples 'workplace_not_valid_model' do
            let(:workplace) { build(:full_workplace_rm_server, :add_items, items: [:tablet]) }
          end
        end

        context 'and when pc and allin1 are not set' do
          include_examples 'workplace_not_valid_model' do
            let(:workplace) { build(:full_workplace_rm_server) }
          end
        end

        context 'and when printer with network connection is set' do
          include_examples 'workplace_not_valid_model' do
            let(:workplace) do
              build(
                :full_workplace_rm_server,
                :add_items,
                items: [:pc, :monitor, { printer: [{ connection_type: { inv_property_list: InvProperty.find_by(name:
                  :connection_type).inv_property_lists.find_by(value: :network) } }] }]
              )
            end
          end
        end

        context 'and when pc is set' do
          include_examples 'workplace_valid_model' do
            let(:workplace) { build(:full_workplace_rm_server, :add_items, items: [:pc]) }
          end
        end

        context 'and when allin1 is set' do
          include_examples 'workplace_valid_model' do
            let(:workplace) { build(:full_workplace_rm_server, :add_items, items: [:allin1]) }
          end
        end

        context 'and when printer with local connection is set' do
          include_examples 'workplace_valid_model' do
            let(:workplace) do
              build(
                :full_workplace_rm_server,
                :add_items,
                items: [:pc, :monitor, { printer: [{ connection_type: { inv_property_list: InvProperty.find_by(name:
                  :connection_type).inv_property_lists.find_by(value: :local) } }] }]
              )
            end
          end
        end
      end
    end
  end
end

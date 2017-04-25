require 'rails_helper'

module Inventory
  RSpec.describe InvItem, type: :model do
    describe "#destroy_from_***REMOVED***" do
      let!(:workplace) { create(:full_workplace_rm_pk, :add_items, items: [:pc, :monitor, :monitor]) }
      before { workplace.destroy_from_***REMOVED*** }

      it "should destroy all items in workplace" do
        expect(workplace.inv_items.count).to eq(0)
      end

      it "should destroy workplace" do
        expect(Workplace.where(workplace_id: workplace.id)).not_to exist
      end
    end

    describe "#check_id_tn" do
      context "when id_tn is set and right" do
        include_examples "workplace_valid_model" do
          let(:workplace) { build(:full_workplace_rm_pk, :add_items, items: [:pc, :monitor, :monitor]) }
        end
      end

      context "when id_tn is set, but wrong" do
        include_examples "workplace_not_valid_model" do
          let(:workplace) { build(:workplace_with_wrong_id_tn, :add_items, items: [:pc, :monitor, :monitor]) }
        end
      end
    end

    describe "#check_workplace_conditions" do
      context "when workplace has rm_pk type" do
        context "and when notebook is set" do
          include_examples "workplace_not_valid_model" do
            let(:workplace) { build(:full_workplace_rm_pk, :add_items, items: [:notebook]) }
          end
        end

        context "and when tablet is set" do
          include_examples "workplace_not_valid_model" do
            let(:workplace) { build(:full_workplace_rm_pk, :add_items, items: [:tablet]) }
          end
        end

        context "and when pc and allin1 are not set" do
          include_examples "workplace_not_valid_model" do
            let(:workplace) { build(:full_workplace_rm_pk) }
          end
        end

        context "and when monitor and allin1 are not set" do
          include_examples "workplace_not_valid_model" do
            let(:workplace) { build(:full_workplace_rm_pk, :add_items, items: [:pc]) }
          end
        end

        context "and when printer with network connection is set" do
          include_examples "workplace_not_valid_model" do
            let(:workplace) { build(:full_workplace_rm_pk, :add_items, items: [:pc, :monitor, { printer: [{
            connection_type: { inv_property_list: InvProperty.find_by(name: :connection_type).inv_property_lists
            .find_by(value: :network) } }] }]) }
          end
        end

        context "and when the one pc and at least one monitor are sets" do
          include_examples "workplace_valid_model" do
            let(:workplace) { build(:full_workplace_rm_pk, :add_items, items: [:pc, :monitor, :monitor]) }
          end
        end

        context "and when allin1 is set" do
          include_examples "workplace_valid_model" do
            let(:workplace) { build(:full_workplace_rm_pk, :add_items, items: [:allin1]) }
          end
        end

        context "and when printer with local connection is set" do
          include_examples "workplace_valid_model" do
            let(:workplace) { build(:full_workplace_rm_pk, :add_items, items: [:pc, :monitor, { printer: [{
            connection_type: { inv_property_list: InvProperty.find_by(name: :connection_type).inv_property_lists
            .find_by(value: :local) } }] }]) }
          end
        end
      end

      context "when workplace has rm_mob type" do
        context "and when user sets items that not part of array InvItem::ALLOWED_MOB_TYPES" do
          InvType.all.reject{ |type_obj| InvItem::ALLOWED_MOB_TYPES.find{ |type_name| type_obj['name'] == type_name }
          }.each do |mob_type|
            include_examples "workplace_not_valid_model" do
              let(:workplace) { build(:full_workplace_rm_mob, :add_items, items: [mob_type.name.to_sym]) }
            end
          end
        end

        context "and when user sets not one allowed item" do
          InvItem::ALLOWED_MOB_TYPES.each do |type_name|
            include_examples "workplace_not_valid_model" do
              let(:workplace) { build(:full_workplace_rm_mob, :add_items, items: [type_name.to_sym, type_name.to_sym]) }
            end
          end
        end

        context "and when user sets only one allowed item" do
          InvItem::ALLOWED_MOB_TYPES.each do |type_name|
            include_examples "workplace_valid_model" do
              let(:workplace) { build(:full_workplace_rm_mob, :add_items, items: [type_name.to_sym]) }
            end
          end
        end
      end

      context "when workplace has rm_net_print type" do
        let!(:network_connection) { { connection_type: { inv_property_list: InvProperty.find_by(name: :connection_type)
          .inv_property_lists.find_by(value: :network) } } }
        let!(:local_connection) { { connection_type: { inv_property_list: InvProperty.find_by(name: :connection_type)
          .inv_property_lists.find_by(value: :local) } } }

        context "and when user sets one printer with network connection" do
          InvItem::ALL_PRINT_TYPES
          include_examples "workplace_valid_model" do
            let(:workplace) { build(:full_workplace_rm_net_print, :add_items, items: [{ printer: [network_connection]
              }]) }
          end
        end

        context "and when user sets two printers with network connection" do
          include_examples "workplace_not_valid_model" do
            let(:workplace) { build(:full_workplace_rm_net_print, :add_items, items: [{ printer: [network_connection]
              }, { mfu: [network_connection] }]) }
          end
        end

        context "and when user sets one printer with network connection and any another item." do
          include_examples "workplace_not_valid_model" do
            let(:workplace) { build(:full_workplace_rm_net_print, :add_items, items: [{ printer: [network_connection] },
              :pc]) }
          end
        end

        context "and when user sets two 3d-printers" do
          include_examples "workplace_not_valid_model" do
            let(:workplace) { build(:full_workplace_rm_net_print, :add_items, items: [:'3d_printer', :'3d_printer']) }
          end
        end

        context "and when user sets only one 3d-printer" do
          include_examples "workplace_valid_model" do
            let(:workplace) { build(:full_workplace_rm_net_print, :add_items, items: [:'3d_printer']) }
          end
        end

        context "and when user sets one 3d_printer and any another item" do
          include_examples "workplace_not_valid_model" do
            let(:workplace) { build(:full_workplace_rm_net_print, :add_items, items: [:'3d_printer', :pc]) }
          end
        end

        context "and when user sets two print_servers" do
          include_examples "workplace_not_valid_model" do
            let(:workplace) { build(:full_workplace_rm_net_print, :add_items, items: [:print_server, :print_server]) }
          end
        end

        context "and when user sets one print_server and any printer with network connection" do
          include_examples "workplace_not_valid_model" do
            let(:workplace) { build(:full_workplace_rm_net_print, :add_items, items: [:print_server, { printer:
              [network_connection] }]) }
          end
        end

        context "and when user sets one print_server and any printer with local connection" do
          include_examples "workplace_valid_model" do
            let(:workplace) { build(:full_workplace_rm_net_print, :add_items, items: [:print_server, { printer:
              [local_connection] }]) }
          end
        end

        context "and when user didn't set any printer" do
          include_examples "workplace_not_valid_model" do
            let(:workplace) { build(:full_workplace_rm_net_print, :add_items, items: [:pc]) }
          end
        end
      end

      context "when workplace has rm_server type" do
        context "and when notebook is set" do
          include_examples "workplace_not_valid_model" do
            let(:workplace) { build(:full_workplace_rm_server, :add_items, items: [:notebook]) }
          end
        end

        context "and when tablet is set" do
          include_examples "workplace_not_valid_model" do
            let(:workplace) { build(:full_workplace_rm_server, :add_items, items: [:tablet]) }
          end
        end

        context "and when pc and allin1 are not set" do
          include_examples "workplace_not_valid_model" do
            let(:workplace) { build(:full_workplace_rm_server) }
          end
        end

        context "and when printer with network connection is set" do
          include_examples "workplace_not_valid_model" do
            let(:workplace) { build(:full_workplace_rm_server, :add_items, items: [:pc, :monitor, { printer: [{
              connection_type: { inv_property_list: InvProperty.find_by(name: :connection_type).inv_property_lists
              .find_by(value: :network) } }] }]) }
          end
        end

        context "and when pc is set" do
          include_examples "workplace_valid_model" do
            let(:workplace) { build(:full_workplace_rm_server, :add_items, items: [:pc]) }
          end
        end

        context "and when allin1 is set" do
          include_examples "workplace_valid_model" do
            let(:workplace) { build(:full_workplace_rm_server, :add_items, items: [:allin1]) }
          end
        end

        context "and when printer with local connection is set" do
          include_examples "workplace_valid_model" do
            let(:workplace) { build(:full_workplace_rm_server, :add_items, items: [:pc, :monitor, { printer: [{
              connection_type: { inv_property_list: InvProperty.find_by(name: :connection_type).inv_property_lists
              .find_by(value: :local) } }] }]) }
          end
        end
      end
    end
  end
end
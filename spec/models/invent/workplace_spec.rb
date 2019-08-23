require 'feature_helper'

module Invent
  RSpec.describe Workplace, type: :model do
    it { is_expected.not_to validate_presence_of(:freezing_time) }
    it { is_expected.to have_many(:items).inverse_of(:workplace).dependent(:nullify) }
    it { is_expected.to have_many(:orders).class_name('Warehouse::Order').dependent(:nullify) }
    it { is_expected.to belong_to(:workplace_type) }
    it { is_expected.to belong_to(:workplace_specialization) }
    it { is_expected.to belong_to(:workplace_count) }
    it { is_expected.to belong_to(:user_iss).with_foreign_key('id_tn') }
    it { is_expected.to belong_to(:iss_reference_site).with_foreign_key('location_site_id') }
    it { is_expected.to belong_to(:iss_reference_building).with_foreign_key('location_building_id') }
    it { is_expected.to belong_to(:iss_reference_room).with_foreign_key('location_room_id') }
    it { is_expected.to accept_nested_attributes_for(:items).allow_destroy(false) }

    context 'when workplace status is :temporary' do
      before { subject.status = :temporary }

      it { is_expected.to validate_presence_of(:freezing_time) }
      it { is_expected.to validate_presence_of(:comment) }
    end

    describe '#destroy_from_***REMOVED***' do
      let!(:workplace) do
        create(:workplace_pk, :add_items, items: %i[pc monitor monitor])
      end
      before { workplace.destroy_from_***REMOVED*** }

      it 'should destroy all items in workplace' do
        expect(workplace.items.count).to eq 0
      end

      it 'should destroy workplace' do
        expect(Workplace.where(workplace_id: workplace.id)).not_to exist
      end
    end

    describe '#check_processing_orders' do
      let!(:wp) { create(:workplace_pk, :add_items, items: %i[pc monitor monitor]) }
      subject { wp }
      before { wp.hard_destroy = true }

      context 'when workplace belongs to processing order' do
        let(:operation) { build(:order_operation, inv_items: [subject.items.first]) }
        let!(:order) { create(:order, inv_workplace: subject, operations: [operation]) }

        it 'adds :cannot_destroy_workplace_belongs_to_processing_order error' do
          subject.destroy
          expect(subject.errors.details[:base]).to include(error: :cannot_destroy_workplace_belongs_to_processing_order)
        end

        it 'does not destroy Workplace' do
          expect { subject.destroy }.not_to change(Workplace, :count)
        end
      end

      context 'when workplace belongs to done order' do
        let(:stockman) { create(:***REMOVED***_user) }
        let(:operation) { build(:order_operation, status: :done, inv_items: [subject.items.first], stockman_id_tn: stockman.id_tn) }
        let!(:order) { create(:order, inv_workplace: subject, operations: [operation], consumer_tn: stockman.tn) }

        its(:destroy) { is_expected.to be_truthy }
      end

      context 'when workplace is not belong to any order' do
        its(:destroy) { is_expected.to be_truthy }
      end
    end

    describe '#check_items' do
      context 'when workplace includes any item' do
        let!(:wp) { create(:workplace_pk, :add_items, items: %i[pc monitor monitor]) }
        subject { wp }

        it 'adds :cannot_destroy_workplace_with_items error' do
          subject.destroy
          expect(subject.errors.details[:base]).to include(error: :cannot_destroy_workplace_with_items)
        end

        it 'does not destroy Workplace' do
          expect { subject.destroy }.not_to change(Workplace, :count)
        end
      end

      context 'when workplace is empty' do
        subject do
          wp = build(:workplace_pk)
          wp.save(validate: false)
          wp
        end

        its(:destroy) { is_expected.to be_truthy }
      end

      context 'when runned :hard_destroy method' do
        it 'does not run validation' do
          expect(subject).not_to receive(:check_items)
          subject.hard_destroy
        end
      end
    end

    describe '#id_tn' do
      context 'when status :freezed' do
        before { allow(subject).to receive(:status_freezed?).and_return(true) }

        it { is_expected.not_to validate_presence_of(:id_tn) }
        it { is_expected.not_to validate_numericality_of(:id_tn).only_integer }
      end

      context 'when status is not :freezed' do
        before { allow(subject).to receive(:status_freezed?).and_return(false) }

        it { is_expected.to validate_presence_of(:id_tn) }
        it { is_expected.to validate_numericality_of(:id_tn).only_integer }
      end

      context 'when id_tn is set and right' do
        subject { build(:workplace_pk, :add_items, items: %i[pc monitor monitor]) }

        it { is_expected.to be_valid }
      end

      context 'when id_tn is set, but wrong' do
        subject { build(:workplace_pk, :add_items, items: %i[pc monitor monitor], id_tn: '') }

        it { is_expected.not_to be_valid }
      end
    end

    describe '#check_workplace_conditions' do
      context 'when :disabled_filters flag is set' do
        subject { build(:workplace_pk, :add_items, items: %i[pc allin1 notebook], disabled_filters: true) }

        it 'does not run :check_workplace_conditions validation' do
          expect(subject).not_to receive(:check_workplace_conditions)
          subject.valid?
        end

        it { is_expected.to be_valid }
      end

      context 'when workplace has rm_pk type' do
        context 'and when status of one item is :waiting_bring' do
          let(:type) { Type.find_by(name: :pc) }
          let(:item_take) { build(:item, type: type, status: :waiting_take) }
          let(:item_bring) { build(:item, type: type, status: :waiting_bring) }
          subject { build(:workplace_pk, items: [item_take, item_bring]) }

          it 'does not have :rm_pk_only_one_pc_or_allin1 error' do
            subject.valid?
            expect(subject.errors.details[:base]).not_to include(error: :rm_pk_only_one_pc_or_allin1)
          end
        end

        context 'and when pc and allin1 are sets' do
          subject { build(:workplace_pk, :add_items, items: %i[pc allin1]) }
          before { expect(subject).not_to be_valid }

          include_examples ':wrong_rm_pk_composition error'
          include_examples 'includes error', 'rm_pk_only_one_pc_or_allin1'
        end

        context 'and when notebook is set' do
          subject { build(:workplace_pk, :add_items, items: [:notebook]) }

          it { is_expected.not_to be_valid }
        end

        context 'and when tablet is set' do
          subject { build(:workplace_pk, :add_items, items: [:tablet]) }

          it { is_expected.not_to be_valid }

          include_examples ':wrong_rm_pk_composition error'
          include_examples 'includes error', 'rm_pk_forbid_notebook_and_tablet'
        end

        context 'and when pc and allin1 are not set' do
          subject { build(:workplace_pk) }

          it { is_expected.not_to be_valid }

          include_examples ':wrong_rm_pk_composition error'
          include_examples 'includes error', 'rm_pk_at_least_one_pc_or_allin1'
        end

        context 'and when monitor and allin1 are not set' do
          subject { build(:workplace_pk, :add_items, items: [:pc]) }

          it { is_expected.not_to be_valid }

          include_examples ':wrong_rm_pk_composition error'
          include_examples 'includes error', 'rm_pk_at_least_one_monitor'
        end

        context 'and when printer with network connection is set' do
          subject do
            build(
              :workplace_pk,
              :add_items,
              items: [
                :pc,
                :monitor,
                { printer: [connection_type: { property_list: Property.find_by(name: :connection_type).property_lists.find_by(value: :network) }] }
              ]
            )
          end

          it { is_expected.not_to be_valid }

          include_examples ':wrong_rm_pk_composition error'
          include_examples 'includes error', 'rm_pk_forbid_net_printer'
        end

        context 'and when the one pc and at least one monitor are sets' do
          subject { build(:workplace_pk, :add_items, items: %i[pc monitor monitor]) }

          it { is_expected.to be_valid }
        end

        context 'and when allin1 is set' do
          subject { build(:workplace_pk, :add_items, items: [:allin1]) }

          it { is_expected.to be_valid }
        end

        context 'and when printer with local connection is set' do
          subject do
            build(
              :workplace_pk,
              :add_items,
              items: [
                :pc,
                :monitor,
                { printer: [connection_type: { property_list: Property.find_by(name: :connection_type).property_lists.find_by(value: :local) }] }
              ]
            )
          end

          it { is_expected.to be_valid }
        end
      end

      context 'when workplace has rm_mob type' do
        context 'and when count of items is zero' do
          subject { build(:workplace_mob) }

          it { is_expected.not_to be_valid }

          include_examples ':wrong_rm_mob_composition error'
          include_examples 'includes error', 'at_least_one_notebook_or_tablet'
        end

        context 'and when user sets items that not part of array Type::ALLOWED_MOB_TYPES' do
          types = Type.all.reject { |type_obj| Type::ALLOWED_MOB_TYPES.find { |type_name| type_obj['name'] == type_name } }

          types.each do |mob_type|
            context "#{mob_type.name} (#{mob_type.short_description})" do
              subject do
                build(:workplace_mob, :add_items, items: [mob_type.name.to_sym])
              end

              it { is_expected.not_to be_valid }

              include_examples ':wrong_rm_mob_composition error'
              include_examples 'includes error', 'only_notebook_or_tablet'
            end
          end
        end

        context 'and when user sets not one allowed item (its includes into array Type::ALLOWED_MOB_TYPES)' do
          Type::ALLOWED_MOB_TYPES.each do |type_name|
            context type_name.pluralize do
              subject do
                build(
                  :workplace_mob,
                  :add_items,
                  items: [type_name.to_sym, type_name.to_sym]
                )
              end

              it { is_expected.not_to be_valid }

              include_examples ':wrong_rm_mob_composition error'
              include_examples 'includes error', 'only_one_notebook_or_tablet'
            end
          end
        end

        context 'and when user sets only one allowed item' do
          Type::ALLOWED_MOB_TYPES.each do |type_name|
            subject { build(:workplace_mob, :add_items, items: [type_name.to_sym]) }

            it { is_expected.to be_valid }
          end
        end
      end

      context 'when workplace has rm_net_print type' do
        context 'and when count of network_printers (or print-servers) is zero' do
          subject { build(:workplace_net_print) }

          it { is_expected.not_to be_valid }

          include_examples ':wrong_rm_net_print_composition error'
          include_examples 'includes error', 'at_least_one_print'
        end

        context 'and when count of network_printers (or print-servers) is not zero' do
          let!(:network_connection) do
            {
              connection_type: {
                property_list: Property.find_by(name: :connection_type).property_lists.find_by(value: :network)
              }
            }
          end
          let!(:local_connection) do
            {
              connection_type: {
                property_list: Property.find_by(name: :connection_type).property_lists.find_by(value: :local)
              }
            }
          end

          context 'and when user sets one printer with network connection' do
            subject do
              build(
                :workplace_net_print,
                :add_items,
                items: [{ printer: [network_connection] }]
              )
            end

            it { is_expected.to be_valid }
          end

          context 'and when user sets two printers with network connection' do
            subject do
              build(
                :workplace_net_print,
                :add_items,
                items: [{ printer: [network_connection] }, { mfu: [network_connection] }]
              )
            end

            it { is_expected.not_to be_valid }

            include_examples ':wrong_rm_net_print_composition error'
            include_examples 'includes error', 'only_one_net_print'
          end

          context 'and when user sets one printer with network connection and any other devise' do
            subject do
              build(
                :workplace_net_print,
                :add_items,
                items: [{ printer: [network_connection] }, :pc]
              )
            end

            it { is_expected.not_to be_valid }

            include_examples ':wrong_rm_net_print_composition error'
            include_examples 'includes error', 'net_print_without_any_devices'
          end

          context 'and when user sets not one 3d-printer' do
            subject do
              build(
                :workplace_net_print, :add_items, items: %i[3d_printer 3d_printer]
              )
            end

            it { is_expected.not_to be_valid }

            include_examples ':wrong_rm_net_print_composition error'
            include_examples 'includes error', 'only_one_3d_printer'
          end

          context 'and when user sets only one 3d-printer' do
            subject { build(:workplace_net_print, :add_items, items: [:'3d_printer']) }

            it { is_expected.to be_valid }
          end

          context 'and when user sets one 3d_printer and any other item' do
            subject do
              build(
                :workplace_net_print,
                :add_items,
                items: %i[3d_printer pc]
              )
            end

            it { is_expected.not_to be_valid }

            include_examples ':wrong_rm_net_print_composition error'
            include_examples 'includes error', '_3d_printer_without_any_devices'
          end

          context 'and when user sets not one print_server' do
            subject { build(:workplace_net_print, :add_items, items: %i[print_server print_server]) }

            it { is_expected.not_to be_valid }

            include_examples ':wrong_rm_net_print_composition error'
            include_examples 'includes error', 'only_one_print_server'
          end

          context 'and when user sets one print_server and any printer with network connection' do
            subject do
              build(
                :workplace_net_print,
                :add_items,
                items: [:print_server, { printer: [network_connection] }]
              )
            end

            it { is_expected.not_to be_valid }

            include_examples ':wrong_rm_net_print_composition error'
            include_examples 'includes error', 'only_local_print_with_print_server'
          end

          context 'and when user sets one print_server and any printer with local connection' do
            subject do
              build(
                :workplace_net_print,
                :add_items,
                items: [:print_server, { printer: [local_connection] }]
              )
            end

            it { is_expected.to be_valid }
          end
        end
      end

      context 'when workplace has rm_server type' do
        context 'and when pc and allin1 are sets' do
          subject { build(:workplace_server, :add_items, items: %i[pc allin1]) }

          it { is_expected.not_to be_valid }

          include_examples ':wrong_rm_server_composition error'
          include_examples 'includes error', 'rm_server_only_one_pc_or_allin1'
        end

        Type::REJECTED_SERVER_TYPES.each do |item|
          context "and when #{item} is set" do
            subject { build(:workplace_server, :add_items, items: [item.to_sym]) }

            it { is_expected.not_to be_valid }

            include_examples ':wrong_rm_server_composition error'
            include_examples 'includes error', 'rm_server_forbid_notebook_and_tablet'
          end
        end

        context 'and when pc and allin1 are not set' do
          subject { build(:workplace_server) }

          it { is_expected.not_to be_valid }

          include_examples ':wrong_rm_server_composition error'
          include_examples 'includes error', 'rm_server_at_least_one_pc_or_allin1'
        end

        context 'and when printer with network connection is set' do
          subject do
            build(
              :workplace_server,
              :add_items,
              items: [
                :pc,
                :monitor,
                { printer: [{ connection_type: { property_list: Property.find_by(name: :connection_type).property_lists.find_by(value: :network) } }] }
              ]
            )
          end

          it { is_expected.not_to be_valid }

          include_examples ':wrong_rm_server_composition error'
          include_examples 'includes error', 'rm_server_forbid_net_printer'
        end

        context 'and when pc is set' do
          subject { build(:workplace_server, :add_items, items: [:pc]) }

          it { is_expected.to be_valid }
        end

        context 'and when allin1 is set' do
          subject { build(:workplace_server, :add_items, items: [:allin1]) }

          it { is_expected.to be_valid }
        end

        context 'and when printer with local connection is set' do
          subject do
            build(
              :workplace_server,
              :add_items,
              items: [
                :pc,
                :monitor,
                { printer: [{ connection_type: { property_list: Property.find_by(name: :connection_type).property_lists.find_by(value: :local) } }] }
              ]
            )
          end

          it { is_expected.to be_valid }
        end
      end
    end

    describe '#status_freezed?' do
      context 'when status is freezed' do
        subject do
          build(
            :workplace_pk,
            :add_items,
            items: [:allin1],
            status: :freezed
          )
        end

        its(:status_freezed?) { is_expected.to be_truthy }
      end
      context 'when status is not freezed' do
        subject { build(:workplace_pk, :add_items, items: [:allin1]) }

        its(:status_freezed?) { is_expected.to be_falsey }
      end
    end

    describe '#rm_equipment_verification' do
      context 'when :items present' do
        subject { build(:workplace, :add_items, items: [:allin1], workplace_type: WorkplaceType.find_by(name: 'rm_equipment')) }

        it 'save workplace' do
          expect(subject).to be_valid
        end
      end
      context 'when :items absence' do
        subject { build(:workplace, workplace_type: WorkplaceType.find_by(name: 'rm_equipment')) }

        it 'not save workplace - error :wrong_rm_equipment_composition' do
          subject.invalid?

          expect(subject.errors.details[:base]).to include(error: :wrong_rm_equipment_composition)
        end

        it 'not save workplace - error :rm_equipment_at_least_one_equipment' do
          subject.invalid?

          expect(subject.errors.details[:base]).to include(error: :rm_equipment_at_least_one_equipment)
        end
      end
    end
  end
end

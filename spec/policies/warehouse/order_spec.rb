require 'spec_helper'

module Warehouse
  RSpec.describe OrderPolicy do
    let(:manager) { create(:***REMOVED***_user) }
    let(:worker) { create(:shatunova_user) }
    let(:read_only) { create(:tyulyakova_user) }
    before { create(:order, validator: nil) }
    subject { OrderPolicy }

    permissions :new? do
      let(:model) { Order.first }

      include_examples 'policy for worker'
    end

    permissions :create_in? do
      let(:model) { Order.first }

      include_examples 'policy for worker'
    end

    permissions :create_out? do
      let(:model) { Order.first }

      context 'with manager role' do
        it 'grants access' do
          expect(subject).to permit(manager, model)
        end

        it 'sets validator' do
          expect(subject).to permit(manager, model)
          expect(model.validator_id_tn).to eq manager.id_tn
          expect(model.validator_fio).to eq manager.fullname
        end
      end
    end

    permissions :update_in? do
      let(:model) { Order.first }

      include_examples 'policy for worker'
    end

    permissions :update_out? do
      let(:model) { Order.first }

      context 'with manager role' do
        it 'grants access' do
          expect(subject).to permit(manager, model)
        end

        # it 'sets validator' do
        #   expect(subject).to permit(manager, model)
        #   expect(model.validator_id_tn).to eq manager.id_tn
        #   expect(model.validator_fio).to eq manager.fullname
        # end
      end

      context 'with worker role' do
        it 'grants access' do
          expect(subject).to permit(worker, model)
        end

        it 'sets nil to validator' do
          expect(subject).to permit(worker, model)
          expect(model.validator_id_tn).to be_nil
          expect(model.validator_fio).to be_nil
        end
      end

      context 'with read_only role' do
        it 'denies access' do
          expect(subject).not_to permit(read_only, model)
        end
      end
    end

    permissions :confirm_out? do
      let(:model) { Order.first }

      include_examples 'policy for manager'
    end

    permissions :execute_in? do
      let(:model) { Order.first }

      include_examples 'policy for worker'
    end

    permissions :execute_out? do
      let(:model) { Order.first }

      include_examples 'policy for worker'
    end

    permissions :destroy? do
      let(:model) { Order.first }

      include_examples 'policy for worker'
    end

    permissions :prepare_to_deliver? do
      let(:model) { Order.first }

      include_examples 'policy for worker'
    end

    permissions :print? do
      let(:model) { Order.first }

      include_examples 'policy for worker'
    end
  end
end

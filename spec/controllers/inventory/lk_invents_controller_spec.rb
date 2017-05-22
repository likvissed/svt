require 'rails_helper'

module Inventory
  RSpec.describe LkInventsController, type: :controller do
    let(:user) { build :user }
    let!(:workplace_count) { create(:active_workplace_count, user: user) }
    sign_in_through_***REMOVED***_user
    before { allow(controller).to receive(:check_***REMOVED***_authorization).and_return(true) }

    describe 'GET #init_properties' do
      it 'creates instance of the LkInvents::InitProperties class' do
        get :init_properties, params: { id_tn: user.id_tn }
        expect(assigns(:properties)).to be_instance_of LkInvents::InitProperties
      end
    end

    describe 'GET #show_division_data' do
      it 'creates instance of the LkInvents::ShowDivisionData class' do
        get :show_division_data, params: { id_tn: user.id_tn, division: workplace_count.division }
        expect(assigns(:division)).to be_instance_of LkInvents::ShowDivisionData
      end
    end

    describe 'GET #pc_config_from_audit' do
      let(:item) { build(:item) }

      it 'creates instance of the LkInvents::PcConfigFromAudit class' do
        get :pc_config_from_audit, params: { id_tn: user.id_tn, invent_num: item.invent_num }
        expect(assigns(:pc_config)).to be_instance_of LkInvents::PcConfigFromAudit
      end
    end
  end
end

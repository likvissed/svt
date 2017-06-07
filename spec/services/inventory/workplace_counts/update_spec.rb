require 'spec_helper'

module Inventory
  module WorkplaceCounts
    RSpec.describe Update, type: :model do
      let(:user) { create :user }
      let(:***REMOVED***_user) { attributes_for(:***REMOVED***_user).except(:id_tn, :division, :email, :login, :fullname) }
      let!(:workplace_count) { create :active_workplace_count, users: [user] }
      # Загружаем отдел c использованием сервиса WorkplaceCount::Show.
      let(:loaded_workplace_count) do
        show = WorkplaceCounts::Show.new(workplace_count.workplace_count_id)
        show.data if show.run
      end
      # Меняем атрибуты отдела (добавляем нового ответственного)
      let(:new_workplace_count) do
        loaded_workplace_count['users_attributes'] << ***REMOVED***_user
        loaded_workplace_count
      end
      subject { Update.new(workplace_count.workplace_count_id,new_workplace_count) }

      include_examples 'run methods', 'update_workplace'
      it 'assign @data to workplace_count object' do
        subject.run
        expect(subject.data).to eq workplace_count
      end

      context 'with valid params' do
        its(:run) { is_expected.to be_truthy }
      end

      context 'with invalid params' do
        # Меняем атрибуты отдела
        let(:new_workplace_count) do
          loaded_workplace_count['division'] = ''
          loaded_workplace_count
        end
        subject { Update.new(workplace_count.workplace_count_id,new_workplace_count) }

        its(:run) { is_expected.to be_falsey }
        it 'includes object and full_message keys into the @error object' do
          subject.run
          expect(subject.error).to include(:object, :full_message)
        end
      end
    end
  end
end
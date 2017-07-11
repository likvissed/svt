require 'rails_helper'

module Inventory
  RSpec.describe WorkplaceCount, type: :model do
    it { is_expected.to have_many(:workplaces) }
    it { is_expected.to have_many(:workplace_responsibles).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:workplace_responsibles) }

    it { is_expected.to validate_presence_of(:division) }
    it { is_expected.to validate_numericality_of(:division).is_greater_than(0).only_integer }
    it { is_expected.to validate_presence_of(:time_start) }
    it { is_expected.to validate_presence_of(:time_end) }

    context 'when workplace_count already exists' do
      let!(:workplace_count) { create :active_workplace_count, users: [create(:user)] }

      it { is_expected.to validate_uniqueness_of(:division).case_insensitive }
    end

    it { is_expected.to accept_nested_attributes_for(:users).allow_destroy(true) }

    describe 'create workpalce_count (one of the responsibles exists in the local table of users)' do
      context 'when users_attributes is empty' do
        subject { build :active_workplace_count }

        it { expect { subject.save! }.to raise_error ActiveRecord::RecordInvalid }
        it 'adds :add_at_least_one_responsible error to the :base key' do
          subject.valid?
          expect(subject.errors.details[:base].first)
            .to include(error: :add_at_least_one_responsible)
        end
      end

      context 'when users_attributes is not empty' do
        let!(:***REMOVED***_user) { create :***REMOVED***_user }

        context 'when adds the same users several times' do
          let(:***REMOVED***_user) { attributes_for :***REMOVED***_user }
          subject { build :active_workplace_count, users_attributes: [***REMOVED***_user, ***REMOVED***_user] }

          it { expect { subject.save! }.to raise_error ActiveRecord::RecordInvalid }
          it 'adds :multiple_user error to the :base key' do
            subject.valid?
            expect(subject.errors.details[:base].first)
              .to include(error: :multiple_user, tn: ***REMOVED***_user[:tn])
          end
        end

        context 'when adds valid users' do
          context 'and when second user also already exists in local table' do
            let!(:user) { create :user }
            subject do
              create :active_workplace_count, users_attributes: [attributes_for(:***REMOVED***_user), attributes_for(:user)]
            end

            it { expect { subject }.to change(WorkplaceResponsible, :count).by(2) }
            it { expect { subject }.not_to change(User, :count) }
          end

          context 'and when second user is not exist in local table' do
            subject do
              create :active_workplace_count, users_attributes: [attributes_for(:***REMOVED***_user), attributes_for(:user)]
            end

            it { expect { subject }.to change(WorkplaceResponsible, :count).by(2) }
            it { expect { subject }.to change(User, :count).by(1) }
          end
        end

        context 'when adds invalid user' do
          let(:invalid_user) { attributes_for :invalid_user }
          subject do
            build :active_workplace_count,
                  users_attributes: [attributes_for(:***REMOVED***_user), invalid_user]
          end

          it { expect { subject.save! }.to raise_error ActiveRecord::RecordInvalid }
          it 'adds :user_not_found error to the :base key' do
            subject.valid?
            expect(subject.errors.details[:base].first)
              .to include(error: :user_not_found, tn: invalid_user[:tn].to_s)
          end
        end
      end
    end

    describe 'update workplace_count' do
      let!(:initial_user) { create :user }
      let!(:workplace_count) { create :active_workplace_count, users: [initial_user] }
      # Загружаем отдел c использованием сервиса WorkplaceCount::Show.
      let(:loaded_workplace_count) do
        show = WorkplaceCounts::Show.new(workplace_count.workplace_count_id)
        show.data if show.run
      end
      subject do
        WorkplaceCount.includes(:users).find(loaded_workplace_count['workplace_count_id'])
      end


      context 'when removes all users' do
        let(:new_workplace_count) do
          loaded_workplace_count['users_attributes'].each { |user| user[:_destroy] = 1 }
          loaded_workplace_count
        end

        it { expect { subject.update!(new_workplace_count.deep_symbolize_keys) }
               .to raise_error ActiveRecord::RecordInvalid }
        it 'adds :save_at_least_one_responsible error to the :base key' do
          subject.update(new_workplace_count.deep_symbolize_keys)
          expect(subject.errors.details[:base].first).to include(error: :save_at_least_one_responsible)
        end
      end

      context 'when adds a few same users several times' do
        # Удаляем лишние поля (чтобы было идентично данным, отправляемым клиентом)
        let(:***REMOVED***_user) { attributes_for(:***REMOVED***_user).except(:id_tn, :division, :email, :login, :fullname) }
        # Добавляем двух одинаковых пользователей
        let(:new_workplace_count) do
          2.times { loaded_workplace_count['users_attributes'] << ***REMOVED***_user }
          loaded_workplace_count
        end

        it { expect { subject.update(new_workplace_count.deep_symbolize_keys) }
               .to raise_error ActiveRecord::RecordInvalid, /Ответственный для данного отдела с табельным ***REMOVED*** уже существует \(либо вы его задали несколько раз\)/ }
      end

      context 'when adds the user which already exist in current list of responsibles' do
        let(:new_user) { attributes_for(:user).except(:id_tn, :division, :email, :login, :fullname) }
        let(:new_workplace_count) do
          loaded_workplace_count['users_attributes'] << new_user
          loaded_workplace_count
        end

        it { expect { subject.update(new_workplace_count.deep_symbolize_keys) }
               .to raise_error ActiveRecord::RecordInvalid, /Ответственный для данного отдела с табельным 101101 уже существует \(либо вы его задали несколько раз\)/ }
      end

      context 'when adds valid user with custom phone' do
        context 'and when this user already exists in the local table of users' do
          let!(:***REMOVED***_user) { create :***REMOVED***_user }
          let(:new_user) do
            attributes_for(:***REMOVED***_user, phone: '12-34').except(:id_tn, :division, :email, :login, :fullname)
          end
          let(:new_workplace_count) do
            loaded_workplace_count['users_attributes'] << new_user
            loaded_workplace_count
          end

          it { expect { subject.update(new_workplace_count.deep_symbolize_keys) }
                 .not_to change(User, :count) }
          it { expect { subject.update(new_workplace_count.deep_symbolize_keys) }
                 .to change(WorkplaceResponsible, :count).by(1) }
        end

        context 'and when this user is not exist in the local table of users' do
          let(:new_user) do
            attributes_for(:***REMOVED***_user, phone: '12-34').except(:id_tn, :division, :email, :login, :fullname)
          end
          let(:new_workplace_count) do
            loaded_workplace_count['users_attributes'] << new_user
            loaded_workplace_count
          end

          it { expect { subject.update(new_workplace_count.deep_symbolize_keys) }
                 .to change(User, :count).by(1) }
          it { expect { subject.update(new_workplace_count.deep_symbolize_keys) }
                 .to change(WorkplaceResponsible, :count).by(1) }
        end
      end

      context 'when adds invalid user' do
        let(:invalid_user) { attributes_for(:invalid_user) }
        let(:new_workplace_count) do
          loaded_workplace_count['users_attributes'] << invalid_user
          loaded_workplace_count
        end

        it { expect { subject.update(new_workplace_count.deep_symbolize_keys) }
               .not_to change(User, :count) }
        it { expect { subject.update(new_workplace_count.deep_symbolize_keys) }
               .not_to change(WorkplaceResponsible, :count) }
        it 'adds :user_not_found error to the :base key' do
          subject.update(new_workplace_count.deep_symbolize_keys)
          expect(subject.errors.details[:base].first)
            .to include(error: :user_not_found, tn: invalid_user[:tn].to_s )
        end
      end

      context 'when user at_first removes user and than adds the same user' do
        let(:new_workplace_count) do
          # Создаем копию массива 'users_attributes' и удаляем у них 'id'
          clone_arr = loaded_workplace_count['users_attributes'].deep_dup
          clone_arr.each { |el| el['id'] = nil }

          # Изначальным элементам масива 'users_attributes' устанавливаем флаг '_destroy'
          loaded_workplace_count['users_attributes'].each { |user| user[:_destroy] = 1 }
          loaded_workplace_count['users_attributes'].concat clone_arr
          loaded_workplace_count
        end

        it { expect { subject.update(new_workplace_count.deep_symbolize_keys) }
               .to raise_error ActiveRecord::RecordInvalid, /Ответственный для данного отдела с табельным 101101 уже существует \(либо вы его задали несколько раз\)/ }
      end

      context 'when set empty phone number in one of users' do
        let(:new_workplace_count) do
          loaded_workplace_count['users_attributes'].first['phone'] = ''
          loaded_workplace_count
        end
        let(:user_iss) { build :user_iss }

        it 'search phone number in UserIss table' do
          allow(UserIss).to receive(:find_by).with(tn: initial_user.tn).and_return user_iss

          subject.update(new_workplace_count.deep_symbolize_keys)
          expect(subject.users.first.phone).to eq user_iss.tel
        end
      end

      context 'when set custom number in one of users' do
        let(:new_workplace_count) do
          loaded_workplace_count['users_attributes'].first['phone'] = '11-11'
          loaded_workplace_count
        end

        it 'update user data with new phone number' do
          subject.update(new_workplace_count.deep_symbolize_keys)
          expect(subject.users.first.phone).to eq '11-11'
        end
      end

      context 'when user full name was changed in the user_iss table' do
        let(:user_iss) { build :user_iss, fio: 'Фамилия Имя Отчество' }

        it 'update fullname attribute in local table of users' do
          allow(UserIss).to receive(:find_by).with(tn: initial_user.tn).and_return user_iss

          subject.update(loaded_workplace_count.deep_symbolize_keys)
          expect(subject.users.first.fullname).to eq user_iss.fio
        end
      end
    end
  end
end
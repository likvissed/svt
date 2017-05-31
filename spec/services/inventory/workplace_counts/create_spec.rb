require 'spec_helper'

module Inventory
  module WorkplaceCounts
    RSpec.describe Create, type: :model do
      let!(:role) { create :***REMOVED***_user_role }
      let(:test_user) { build :user }
      let(:***REMOVED***_user) { build :***REMOVED***_user }
      let(:workplace_count) do
        tmp = build(:active_workplace_count, users: [test_user, ***REMOVED***_user]).as_json(include: :users)

        tmp['users_attributes'] = tmp['users']
        tmp['users_attributes'].each do |resp|
          # Удаляем все ключи кроме 'tn'. Ключ 'phone' удалили, чтобы проверить, будет ли сервис автоматически
          # вставлять номер телефона из таблицы UserIss
          resp.keys.each { |key| resp.delete(key) unless key.to_s == 'tn' }
        end
        tmp.delete('users')

        tmp
      end

      context 'with valid workplace_count params' do
        let(:wp_resp_count) { workplace_count['users_attributes'].count }
        subject { Create.new(workplace_count) }

        its(:run) { is_expected.to be_truthy }

        context 'when all users already exists in database' do
          let!(:test_user) { create :user }
          let!(:***REMOVED***_user) { create :***REMOVED***_user }

          it 'does not save a user in database' do
            expect { subject.run }.not_to change(User, :count)
          end
        end

        context 'when one user exists and second user not exists in database' do
          let!(:test_user) { create :user }

          it 'saves a user in database' do
            expect { subject.run }.to change(User, :count).from(1).to(2)
          end

          it 'adds the :***REMOVED***_user role to created user' do
            subject.run
            expect(User.last.role).to eq role
          end
        end

        context 'when users not exists yet in database' do
          it 'saves a new users in database' do
            expect { subject.run }.to change(User, :count).by(wp_resp_count)
          end

          it 'adds the :***REMOVED***_user role to user' do
            subject.run
            expect(subject.data.users.all? { |user| user.role = Role.find_by(name: :***REMOVED***_user) })
              .to be_truthy
          end

          context 'with phone in the received params'
          context 'without phone in the received params'
        end

        context 'with multiple identical users' do
          let(:workplace_count) do
            tmp = build(:active_workplace_count, users: [test_user, test_user]).as_json(include: :users)

            tmp['users_attributes'] = tmp['users']
            tmp['users_attributes'].each do |resp|
              # Удаляем все лишние ключи
              resp.keys.each { |key| resp.delete(key) unless key.to_s == 'tn' }
            end
            tmp.delete('users')

            tmp
          end
          subject { Create.new(workplace_count) }

          context 'when user already exists in database' do
            let!(:test_user) { create :user }

            it 'creates only one record in the workplace_responsible table' do
              expect { subject.run }.to change(WorkplaceResponsible, :count).by(1)
            end

            it 'does not create user in the users table' do
              expect { subject.run }.not_to change(User, :count)
            end
          end

          context 'when user not exists yet in database' do
            it 'creates only one record in the workplace_responsible table' do
              expect { subject.run }.to change(WorkplaceResponsible, :count).by(1)
            end

            it 'create only one user in the users table' do
              expect { subject.run }.to change(User, :count).by(1)
            end
          end
        end

        context 'when user sets a phone manually' do
          context 'when user not exist' do
            let(:test_user) { build(:user, phone: '12-34') }
            let(:workplace_count) do
              tmp = build(:active_workplace_count, users: [test_user]).as_json(include: :users)

              tmp['users_attributes'] = tmp['users']
              tmp['users_attributes'].each do |resp|
                # Удаляем все ключи кроме 'tn' и 'phone'. Это те параметры, коорые задает пользователь.
                resp.keys.each { |key| resp.delete(key) unless %w[tn phone].include? key.to_s }
              end
              tmp.delete('users')

              tmp
            end
            subject { Create.new(workplace_count) }

            it 'saves the user with specified phone in the users table' do
              subject.run
              expect(User.last.phone).to eq test_user.phone
            end
          end
        end

        it 'creates instance of the WorkplaceCount model' do
          subject.run
          expect(subject.data).to be_instance_of WorkplaceCount
        end

        include_examples 'run methods', %w[get_responsible_data save_workplace]

        it 'saves a new workplace_count in the database' do
          expect { subject.run }.to change(WorkplaceCount, :count).by(1)
        end

        it 'saves a new workplace_responsibles in the database' do
          expect { subject.run }.to change(WorkplaceResponsible, :count).by(wp_resp_count)
        end
      end

      context 'with invalid workplace_count params' do
        context 'without users' do
          let(:wrong_workplace_count) { attributes_for :active_workplace_count }
          subject { Create.new(wrong_workplace_count) }

          its(:run) { is_expected.to be_falsey }

          it 'includes object and full_message keys into the @error object' do
            subject.run
            expect(subject.error).to include(:object, :full_message)
          end

          it 'adds :add_at_least_one_responsible error to the :base object' do
            subject.run
            expect(subject.error[:object].details[:base]).to include(error: :add_at_least_one_responsible)
          end
        end

        context 'with users and without main params' do
          let(:wrong_workplace_count) do
            workplace_count.delete('division')
            workplace_count.delete('time_start')
            workplace_count.delete('time_end')

            workplace_count
          end
          subject { Create.new(wrong_workplace_count) }

          its(:run) { is_expected.to be_falsey }

          it 'includes object and full_message keys into the @error object' do
            subject.run
            expect(subject.error).to include(:object, :full_message)
          end

          it 'adds :division, :time_start and :time_end errors to the object' do
            subject.run
            expect(subject.error[:object].details).to include(:division, :time_start, :time_end)
          end
        end
      end
    end
  end
end
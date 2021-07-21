module Api
  module V1
    module Invent
      class ItemsController < ApplicationController
        skip_before_action :authenticate_user!

        def index
          result = if params[:invent_num].present?
                     ::Invent::Item
                       .where(invent_num: params[:invent_num], status: :in_workplace)
                       .includes(%i[type model barcode_item])
                       .as_json(
                         include: [
                           :barcode_item,
                           {
                             type: {
                               except: %i[create_time modify_time]
                             }
                           }
                         ],
                         except: %i[create_time modify_time],
                         methods: :short_item_model
                       )
                   elsif params[:tn].present?
                     user = User.find_by(tn: params[:tn])
                     employee = UsersReference.info_users("personnelNo==#{params[:tn]}")

                     if user.present? && employee.first.present? && employee.first.try(:[], 'departmentForAccounting').present? &&
                        user.workplace_responsibles.find_by(workplace_count: ::Invent::WorkplaceCount.find_by(division: employee.first.try(:[], 'departmentForAccounting'))).present?

                       items = ::Invent::Item
                                 .includes(:barcode_item, :model, :type, { workplace: %i[workplace_count] })
                                 .where(status: :in_workplace)
                                 .by_division(employee.first.try(:[], 'departmentForAccounting'))
                                 .as_json(
                                   include: [
                                     :barcode_item,
                                     {
                                       type: { except: %i[create_time modify_time] }
                                     },
                                     {
                                       workplace: {
                                         except: %i[create_time]
                                       }
                                     }
                                   ],
                                   except: %i[create_time modify_time],
                                   methods: :short_item_model
                                 )

                       employee_list = items.map { |it| it['workplace']['id_tn'] }

                       employees_wp = UsersReference.info_users("id=in=(#{employee_list.compact.join(',')})")
                       items.each do |it|
                         employee = employees_wp.find { |emp| emp['id'] == it['workplace']['id_tn'] }

                         it['fio_user_iss'] = employee.present? ? employee['fullName'] : 'Ответственный не найден'
                       end
                       items
                     else
                       []
                     end
                   else
                     []
                   end

          render json: result
        end
      end
    end
  end
end

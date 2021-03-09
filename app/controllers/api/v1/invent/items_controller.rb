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

                     if user.try(:user_iss).present? &&
                        user.workplace_responsibles.find_by(workplace_count: ::Invent::WorkplaceCount.find_by(division: user.user_iss.dept)).present?

                       ::Invent::Item
                         .includes(:barcode_item, :model, :type, { workplace: %i[user_iss workplace_count] })
                         .where(status: :in_workplace)
                         .by_division(user.user_iss.dept)
                         .as_json(
                           include: [
                             :barcode_item,
                             {
                               type: { except: %i[create_time modify_time] }
                             },
                             {
                               workplace: {
                                 except: %i[create_time],
                                 include: {
                                   user_iss: { only: :fio }
                                 }
                               }
                             }
                           ],
                           except: %i[create_time modify_time],
                           methods: :short_item_model
                         )
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

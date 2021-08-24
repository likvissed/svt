module Api
  module V2
    module Invent
      class ItemsController < ApplicationController
        skip_before_action :authenticate_user!

        # Получение объекта техники (на РМ) по штрих-коду (barcode)
        def barcode
          @barcode = Barcode
                       .includes(codeable: [:type, :model, :barcode_item, { workplace: %i[workplace_type iss_reference_site iss_reference_building iss_reference_room] }])
                       .find_by(codeable_type: 'Invent::Item', id: params[:barcode])

          barcode_item = @barcode
                           .as_json(include: {
                                      codeable: {
                                        include: [
                                          :barcode_item,
                                          {
                                            type: { except: %i[create_time modify_time] }
                                          },
                                          {
                                            workplace: {
                                              include: [
                                                :workplace_type,
                                                :iss_reference_site,
                                                :iss_reference_building,
                                                {
                                                  iss_reference_room: { except: :security_category_id }
                                                }
                                              ],
                                              except: %i[create_time]
                                            }
                                          }
                                        ],
                                        except: %i[create_time modify_time],
                                        methods: :short_item_model
                                      }
                                    })

          result = barcode_item.present? && barcode_item['codeable']['status'] == 'in_workplace' ? barcode_item['codeable'] : {}

          render json: result
        end

        # Получение массива техники (на РМ) по любому из параметров: %i[fio invent_num barcode dept id_tn]
        def search_items
          workplace_count = params[:dept].present? ? ::Invent::WorkplaceCount.find_by(division: params[:dept]) : ''

          if (params[:dept].present? && workplace_count.blank?) || (params[:barcode].present? && params[:barcode].scan(/\D/).empty? == false) ||
             (params[:fio].blank? && params[:invent_num].blank? && params[:barcode].blank? && params[:dept].blank? && params[:id_tn].blank?)
            render json: []
          else
            filtering_params = {}
            filtering_params[:responsible] = params[:fio]
            filtering_params[:invent_num] = params[:invent_num]
            filtering_params[:barcode_item] = params[:barcode]
            filtering_params[:workplace_count_id] = workplace_count.try(:workplace_count_id)
            filtering_params[:id_tn] = params[:id_tn]

            result = ::Invent::Item
                       .filter(filtering_params)
                       .where(status: :in_workplace)
                       .includes(:type, :model, :barcode_item, { workplace: %i[workplace_type iss_reference_site iss_reference_building iss_reference_room] })
                       .as_json(
                         include: [
                           :barcode_item,
                           {
                             workplace: {
                               include: [
                                 :workplace_type,
                                 :iss_reference_site,
                                 :iss_reference_building,
                                 {
                                   iss_reference_room: { except: :security_category_id }
                                 }
                               ],
                               except: %i[create_time]
                             }
                           },
                           {
                             type: {
                               except: %i[create_time modify_time]
                             }
                           }
                         ],
                         except: %i[create_time modify_time],
                         methods: :short_item_model
                       )

            if result.present?
              # Для того, чтобы предотвратить ошибку большого запроса в НСИ
              result.each_slice(500) do |items|
                employee_list = items.map { |it| it['workplace']['id_tn'] }
                employees_wp = UsersReference.info_users("id=in=(#{employee_list.compact.join(',')})")
                items.each do |item|
                  next if item['workplace'].blank?

                  employee = employees_wp.find { |emp| emp['id'] == item['workplace']['id_tn'] }
                  item['workplace']['user_fio'] = employee.present? ? employee['fullName'] : 'Ответственный не найден'
                end
              end
            end

            render json: result
          end
        end
      end
    end
  end
end

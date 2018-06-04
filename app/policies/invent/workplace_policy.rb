module Invent
  class WorkplacePolicy < ApplicationPolicy
    def ctrl_access?
      return true if admin?

      if user.role? :***REMOVED***_user
        user.workplace_counts.any?
      elsif user.one_of_roles? :manager, :worker, :read_only
        true
      else
        false
      end
    end

    def new?
      return true if admin?

      if user.role? :***REMOVED***_user
        user.workplace_counts.any?
        #division_access? && allowed_time?
      elsif user.one_of_roles? :manager, :worker
        true
      else
        false
      end
    end

    # Есть ли у пользователя доступ на создание РМ указанного отдела.
    def create?
      return true if admin?

      if user.role? :***REMOVED***_user
        record.status = :pending_verification
        division_access? && allowed_time?
      elsif user.one_of_roles? :manager, :worker
        true
      else
        false
      end
    end

    # Если роль '***REMOVED***_user': есть ли у пользователя доступ на редактирование РМ указанного отдела.
    # Если роль 'manager': доступ есть
    def edit?
      return true if admin?

      if user.role? :***REMOVED***_user
        division_access? && allowed_time? && access_to_edit?
      elsif user.one_of_roles? :manager, :worker, :read_only
        true
      else
        false
      end
    end

    # Если роль '***REMOVED***_user': есть ли у пользователя доступ на редактирование РМ указанного отдела.
    # Если роль 'manager': доступ есть
    def update?
      return true if admin?

      if user.role? :***REMOVED***_user
        if division_access? && allowed_time? && access_to_edit?
          record.status = :pending_verification
          true
        else
          false
        end
      elsif user.one_of_roles? :manager, :worker
        true
      else
        false
      end
    end

    # Если роль '***REMOVED***_user': есть ли у пользователя доступ на удаление РМ указанного отдела.
    # Если роле не '***REMOVED***_user', но ответственный за отдел + доступ по времени открыт: доступ есть
    # def destroy?
    #   return true if admin?

    #   if user.role? :***REMOVED***_user
    #     division_access? && allowed_time? && !confirmed?
    #   elsif user.role? :manager
    #     true
    #   else
    #     false
    #   end
    # end

    def destroy?
      return true if admin?

      user.one_of_roles? :manager, :worker
    end

    def hard_destroy?
      return true if admin?

      user.one_of_roles? :manager, :worker
    end

    class Scope < Scope
      def resolve
        if user.role? :***REMOVED***_user
          divisions = user.workplace_counts.pluck(:division)
          scope.left_outer_joins(:workplace_count).where("invent_workplace_count.division IN (#{divisions.empty? ? 'NULL' : divisions.join(', ')})")
        else
          scope.all
        end
      end
    end

    def permitted_attributes
      if user.role? :***REMOVED***_user
        [
          :workplace_id,
          :workplace_count_id,
          :workplace_type_id,
          :workplace_specialization_id,
          :id_tn,
          :location_site_id,
          :location_building_id,
          :location_room_name,
          :location_room_id,
          :comment,
          item_ids: [],
          items_attributes: [
            :id,
            :parent_id,
            :type_id,
            :model_id,
            :item_model,
            :workplace_id,
            :location,
            :invent_num,
            :serial_num,
            :_destroy,
            property_values_attributes: %i[id property_id item_id property_list_id value _destroy]
          ]
        ]
      else
        [
          :workplace_id,
          :disabled_filters,
          :workplace_count_id,
          :workplace_type_id,
          :workplace_specialization_id,
          :id_tn,
          :location_site_id,
          :location_building_id,
          :location_room_name,
          :location_room_id,
          :comment,
          :status,
          item_ids: [],
          items_attributes: [
            :id,
            :parent_id,
            :type_id,
            :model_id,
            :item_model,
            :workplace_id,
            :location,
            :invent_num,
            :serial_num,
            :status,
            :_destroy,
            property_values_attributes: %i[id property_id item_id property_list_id value _destroy]
          ]
        ]
      end
    end

    protected

    # Есть ли доступ на работу с РМ указанного отдела.
    def division_access?
      user.workplace_counts.pluck(:division).any? { |division| division == record.workplace_count.division }
    end

    # Не прошло ли разрешенное время редактирования.
    def allowed_time?
      Time.zone.today.between? record.workplace_count.time_start, record.workplace_count.time_end
    end

    # Подтверждено ли рабочее место.
    def confirmed?
      record.status == 'confirmed'
    end

    def access_to_edit?
      %w[pending_verification disapproved].include?(record.status)
    end
  end
end

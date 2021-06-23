module Warehouse
  class OrderPolicy < Warehouse::ApplicationPolicy
    def new?
      for_worker
    end

    def create_in?
      for_worker
    end

    def create_out?
      record.set_validator(user) if for_manager
      for_worker
    end

    def create_write_off?
      record.set_validator(user) if for_manager
      for_worker
    end

    def update_in?
      for_worker
    end

    def update_out?
      record.set_validator(nil) if user.role? :worker

      for_worker
    end

    def update_write_off?
      record.set_validator(nil) if user.role? :worker

      for_worker
    end

    def confirm?
      for_manager
    end

    def execute_in?
      for_worker
    end

    def execute_out?
      for_worker
    end

    def execute_write_off?
      for_worker
    end

    def prepare_to_deliver?
      for_worker
    end

    def print?
      for_worker
    end

    def assign_operation_receiver?
      for_worker
    end

    def permitted_attributes
      if for_manager
        [
          :id,
          :invent_workplace_id,
          :creator_id_tn,
          :consumer_id_tn,
          :consumer_tn,
          :validator_id_tn,
          :request_num,
          :invent_num,
          :operation,
          :status,
          :creator_fio,
          :consumer_fio,
          :validator_fio,
          :consumer_dept,
          :comment,
          :dont_calculate_status,
          operations_attributes: [
            :id,
            :item_id,
            :location_id,
            :stockman_id_tn,
            :operationable_id,
            :operationable_type,
            :item_type,
            :item_model,
            :shift,
            :stockman_fio,
            :warehouse_receiver_fio,
            :status,
            :date,
            :_destroy,
            :to_write_off,
            :w_item_id,
            inv_item_ids: [],
            inv_items_attributes: [
              :id,
              :serial_num,
              :invent_num,
              :codeable_type,
              :_destroy
            ],
            location: %i[
              id
              site_id
              building_id
              room_id
              comment
              name
            ]
          ]
        ]
      else
        [
          :id,
          :invent_workplace_id,
          :creator_id_tn,
          :consumer_id_tn,
          :consumer_tn,
          :request_num,
          :invent_num,
          :operation,
          :status,
          :creator_fio,
          :consumer_fio,
          :consumer_dept,
          :comment,
          :dont_calculate_status,
          operations_attributes: [
            :id,
            :item_id,
            :location_id,
            :stockman_id_tn,
            :operationable_id,
            :operationable_type,
            :item_type,
            :item_model,
            :shift,
            :stockman_fio,
            :warehouse_receiver_fio,
            :status,
            :date,
            :_destroy,
            :to_write_off,
            inv_item_ids: [],
            inv_items_attributes: [
              :id,
              :serial_num,
              :invent_num,
              :_destroy
            ]
          ]
        ]
      end
    end
  end
end
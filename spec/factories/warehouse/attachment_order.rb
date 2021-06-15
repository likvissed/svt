module Warehouse
  FactoryBot.define do
    factory :attachment_order, class: AttachmentOrder do
      order { Order.find_by(id: order_id) }
      document { Rack::Test::UploadedFile.new(Rails.root.join('spec/files/old_pc_config.txt'), 'text/plain') }
    end
  end
end

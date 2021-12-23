module Warehouse
  FactoryBot.define do
    factory :attachment_request, class: AttachmentRequest do
      document { Rack::Test::UploadedFile.new(Rails.root.join('spec/files/old_pc_config.txt'), 'text/plain') }
      is_public { true }
    end
  end
end

module Invent
  FactoryBot.define do
    factory :attachment, class: Attachment do
      workplace { Workplace.find_by(workplace_id: workplace_id) }
      document { Rack::Test::UploadedFile.new(Rails.root.join('spec/files/old_pc_config.txt'), 'text/plain') }
    end

    factory :attachment_blank, class: Attachment do
      workplace { Workplace.find_by(workplace_id: workplace_id) }
    end
  end
end

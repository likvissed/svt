module Warehouse
  shared_examples ':cannot_update_done_operation error' do
    it 'adds :cannot_update_done_operation' do
      subject.save
      expect(subject.errors.details[:base]).to include(error: :cannot_update_done_operation)
    end
  end
end
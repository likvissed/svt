require 'spec_helper'

module Invent
  RSpec.describe PcFile, type: :model do
    let(:old_file) do
      Rack::Test::UploadedFile.new(
        Rails.root.join('spec', 'files', 'old_pc_config.txt'),
        'text/plain'
      )
    end
    let(:pc_instance) { PcFile.new(0, old_file) }
    before { pc_instance.upload }

    context 'when file is uploading' do
      context 'when directory not exists' do
        it 'creates directory and saves file into it' do
          expect(File).to exist pc_instance.path_to_file
        end
      end

      context 'when directory exists' do
        let(:new_file) do
          Rack::Test::UploadedFile.new(
            Rails.root.join('spec', 'files', 'new_pc_config.txt'),
            'text/plain'
          )
        end
        let(:new_pc_instance) { PcFile.new(0, new_file) }
        before { new_pc_instance.upload }

        it 'deletes all files from directory' do
          expect(File).not_to exist pc_instance.path_to_file
        end

        it 'saves new file into directory' do
          expect(File).to exist new_pc_instance.path_to_file
        end
      end
    end

    context 'when file is removing' do
      it 'removes directory which includes file' do
        pc_instance.destroy
        expect(File).not_to exist pc_instance.path_to_file_dir
      end
    end
  end
end

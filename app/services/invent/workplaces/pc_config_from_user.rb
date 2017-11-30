module Invent
  module Workplaces
    # Декодировать данные, полученные программой SysInfo
    class PcConfigFromUser < BaseService
      def initialize(file)
        @file = file
      end

      def run
        match_data

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      private

      def match_data
        chr_code_arr = @file.read.chars.map { |chr| chr.ord ^ ENV['PC_CONFIG_KEY'].to_i }
        @data = chr_code_arr.pack('C*').force_encoding('utf-8')
        return data if data.valid_encoding?
        @data.force_encoding('ISO-8859-1').encode('utf-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      end
    end
  end
end

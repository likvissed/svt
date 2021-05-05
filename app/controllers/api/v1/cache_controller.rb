module Api
  module V1
    class CacheController < ApplicationController
      skip_before_action :authenticate_user!

      def clear
        Rails.logger.info "clear_cache_app: #{Rails.cache.instance_variable_get(:@data).keys}".red
        Rails.cache.clear

        render json: 'Cache is clear'
      end
    end
  end
end

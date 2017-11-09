module Invent
  class ItemsController < ApplicationController
    def index
      respond_to do |format|
        format.html
        format.json do
          @index = Items::Index.new(params)

          if @index.run
            render json: @index.data
          else
            render json: { full_message: 'Ошибка. Обратитесь к администратору, т.***REMOVED***' }, status: 422
          end
        end
      end
    end
  end
end

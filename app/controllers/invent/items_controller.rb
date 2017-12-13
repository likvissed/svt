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

    def busy
      @busy = Items::Busy.new(params[:type_id], params[:invent_num])

      if @busy.run
        render json: @busy.data
      else
        render json: { full_message: 'Ошибка. Обратитесь к администратору, т.***REMOVED***' }, status: 422
      end
    end

    def show
      @show = Items::Show.new(params[:item_id])

      if @show.run
        render json: @show.data
      else
        render json: { full_message: @show.errors.full_messages.join('. ') }, status: 422
      end
    end

    def avaliable
      @avaliable = Items::Avaliable.new(params[:type_id])
      
      if @avaliable.run
        render json: @avaliable.data
      else
        render json: { full_message: 'Ошибка. Обратитесь к администратору, т.***REMOVED***' }, status: 422
      end
    end
  end
end

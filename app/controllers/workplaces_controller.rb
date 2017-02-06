class WorkplacesController < ApplicationController

  def index
    respond_to do |format|
      format.html
      format.json do
        # @workplaces = Workplace.all
        render json: [
          { name: 'Место-***REMOVED***-1', type: 'Конструкторское', responsible: '***REMOVED*** Р.Ф.', location: '3а-321а', count: 4},
          { name: 'Место-***REMOVED***-2', type: 'Офисное', responsible: '***REMOVED*** Р.Ф.', location: '3а-321а', count: 2}
        ]
      end
    end
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end

end

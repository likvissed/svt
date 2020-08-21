require 'application_responder'

class ApplicationController < ActionController::Base
  include Pundit

  self.responder = ApplicationResponder

  layout :layout
  protect_from_forgery with: :exception
  after_action :set_csrf_cookie_for_ng
  after_action :user_activity
  before_action :authenticate_user!
  before_action :add_attr_to_current_user, if: -> { current_user }
  # before_action :authorization, if: -> { current_user }

  # Обрабтка случаев, когда у пользователя нет доступа на выполнение запрашиваемых действий
  rescue_from Pundit::NotAuthorizedError do |exception|
    respond_to do |format|
      format.html { render_403 }
      format.json { render json: { full_message: I18n.t('controllers.app.access_denied') }, status: 403 }
    end
  end

  # XSRF for angularjs
  def set_csrf_cookie_for_ng
    cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  end

  def render_403
    render file: Rails.root.join('public', '403.html'), status: 403, layout: false
  end

  def render_404
    render file: Rails.root.join('public', '404.html'), status: 404, layout: false
  end

  def render_500
    render file: Rails.root.join('public', '500.html'), status: 500, layout: false
  end

  # Если у пользователя есть доступ, в ответ присылается html-код кнопки "Добавить" для создания новой записи
  # Запрос отсылается из JS файла при инициализации таблицы
  def link_to_new_record
    case params[:ctrl_name]
    when 'workplace_counts'
      class_name = Invent::WorkplaceCount
      type = :modal
      attrs = 'ng-click="wpCount.openWpCountEditModal()"'
    when 'workplaces'
      class_name = Invent::Workplace
      type = :page
      attrs = "href=#{new_invent_workplace_path}"
    end

    link = create_link_to_new_record(type, class_name, attrs)

    render json: link
  end

  protected

  # XSRF for angularjs
  def verified_request?
    super || valid_authenticity_token?(session, request.headers['X-XSRF-TOKEN'])
  end

  # Создать html-строку с содержимым, зависящим от прав доступа пользователя
  # Запрос на данный метод генерирует директива addRecord, которая рендерит полученную строку.
  #
  # type    - тип контента, на который будет ссылаться ссылка
  #   (modal - модальное окно текущей страницы, page - новая страница)
  # object  - модель
  # params  - строка, содержащая атрибуты, необходиые для html тега (для разных типо разные атрибуты)
  def create_link_to_new_record(type, object, params)
    # if can? :manage, object
    if type == :modal
      "<button class='btn btn-primary btn-block btn-sm' #{params}>Добавить</button>"
    elsif type == :page
      # "<form class='button_to' method='get' action='#{params}'>
      #   <input class='btn btn-primary btn-block btn-sm' type='submit' value='Добавить'>
      # </form>"
      "<a class='btn btn-primary btn-block btn-sm' #{params}>Добавить</a>"
    end
  end

  private

  def add_attr_to_current_user
    current_user.access_token = session[:access_token]
  end

  # Чтобы после выхода редиректил на страницу входа
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  # Куда перенаправлять после авторизации
  def after_sign_in_path_for(resource_or_scope)
    session['user_return_to'] || invent_workplaces_path
  end

  # Определяем, какой layout выводить: для входа в систему или основной
  def layout
    is_a?(Devise::SessionsController) ? 'sign_in_app' : 'application'
  end

  # Проверка роли перед доступом к контроллерам
  # def authorization
  #   authorize :application, :authorization?
  # end

  def user_activity
    current_user.try(:touch)
  end
end

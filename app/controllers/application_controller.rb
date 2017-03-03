require "application_responder"

class ApplicationController < ActionController::Base
  self.responder = ApplicationResponder

  layout :layout
  protect_from_forgery with: :exception
  after_action :set_csrf_cookie_for_ng
  before_action :authenticate_user!

  # Обрабтка случаев, когда у пользователя нет доступа на выполнение запрашиваемых действий
  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html do
        render_403
      end
      format.json { render json: { full_message: "Доступ запрещен" }, status: :forbidden }
    end
  end

  # XSRF for angularjs
  def set_csrf_cookie_for_ng
    cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  end

  def render_403
    render file: "#{Rails.root}/public/403.html", status: 403, layout: false
  end

  def render_404
    render file: "#{Rails.root}/public/404.html", status: 404, layout: false
  end

  def render_500
    render file: "#{Rails.root}/public/500.html", status: 500, layout: false
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
      "<button class='btn btn-primary btn-block' #{params}>Добавить</button>"
    elsif type == :page
      "<form class='button_to' method='get' action='#{params}'>
        <input class='btn btn-primary btn-block' type='submit' value='Добавить'>
      </form>"
    end
  end

  private

  # Определяем, какой layout выводить: для входа в систему или основной
  def layout
    is_a?(Devise::SessionsController) ? "sign_in_app" : "application"
  end
end

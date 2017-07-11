module ApplicationHelper
  def title(page_title)
    content_for :title, page_title.to_s
  end
  
  def active_class(path)
    # current_page?(path) ? 'active' : ''
    request.fullpath.include?(path) ? 'active' : ''
  end
end

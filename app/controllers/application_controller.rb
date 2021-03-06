class ApplicationController < ActionController::Base
  include ApplicationHelper
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :set_locale
  before_filter :show_navbar
  helper_method :get_current_user, :get_current_folder, :set_current_folder, :get_user_folders, :get_not_children_folders
  helper_method :redirect_to_mytopbox, :redirect_to_current_folder
  helper_method :find_mytopbox
  helper_method :all_users_except_current


  def set_locale
    if cookies[:educator_locale] && I18n.available_locales.include?(cookies[:educator_locale].to_sym)
      l = cookies[:educator_locale].to_sym
    else
      l = I18n.default_locale
      cookies.permanent[:educator_locale] = l
    end
    I18n.locale = l
  end

  def get_current_user
    User.find(session[:user_id]) if session[:user_id]
  end

  def get_current_folder
    current_folder = Folder.find(session[:current_folder_id]) if session[:user_id]
    return (current_folder ||= Folder.find_by(name: MAIN_FOLDER_NAME, user_id: get_current_user.id))
  end

  def set_current_folder(folder)
    session[:current_folder_id] = folder.id 
  end

  
  def require_user
    redirect_to LOGIN_URL unless logged_in?
  end

  def has_active_session?
    if session[:user_id]
      redirect_to_mytopbox
      return false
    else
      return true
    end
  end

  def log_out
    session[:user_id] = nil
  end

  def log_in(user)
    session[:user_id] = user.id
  end

  def logged_in?
    !get_current_user.nil?
  end

  def get_not_children_folders(children)
    @result = []
    folders = get_user_folders.where('id != ?', get_current_folder.id)
    get_children_folders(children.to_ary)
    return folders - @result
  end

  private
  def get_children_folders(children)
    if children.length != 0
      children.each do |c|
        child = []
        child.push(c)
        @result += child
        get_children_folders(c.children.to_ary)
      end
    end
  end

  protected
  def show_navbar
    @show_navbar = true
  end

  def redirect_to_mytopbox
    my_topbox = Folder.find_by(name: MAIN_FOLDER_NAME, user_id: get_current_user.id)
    my_topbox_id = my_topbox.id.to_s
    redirect_to MAIN_FOLDER_PATH + my_topbox_id
  end

  def redirect_to_current_folder
    redirect_to MAIN_FOLDER_PATH + get_current_folder.id.to_s
  end

  def find_mytopbox
    Folder.find_by(name: MAIN_FOLDER_NAME, user_id: get_current_user.id)
  end

  def get_user_folders
    Folder.where(user_id: get_current_user.id)
  end

  def all_users_except_current
    User.where('id != ?', get_current_user.id)
  end

end
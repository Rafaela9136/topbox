class DocumentsController < ApplicationController
  include DocumentsHelper, ApplicationHelper
  helper_method :share, :user, :download, :recycle

  def user
    return @document.folder.user
  end

  def new
    @document = Document.new
  end

  def create
    @file = params.delete(:file)
    @document = Document.new(get_document_params)
    @document.folder = get_current_folder
    privacy = Privacy.new
    privacy.shareable = @document
    @document.privacy = privacy
    if @file 
      @document.content = file.read
    end
    if @document.save
      redirect_to_current_folder
    end
  end

  def index
    @documents = Document.all
  end

  def show
    @document = Document.find(params[:id])
      unless has_read_permission? 
        render "permissions/denied"
      end
      if @document.trash
        render "permissions/denied"
      end
  end

  def move_to_trash
    @document = Document.find(params[:id])
    @document.make_trash 
    redirect_to_current_folder
  end

  def recycle
    @document = Document.find(params[:id])
    @document.update trash: false
    @document.make_recycle
    redirect_to @document
  end

  def download
    @document = Document.find(params[:id])
    filename = @document.name + "." + @document.extension
    send_data @document.content, :filename => filename
  end

  def destroy
    @document = Document.find(params[:id])
    @document.destroy
    redirect_to MAIN_FOLDER_PATH + get_current_folder.id.to_s
  end

  def edit
    @document = Document.find(params[:id])
    unless (has_edit_permission? and !@document.trash)
      redirect_to MAIN_FOLDER_PATH
    end
  end

  def share
    @document = Document.find(params[:id])
    redirect_to share_permission_path + '?d='+@document.id.to_s
  end

  def update
    @document = Document.find params[:id]
    unless (@document.user != get_current_user)
      folder_id = params.require(:document).require(:folder)
      @folder = Folder.find(folder_id)
      @document.folder = @folder
    end
    @document.update_attributes(get_document_params)
    
    redirect_to action: ACTION_SHOW, id: @document
  end

  def compress
    @document = Document.find(params[:id])
    compression_method = get_compression_method(params[:compression_method])
    @document.content = compression_method.compress(@document.content)
    @document.name += ('.' + @document.extension)
    @document.extension = compression_method.get_extension
    @document.save
    redirect_to :controller => 'folders', :action => 'index'
  end

  def decompress
    @document = Document.find(params[:id])
    compression_method = get_compression_method(@document.extension)
    @document.content = compression_method.decompress(@document.content)
    @document.extension = get_extension_out_of_name(@document.name)
    @document.name = @document.name[0..(-@document.extension.length - 2)]
    @document.save
    redirect_to :controller => 'folders', :action => 'index'
  end
  
  private
  def get_document_params
    params.require(:document).permit(:name, :content, :extension, :file)
  end

    def has_edit_permission?
    return true if is_in_user_folders?(@document.folder)
    @document.privacy.permissions.each do |permission|
      return true if ((permission.user_id == get_current_user.id) and permission.Editar?)
    end
    return false
  end

  def has_read_permission?
    return true if @document.privacy.open?
    return false if get_current_user.nil?
    return true if has_edit_permission?
    @document.privacy.permissions.each do |permission|
      return true if (permission.user_id == get_current_user.id)
    end
    return false
  end

  def is_in_user_folders?(folder)
    return false if folder.nil?
    if folder.user == get_current_user
      return true
    else
      return is_in_user_folders?(folder.parent)
    end
  end

  def get_compression_method(extension)
    if extension == GzipMethod.get_extension
      return GzipMethod
    elsif extension == ZipMethod.get_extension
      return ZipMethod
    end
  end

end
Monatomic::Application.class_eval do
  get "/" do
    if current_user
      erb :home
    else
      erb :login, layout: false
    end
  end

  # login
  post "/" do
    user = User.where(email: params[:email]).first
    if user and user.validate_password(params[:password])
      session[:uid] = user.id.to_s
    else
      session[:flash] = "用户名/密码错误"
    end
    redirect "/"
  end

  get "_logout" do
    session.delete :uid
    redirect "/"
  end

  # index
  get "/:resources" do
    require_user_and_prepare_resources
    @fields = @model.fields_for(current_user)
    erb :index
  end

  # create
  post "/:resources" do
    require_user_and_prepare_resources
    @resource = @resources.new
    params["data"].each do |k, v|
      unless @resource.writable? current_user, k
        @resource.errors.add(k, "is not allowed to set to \"#{v}\"")
      end
    end
    @resource.assign_attributes(params["data"])
    if @resource.errors.blank? and @resource.save
      session[:flash] = "Create %s \"%s\" successfully" % [@model.display_name, @resource.display_name]
      redirect model_path(@resource.id)
    else
      erb :edit
    end
  end

  # new
  get "/:resources/new" do
    require_user_and_prepare_resources
    @resource = @resources.new
    erb :edit
  end

  # show
  get "/:resources/:id" do
    require_user_and_prepare_resources
    @fields = @model.fields_for(current_user)
    erb :show
  end

  # update
  # We use post for best compatibility
  post "/:resources/:id" do
    require_user_and_prepare_resources
    params["data"].each do |k, v|
      unless @resource.writable? current_user, k
        @resource.errors.add(k, "is not allowed to set to \"#{v}\"")
      end
    end
    @resource.assign_attributes(params["data"])
    if @resource.errors.blank? and @resource.save
      session[:flash] = "Update %s \"%s\" successfully" % [@model.display_name, @resource.display_name]
      redirect model_path(@resource.id)
    else
      erb :edit
    end
  end

  # edit
  get "/:resources/:id/edit" do
    require_user_and_prepare_resources
    erb :edit
  end

  # delete
  post "/:resources/:id/delete" do
    require_user_and_prepare_resources
    @resource.destroy if @resource.deletable? current_user
    session[:flash] = "Delete %s \"%s\" successfully" % [@model.display_name, @resource.display_name]
    redirect model_path
  end

  def require_user_and_prepare_resources
    redirect "/" unless current_user
    begin
      @model = params[:resources].classify.constantize
    rescue NameError
    end
    @resources = @model && @model.for(current_user)
    halt 403 if @resources.nil?
    return if params[:id].blank?
    @resource = @resources.find(params[:id])
  end
end

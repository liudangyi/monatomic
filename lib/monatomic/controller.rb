Monatomic::Application.class_eval do
  get "/" do
    session.delete(:uid) if params[:logout]
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

  before "/:resources" do
    redirect "/" unless current_user
    @model = params[:resources].classify.constantize
    @fields = @model.fields_for(current_user)
  end

  before "/:resources/*" do
    redirect "/" unless current_user
    @model = params[:resources].classify.constantize
    @fields = @model.fields_for(current_user)
  end

  # index
  get "/:resources" do
    @resources = @model.all
    erb :index
  end

  # create
  post "/:resources" do
    params[:resources]
  end

  # new
  get "/:resources/new" do
    params[:resources]
  end

  # show
  get "/:resources/:id" do
    params.inspect
  end

  # update
  # We use post for best compatibility
  post "/:resources/:id" do
    params.inspect
  end

  # edit
  get "/:resources/:id/edit" do
    params.inspect
  end

  # destroy
  post "/:resources/:id/destroy" do
    params.inspect
  end
end

require "rubyXL"

Monatomic::Application.class_exec do
  get "/" do
    if current_user
      erb :home
    else
      erb :login, layout: false
    end
  end

  # login
  post "/" do
    user = User.where(uid: params[:uid]).first if params[:uid].present?
    if user and user.validate_password(params[:password])
      session[:uid] = user.id.to_s
    else
      session[:flash] = t(:wrong_username_or_password)
    end
    redirect "/"
  end

  get "/_logout" do
    session.delete :uid
    redirect "/"
  end

  # index
  get "/:resources.?:format?" do
    require_user_and_prepare_resources
    @fields = @model.fields_for(current_user)
    case params[:format]
    when "json"
      content_type :json
      @resources.to_json(user: current_user)
    when "xlsx"
      send_xlsx
    else
      @columns = @model.fields_for(current_user, limit: @model.display_fields)
      erb :index
    end
  end

  # create
  post "/:resources" do
    require_user_and_prepare_resources
    @resource = @resources.new(created_by: current_user)
    params["data"].each do |k, v|
      unless @resource.writable? current_user, k
        @resource.errors.add(k, t(:not_allowed) % v)
      end
    end
    @resource.assign_attributes(params["data"])
    if @resource.valid? and @resource.save
      session[:flash] = t(:create_successfully) % [t(@model), @resource.display_name]
      redirect path_for(@resource.id)
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
  get "/:resources/:id.?:format?" do
    require_user_and_prepare_resources
    @fields = @model.fields_for(current_user)
    if params[:format] == "json"
      content_type :json
      @resource.to_json(user: current_user)
    else
      erb :show
    end
  end

  # update
  # We use post for best compatibility
  post "/:resources/:id" do
    require_user_and_prepare_resources
    params["data"].each do |k, v|
      unless @resource.writable? current_user, k
        @resource.errors.add(k, t(:not_allowed) % v)
      end
      # https://github.com/rails/rails/blob/71c7fd101324046995d8f7e51e78475c0e37ec1a/actionview/lib/action_view/helpers/form_options_helper.rb#L140
      v.shift if v.is_a? Array
    end
    if @resource.errors.empty? and @resource.assign_attributes(params["data"]) and @resource.valid? and @resource.save
      session[:flash] = t(:update_successfully) % [@model.display_name, @resource.display_name]
      redirect path_for(@resource.id)
    else
      @resource.assign_attributes(params["data"])
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
    session[:flash] = t(:delete_successfully) % [@model.display_name, @resource.display_name]
    redirect path_for
  end

  def require_user_and_prepare_resources
    redirect "/" unless current_user
    begin
      @model = params[:resources].camelize.constantize
    rescue NameError
    end
    @resources = @model && @model.for(current_user)
    halt t(:not_authorized) if @resources.nil?
    if params[:search].present?
      fields = @model.fields_for(current_user).map { |e| [e.name, e] }.to_h
      query = {}
      params[:search].split.each do |e|
        if e =~ /:/
          k, v = e.split(":", 2)
          query[k] ||= []
          query[k] << v
        else
          @model.search_fields.each do |f|
            query[f.to_s] ||= []
            query[f.to_s] << e
          end
        end
      end
      query = query.map do |k, v|
        f = fields[k]
        if f.nil?
          nil
        elsif f.type == String
          {"$and" => v.map { |e| {k => /#{Regexp.escape(e)}/i} }}
        else
          { k => v.first }
        end
      end.reject(&:nil?)
      @resources = @resources.and("$or" => query) if query.present?
    end
    if params[:sort].present?
      if params[:sort][0] == "-"
        @resources = @resources.order_by(params[:sort][1..-1] => -1)
      else
        @resources = @resources.order_by(params[:sort] => 1)
      end
    end
    @resources = @resources.includes(:created_by)
    return if params[:id].blank?
    @resource = @resources.find(params[:id])
  end
end

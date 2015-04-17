module Monatomic
  module Helper
    def t str
      settings.common_translation[str] || str
    end

    def h str
      Rack::Utils.escape_html str
    end

    def current_user
      @current_user ||= (User.where(id: session[:uid]).first if session[:uid])
    end

    def present resource, field
      if resource.readable? current_user, field
        value = resource[field.name]
        erb :"templates/#{field.options[:display_type]}", locals: { value: value }
      else
        t "(Hidden)"
      end
    end

    def model_path(*others)
      "/" + [@model.name.tableize, *others].join("/")
    end
  end
end

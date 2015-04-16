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
      value = resource[field.name]
      case field.options[:display_type]
      when :string
        h value
      when :tags
        value.map { |e| "<span class='label label-primary'>#{h e}</span>" }.join " "
      else
        "Unkown type #{field.options[:display_type]}"
      end
    end
  end
end

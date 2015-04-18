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

    def present resource, field, target: :presenter
      if resource.readable? current_user, field
        presenter = field.options[target]
        scope = OpenStruct.new(value: resource[field.name], field: field)
        scope.define_singleton_method(:h, &method(:h))
        if presenter.is_a? Symbol
          erb :"#{target}s/#{presenter}", scope: scope
        elsif presenter.is_a? String
          erb presenter, scope: scope
        elsif presenter.is_a? Proc
          scope.instance_exec(&presenter)
        end
      else
        t "(Hidden)"
      end
    end

    def model_path(*others)
      "/" + [@model.name.tableize, *others].join("/")
    end
  end
end

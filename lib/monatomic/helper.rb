module Monatomic
  module Helper
    def t *args
      I18n.t(*args)
    end

    def h str
      Rack::Utils.escape_html str
    end

    def current_user
      @current_user ||= (User.where(id: session[:uid]).first if session[:uid])
    end

    def present resource, field, target: :presenter
      ability = {
        presenter: :readable,
        editor: :writable
      }[target]
      if resource.method("#{ability}?").call current_user, field
        presenter = field.options[target]
        if field.is_a? Mongoid::Fields::ForeignKey
          value = resource.send(field.name.sub(/_id\Z/, ""))
        else
          value = resource.send(field.name)
        end
        scope = OpenStruct.new(
          value: value,
          field: field,
          param_name: "data[#{field.name}]"
        )
        scope.define_singleton_method(:method_missing, &method(:send))
        if presenter.is_a? Symbol
          erb :"#{target}s/#{presenter}", scope: scope
        elsif presenter.is_a? String
          erb presenter, scope: scope
        elsif presenter.is_a? Proc
          scope.instance_exec(&presenter)
        else
          h "Unknown presenter #{presenter} with #{field.inspect}"
        end
      else
        t :hidden
      end
    end

    def model_path(*others)
      "/" + [@model.name.tableize, *others].join("/")
    end

    def app_name
      t :app_name, exception_handler: proc { settings.app_name }
    end
  end
end

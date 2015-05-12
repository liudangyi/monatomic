require "tempfile"

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
        editor: :writable,
        text: :readable,
      }[target]
      raise ArgumentError if ability.nil?
      if resource.method("#{ability}?").call current_user, field
        presenter = field.options[target] || field.options[:display_type]
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
        elsif target == :text
          if value.respond_to? :display_name
            value.display_name
          else
            value
          end
        else
          h "Unknown presenter #{presenter} with #{field.inspect}"
        end
      else
        t :hidden
      end
    end

    def path_for(*arguments)
      options = arguments.last
      if options.is_a? Hash
        arguments.pop
        options.reject! { |k, v| v.blank? }
      else
        options = {}
      end
      [:sort, :search].each do |e|
        options[e] ||= params[e] if params[e]
      end
      arguments.unshift(@model.name.tableize) if @model
      base = "/" + arguments.join("/")
      if format = options.delete(:format)
        base << ".#{format}"
      end
      base << "?" + Rack::Utils.build_query(options) if options.present?
      base
    end

    def app_name
      t :app_name, exception_handler: proc { settings.app_name }
    end

    def send_xlsx
      workbook = RubyXL::Workbook.new
      worksheet = workbook[0]
      @fields.each_with_index do |field, i|
        worksheet.add_cell(0, i, t(field))
      end
      @resources.each_with_index do |res, i|
        @fields.each_with_index do |field, j|
          worksheet.add_cell(i+1, j, present(res, field, target: :text))
        end
      end
      tmp = Tempfile.new(["export", ".xlsx"])
      workbook.write tmp.path
      send_file tmp.path, filename: "#{@model.display_name}#{Time.now.to_s(:number)}.xlsx"
    end
  end
end

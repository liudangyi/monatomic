require "tempfile"

module Monatomic
  module Helper
    def t s, *others
      if s.respond_to? :display_name
        h s.display_name
      elsif s.respond_to? :name
        h I18n.t s.name
      else
        I18n.t s.to_s, *others
      end
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
        xlsx: :readable,
      }[target]
      raise ArgumentError if ability.nil?
      if resource.method("#{ability}?").call current_user, field
        presenter = field.options[target] || field.options[:display_type]
        if field.is_a? Mongoid::Fields::ForeignKey
          value = resource.send(field.name.sub(/_id\Z/, ""))
        else
          value = resource.send(field.name)
        end
        if target == :xlsx
          if value.respond_to? :display_name
            return value.display_name
          else
            return value
          end
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

    def path_for(*arguments)
      options = arguments.last
      if options.is_a? Hash
        arguments.pop
      else
        options = {}
      end
      [:sort, :search].each do |e|
        options[e] = params[e] if params[e].present? and options[e].nil?
      end
      arguments.unshift(@model.name.underscore) if @model
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
      workbook.cell_xfs << RubyXL::XF.new(num_fmt_id: 22)
      workbook.cell_xfs << RubyXL::XF.new(num_fmt_id: 14)
      worksheet = workbook[0]
      @fields.each_with_index do |field, i|
        worksheet.add_cell(0, i, t(field))
      end
      width = []
      @resources.each_with_index do |res, i|
        @fields.each_with_index do |field, j|
          width[j] ||= []
          v = present(res, field, target: :xlsx)
          c = worksheet.add_cell(i+1, j, v)
          if v.class.in? [Date, DateTime, Time]
            c.raw_value = workbook.date_to_num(v.to_datetime).to_s
            c.style_index = v.is_a?(Date) ? 2 : 1
            c.datatype = nil
            width[j] << (v.is_a?(Date) ? 8 : 12)
          else
            width[j] << v.to_s.length
          end
        end
      end
      width.each_with_index do |ws, i|
        worksheet.change_column_width(i, ws.max + 4)
      end
      tmp = Tempfile.new(["export", ".xlsx"])
      workbook.write tmp.path
      send_file tmp.path, filename: "#{@model.display_name}#{Time.now.to_s(:number)}.xlsx"
    end
  end
end

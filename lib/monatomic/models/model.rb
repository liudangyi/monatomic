require "mongoid"

module Monatomic
  class Model
    include Mongoid::Document

    class_attribute :acl

    %w[ readable writable deletable ].each do |type|
      define_method "#{type}?" do |user, field = nil|
        roles = self.class.acl[field ? field.name : :default]
        roles &&= roles[type.to_sym]
        return true if roles.blank?
        roles.each do |i|
          if i.is_a? Symbol
            return true if i.in? user.roles
          elsif i.arity == 1
            return true if self.instance_exec(user, &i)
          else
            return true if self.instance_exec(&i)
          end
        end
        false
      end
    end

    def represent_name
      if self.class.represent_field.is_a? Proc
        self.instance_exec(&self.class.represent_field)
      else
        self[self.class.represent_field]
      end
    end

    class << self
      alias :_field :field

      def inherited(subclass)
        subclass.acl = Hash.new
        subclass.acl[:default] = {
          readable: [:everyone],
          writable: [:admin],
          deletable: [:admin],
        }
        super
      end

      def field(name, options = {})
        name = name.to_s
        type = options[:type] || :string
        type = type.to_sym if type.is_a? String
        display = name.humanize
        options.delete_if do |k, v|
          case k
          when :type
            true
          when :validation
            add_validation name, v
            true
          when :readable, :writable
            add_access_control k, name, v
            true
          when :display
            display = v.to_s
            true
          else
            false
          end
        end
        options[:type] =
          case type
          when :string
            options[:default] ||= ""
            String
          when :tags
            options[:default] ||= []
            Array
          when :integer
            options[:default] ||= 0
            Integer
          when Class
            type
          else
            raise ArgumentError, "Cannot understand type #{type} for #{name}"
          end
        f = _field name, options
        f.options[:display_type] = type
        f.options[:display_name] = display
      end

      def add_validation(name, opt)
        opt = { opt => true } if opt.is_a? Symbol
        opt = opt.zip([true]).to_h if opt.is_a? Array
        validates name, opt
      end

      # Access Control
      def add_access_control(type, name, roles)
        acl[name] ||= {}
        acl[name][type] =
          case roles
          when true
            [:everyone]
          when false
            []
          when String
            [roles.to_sym]
          when Proc, Symbol
            [roles]
          when Array # [:role1, :role2, -> { ... } ]
            roles.map do |e|
              if e.is_a? String
                e.to_sym
              elsif e.is_a? Symbol or e.is_a? Proc
                e
              else
                raise ArgumentError
              end
            end
          else
            raise ArgumentError
          end
      end

      def readable=(roles)
        add_access_control(:readable, :default, roles)
      end

      def writable=(roles)
        add_access_control(:writable, :default, roles)
      end

      # All fields possible for a user to read / write
      def fields_for(user, type = :readable, resource = nil)
        fs = []
        fields.each do |name, field|
          roles = acl[name] && acl[name][type]
          if roles
            fs << field if roles.any? { |e| e.in?(user.roles) or e.is_a? Proc }
          elsif name[0] != "_"
            fs << field
          end
        end
        fs
      end

      # Get a query of readable records
      HELPER_MESSAGE = """Please note that model-based :readable proc \
is not executed within a special record. You should return a mongoid query \
or a boolean value where true means all and false means none."""
      def for(user)
        acl[:default][:readable].each do |role|
          if role.is_a? Symbol
            return all if role.in? user.roles
          else
            begin
              query = role.call(user)
            rescue NoMethodError => e
              raise NoMethodError, e.message + ". " + HELPER_MESSAGE
            end
            if query == true
              return all
            # we suppose there's only one block
            # else user should merge them by hand
            elsif query.is_a? Hash or query.is_a? String
              return where(query)
            elsif query != false
              raise ArgumentError, HELPER_MESSAGE
            end
          end
        end
        nil
      end

      # General setttings
      def set(option, value = (not_set = true), &block)
        raise ArgumentError if block and !not_set
        value, not_set = block, false if block

        if not_set
          raise ArgumentError unless option.respond_to?(:each)
          option.each { |k,v| set(k, v) }
          return self
        end

        if respond_to?("#{option}=")
          return __send__("#{option}=", value)
        end

        define_singleton_method(option.to_sym) { value }
      end

      def display_name
        self.name
      end

      def represent_field
        :id
      end

    end

  end
end

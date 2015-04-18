require "mongoid"

module Monatomic
  class Model
    include Mongoid::Document

    class_attribute :acl

    %w[ readable writable deletable ].each do |type|
      type = type.to_sym

      define_method "#{type}?" do |user, field = nil|
        raise "You should not call readable? without a field!" if type == :readable and field == nil
        roles = self.class.acl[field ? field.name : :default]
        roles &&= roles[type]
        return field != nil if roles.blank?
        roles.each do |k, v|
          if k.in? user.roles
            return true if v == true
            if v.arity == 1
              return true if self.instance_exec(user, &v)
            else
              return true if self.instance_exec(&v)
            end
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
          readable: { everyone: true },
          writable: { admin: true },
          deletable: { admin: true },
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
            { everyone: true }
          when false
            {}
          when String, Symbol
            { roles.to_sym => true }
          when Proc
            { everyone: roles }
          when Array # [:role1, :role2]
            raise ArgumentError unless roles.all? { |e| e.is_a? String or e.is_a? Symbol }
            roles.map { |e| [e.to_sym, true] }.to_h
          when Hash # { role1: true, role2: false, role3: -> { xxx } }
            roles.select do |k, v|
              if name == :default and type == :readable
                v == true or v.is_a? Proc or v.is_a? Hash
              elsif v.is_a? Hash
                raise ArgumentError, "You can only use a Hash in model-based readable ACL setting"
              else
                v == true or v.is_a? Proc
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
            fs << field if roles.any? { |k, v| k.in?(user.roles) }
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
        queries = []
        acl[:default][:readable].each do |k, v|
          if k.in? user.roles
            return all if v == true
            if v.is_a? Hash
              queries << v
              next
            end
            begin
              query = v.call(user)
            rescue NoMethodError => e
              raise NoMethodError, e.message + ". " + HELPER_MESSAGE
            end
            case query
            when true
              return all
            when Hash, String
              queries << query
            when false, nil
            else
              raise ArgumentError, HELPER_MESSAGE
            end
          end
        end
        self.or(queries) if queries.present?
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

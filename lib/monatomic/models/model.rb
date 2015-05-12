require "mongoid"
require "monatomic/types"

BSON::ObjectId.class_exec do
  def as_json(options = nil)
    to_s
  end
end

module Monatomic
  module Model
    extend ActiveSupport::Concern

    included do
      include Mongoid::Document

      %w[ readable writable deletable ].each do |type|
        type = type.to_sym

        define_method "#{type}?" do |user, field = :default|
          if type == :readable and field == :default
            raise ArgumentError, "You should not call readable? without a field!" 
          elsif type != :readable and field != :default
            return false if method("#{type}?").call(user, :default) == false
          end
          field = field.name if field.respond_to? :name
          roles = self.class.acl[field]
          roles &&= roles[type]
          return field.to_s[0] != "_" if roles.nil?
          return false if roles == false
          roles.each do |k, v|
            if k.in? user.roles
              return v if v == true or v == false
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

      def display_name
        if self.class.represent_field.is_a? Proc
          self.instance_exec(&self.class.represent_field)
        else
          self[self.class.represent_field]
        end
      end

      def as_json(user: nil)
        if user
          fields.keys.select { |e| readable? user, e }.map { |e| [e, self[e]] }.to_h
        else
          super
        end
      end

      class << self
        alias_method :_field, :field

        def acl
          @acl ||= {
            default: {
              readable: { "everyone" => true },
              writable: { "admin" => true },
              deletable: { "admin" => true },
            },
            "created_at" => { writable: false },
            "updated_at" => { writable: false },
            "created_by_id" => { writable: false },
          }
        end

        def field(name, options = {})
          name = name.to_s
          type = options[:type] || :string
          type = type.to_s.downcase if type.is_a? Class
          type = type.to_sym
          type_info = Types[type].dup
          raise ArgumentError, "type \"#{type}\" must be one of these #{Types.keys.inspect}" if type_info.nil?
          display = nil
          options.delete_if do |k, v|
            case k
            when :validation
              add_validation name, v
              true
            when :readable, :writable
              add_access_control name, k, v
              true
            when :display
              display = v.to_s
              true
            else
              if k.in? Mongoid::Fields::Validators::Macro::OPTIONS
                false
              else
                type_info[k] = v
                true
              end
            end
          end
          options[:type] = type_info[:storage] || String
          options[:default] ||= type_info[:default]
          options[:default] ||= "" if options[:type] == String
          f = super name, options
          f.options[:display_type] = type
          f.options.merge!(type_info)
          f.define_singleton_method(:display_name) { display } if display
        end

        def add_validation(name, opt)
          opt = { opt => true } if opt.is_a? Symbol
          opt = opt.zip([true]).to_h if opt.is_a? Array
          validates name, opt
        end

        # Access Control
        def add_access_control(name, type, roles)
          acl[name] ||= {}
          acl[name][type] =
            case roles
            when false
              false
            when String, Symbol
              { roles.to_s => true }
            when Proc, true
              { "everyone" => roles }
            when Array # [:role1, :role2]
              raise ArgumentError unless roles.all? { |e| e.is_a? String or e.is_a? Symbol }
              roles.map { |e| [e.to_s, true] }.to_h
            when Hash # { role1: true, role2: false, role3: -> { xxx } }
              roles.stringify_keys
            else
              raise ArgumentError
            end
        end

        %w[ readable writable deletable ].each do |type|
          define_method "#{type}=" do |roles|
            add_access_control(:default, type.to_sym, roles)
          end
        end

        # All fields possible for a user to read
        def fields_for(user, limit: nil)
          if limit
            fs = limit.map { |e| fields[e.to_s] }
          else
            fs = fields.values
          end
          fs.select do |field|
            name = field.name
            roles = acl[name] && acl[name][:readable]
            case roles
            when nil
              name[0] != "_"
            when true
              true
            when Hash
              roles.any? { |k, v| k.in?(user.roles) && v != false }
            end
          end
        end

        # Get a query of readable records
        HELPER_MESSAGE = """Please note that model-based :readable proc \
is not executed within a special record. You should return a mongoid query \
or a boolean value where true means all and false means none."""
        def for(user)
          queries = []
          return nil if acl[:default][:readable] == false
          acl[:default][:readable].each do |k, v|
            if k.in? user.roles
              return all if v == true
              if v.is_a? Hash
                queries << v
                next
              end
              begin
                if v.arity == 1
                  query = v.call(user)
                else
                  query = v.call
                end
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
          self.and("$or" => queries) if queries.present?
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
          to_s.humanize
        end

        def represent_field
          fields.keys[4] || :id
        end

        def display_fields
          fields.keys.slice(3, 5)
        end

        def search_fields
          fields.keys.slice(4, 1)
        end

      end

      include Mongoid::Timestamps
      belongs_to :created_by, class_name: "User"

    end

  end
end

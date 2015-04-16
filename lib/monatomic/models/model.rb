require "mongoid"

module Monatomic
  class Model
    include Mongoid::Document

    class_attribute :acl
    class_attribute :display_name

    class << self
      alias :_field :field

      def inherited(subclass)
        subclass.acl = Hash.new
        subclass.acl[:default] = {
          readable: [:everyone],
          writable: [:admin]
        }
        subclass.display_name = subclass.name
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

      def add_access_control(type, name, roles)
        roles = [roles] unless roles.is_a? Array
        acl[name] ||= {}
        acl[name][type] = roles.map(&:to_sym)
      end

      def readable(*roles)
        acl[:default][:readable] = roles.map(&:to_sym)
      end

      def writable(*roles)
        acl[:default][:writable] = roles.map(&:to_sym)
      end

      def fields_for(user)
        readable = []
        fields.each do |name, field|
          if acl[name] and acl[name][:readable]
            readable << field if (acl[name][:readable] & user.roles).present?
          elsif (acl[:default][:readable] & user.roles).present? and name[0] != "_"
            readable << field
          end
        end
        readable
      end

      def display(value)
        self.display_name = value
      end

    end

  end
end

require 'i18n'

module Enumerize
  class Value < String
    include Predicatable

    attr_reader :value

    def initialize(attr, name, value=nil)
      @attr = attr
      @value = value.nil? ? name.to_s : value

      super(name.to_s)
    end

    def text
      I18n.t(i18n_keys[0], :default => i18n_keys[1..-1])
    end

    def encode_with(coder)
      coder.represent_object(self.class.superclass, @value)
    end

    def to_xml(options = {})
      return unless options[:builder]

      opt = xml_serialize

      if opt.length == 1
        build_tag(options[:builder], self.name, opt[0])
      else
        opt.each { |o| build_tag(options[:builder], "#{self.name}-#{o}", o) }
      end
    end

    def build_tag(builder, name, option)
      builder.tag!(name, value_for_serialization(option))
    end

    def value_for_serialization(option)
        case option
          when :value
            self.value
          when :name
            self.to_s
          when :text
            self.text
          when :json
            value_for_serialization(self.json_serialize)
          when :xml
            value_for_serialization(self.xml_serialize)
          else
            self.to_s
        end
    end

    def name
      @attr.name
    end

    def xml_serialize
      Array(@attr.xml_serialize || :value)
    end

    def json_serialize
      @attr.json_serialize || :value
    end

    private

    def define_query_method(value)
      singleton_class.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{value}?
          #{value == self}
        end
      RUBY
    end

    def i18n_keys
      @i18n_keys ||= begin
        i18n_keys = i18n_scopes
        i18n_keys << [:"enumerize.defaults.#{@attr.name}.#{self}"]
        i18n_keys << [:"enumerize.#{@attr.name}.#{self}"]
        i18n_keys << self.humanize # humanize value if there are no translations
        i18n_keys.flatten
      end
    end

    def i18n_scopes
      @attr.i18n_scopes.map { |s| :"#{s}.#{self}" }
    end
  end
end

class RubySerializer
  class << self
    def handlers
      @handlers ||= {}
    end

    def handler(types, callable = nil, &block)
      Array(types).each do |type|
        handlers[type] = callable || block
      end
    end

    def inherited(subclass)
      handlers.each do |type, handler|
        subclass.handlers[type] = handler
      end
    end
  end

  def instance(klass, args: [], indent: 0)
    self.class.handlers.each do |type, handler|
      return instance_exec(klass, args: args, indent: indent, &handler) if klass <= type
    end

    raise "Unhandled type #{klass} with args: #{args.inspect}"
  end

  def serialize(object, args: [], indent: 0)
    self.class.handlers.each do |type, handler|
      return instance_exec(object, args: args, indent: indent, &handler) if object.class <= type
    end

    raise "Unhandled type #{object.class} for #{object.inspect}"
  end

  handler(Array) do |array, indent: 0, **_|
    "[\n#{array.map { |element| ("\t" * indent) + serialize(element, indent: indent + 1) }.join(",\n")}\n]"
  end

  handler(Hash) do |hash, indent: 0, **_|
    body = hash.map do |key, value|
      case key
      when Symbol
        "#{"\t" * indent}#{key}: #{serialize(value, indent: indent + 1)}"
      when String
        "#{"\t" * indent}\"#{key}\" => #{serialize(value, indent: indent + 1)}"
      else
        "#{"\t" * indent}\(#{serialize(key, indent: indent + 1)}\) => #{serialize(value, indent: indent + 1)}"
      end
    end.join(",\n")

    "{\n#{body}\n}"
  end

  handler(String) do |string, **_|
    "\"#{string}\""
  end

  handler(Symbol) do |symbol, **_|
    ":#{symbol}"
  end

  handler(Numeric) { |n, **_| n.to_s }
  handler(NilClass) { 'nil' }
end

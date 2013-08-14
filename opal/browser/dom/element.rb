module Browser; module DOM

class Element < Node
  def self.create(*args)
    $document.create_element(*args)
  end

  include Event::Target

  alias_native :id, :id

  def add_class(name)
    `#@native.className = #{class_names.push(name).uniq.join ' '}`

    self
  end

  def remove_class(name)
    `#@native.className = #{class_names.delete(name).join ' '}`
  end

  alias_native :class_name, :className

  def class_names
    `#@native.className`.split(/\s+/)
  end

  def attr(name)
    attributes[name]
  end

  alias attribute attr

  def attribute_nodes
    Array(`#@native.attributes`, :item).map { |e| DOM(e) }
  end

  def attributes
    Attributes.new(self)
  end

  def [](name)
    `#@native.getAttribute(#{name.to_s}) || nil`
  end

  def []=(name, value)
    `#@native.setAttribute(#{name.to_s}, #{value.to_s})`
  end

  alias get []

  alias get_attribute attr

  alias set_attribute []=

  def key?(name)
    !!self[name]
  end

  def keys
    attributes.keys
  end

  def values
    attribute_nodes.map { |n| n.value }
  end

  def each
    attributes.each { |name, value| yield value }
  end

  def remove_attribute(name)
    `#@native.removeAttribute(name)`
  end

  Size     = Struct.new(:width, :height)
  Position = Struct.new(:x, :y)

  def size
    Size.new(`#@native.clientWidth`, `#@native.clientHeight`)
  end

  def position
    Size.new(`#@native.clientLeft`, `#@native.clientTop`)
  end

  def /(*paths)
    paths.map { |path| xpath(path) }.flatten.uniq
  end

  def at(path)
    xpath(path).first
  end

  def at_css(*rules)
    rules.each {|rule|
      found = css(rule).first

      return found if found
    }

    nil
  end

  def at_xpath(*paths)
    paths.each {|path|
      found = xpath(path).first

      return found if found
    }

    nil
  end

  def search(*selectors)
    NodeSet.new document, selectors.map {|selector|
      xpath(selector).to_a.concat(css(selector).to_a)
    }.flatten.uniq
  end

  def css(path)
    NodeSet.new(document, Array(`#@native.querySelectorAll(path)`))
  end

  def xpath(path)
    result = []

    %x{
      try {
        var tmp = (#@native.ownerDocument || #@native).evaluate(
          path, #@native, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);

        result = #{Array(`tmp`, :snapshotItem, :snapshotLength)};
      } catch (e) { }
    }

    NodeSet.new(document, result)
  end

  def style(data = nil)
    style = Style::Definition.new(`#@native.style`)

    if data.is_a?(String)
      style.replace(data)

      self
    elsif data.is_a?(Enumerable)
      style.assign(data)

      self
    else
      style
    end
  end

  def inspect
    "#<DOM::Element: #{name}>"
  end

  class Attributes
    include Enumerable

    def initialize(element)
      @element = element
    end

    def each(&block)
      return enum_for :each unless block_given?

      @element.attribute_nodes.each {|attr|
        yield attr.name, attr.value
      }

      self
    end

    def [](name)
      @element[name]
    end

    def []=(name, value)
      @element[name] = value
    end

    def merge!(hash)
      hash.each {|name, value|
        @element[name] = value
      }
    end
  end
end

end; end

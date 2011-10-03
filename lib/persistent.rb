module Persistent
  def self.included(base)
    base.class_eval do
      extend ClassMethods
      attr_accessor :id
      private :initialize
    end
  end

  def initialize(id)
    @id = id.to_i
  end

  def attribute_key(attribute)
    "#{self.class.key}/#{id}/#{attribute}"
  end

  def read_attribute(name)
    DB.get(attribute_key(name))
  end

  def write_attribute(name, value)
    DB.set(attribute_key(name), value)
  end

  def delete(*attributes)
    DB.multi do
      DB.del(*attributes.map { |a| attribute_key(a) })
      DB.srem(self.class.key, id)
    end
  end

  def ==(other)
    self.class == other.class && id == other.id
  end

  module ClassMethods
    def persistent_attr_accessor(name)
      persistent_attr_reader(name)
      persistent_attr_writer(name)
    end

    def persistent_attr_reader(name)
      define_method(name) { read_attribute(name) }
    end

    def persistent_attr_writer(name)
      define_method(:"#{name}=") { |value| write_attribute(name, value) }
    end

    def key
      # Poor man's underscore.pluralize
      "#{name.downcase}s"
    end

    def get(id)
      DB.sismember(key, id) ? new(id) : nil
    end

    def all
      DB.smembers(key).map { |id| new(id) }
    end

    def create(attributes = {})
      new(attributes[:id] || next_id).tap do |record|
        DB.sadd(key, record.id)

        attributes.each do |name, value|
          record.send("#{name}=", value)
        end
      end
    end

    def get_or_create(id)
      get(id) || create(:id => id)
    end

    def delete(id)
      new(id).delete
    end

    def next_id
      DB.incr("#{key}/last-id")
    end
  end
end

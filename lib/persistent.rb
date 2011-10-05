#
# Include this module into your class to make it redis-persistable.
#
module Persistent
  REDIS = Redis.new(:host => CONFIG[:redis_host], :port => CONFIG[:redis_port])

  def self.included(base)
    base.class_eval do
      extend ClassMethods
      attr_accessor :id
      # private :initialize
    end
  end

  def read_scalar(name)
    REDIS.get attribute_key(name)
  end

  def write_scalar(name, value)
    REDIS.set attribute_key(name), value

    index = self.class.indices[name]
    index && index.add(value, self)
  end

  def increment!(name, amount = 1)
    REDIS.incrby attribute_key(name), amount
  end

  def ==(other)
    self.class == other.class && id == other.id
  end

  def delete
    delete_id
    delete_from_indices
    delete_attributes
  end

  private

  def delete_id
    REDIS.srem(self.class.key, id)
  end

  def delete_from_indices
    self.class.indices.values.each { |index| index.remove(self) }
  end

  def delete_attributes
    REDIS.del *self.class.attributes.map { |a| attribute_key(a) }
  end

  def attribute_key(name)
    "#{self.class.key}/#{id}/#{name}"
  end

  def initialize(id)
    @id = id.to_i
  end

  module ClassMethods
    def create(attributes = {})
      new(attributes[:id] || next_id!).tap do |record|
        REDIS.sadd(key, record.id)

        attributes.each do |name, value|
          record.send("#{name}=", value)
        end
      end
    end

    def get(id)
      REDIS.sismember(key, id) ? new(id) : nil
    end

    def get_or_create(id)
      get(id) || create(:id => id)
    end

    def all
      REDIS.smembers(key).map { |id| new(id) }
    end

    def delete(id)
      new(id).delete
    end

    def next_id!
      REDIS.incr("#{key}/last-id")
    end

    def key
      # Poor man's underscore.pluralize
      "#{name.downcase}s"
    end

    def attributes
      # FIXME: this won't work with inheritance.
      @attributes ||= ::Set.new
    end

    def string(name)
      string_reader(name)
      string_writer(name)
    end

    def string_reader(name)
      define_method(name) { read_scalar(name) }
      attributes << name
    end

    def string_writer(name)
      define_method(:"#{name}=") { |value| write_scalar(name, value) }
      attributes << name
    end

    def integer(name)
      integer_reader(name)
      integer_writer(name)
    end

    def integer_reader(name)
      define_method(name) { read_scalar(name).to_i }
      attributes << name
    end

    def integer_writer(name)
      define_method(:"#{name}=") { |value| write_scalar(name, value.to_i) }
      attributes << name
    end

    def set(name)
      define_method(name) do
        var = "@#{name}"
        set = instance_variable_get(var)

        unless set
          set = Set.new(attribute_key(name))
          instance_variable_set(var, set)
        end

        set
      end
    end

    def indices
      # FIXME: this won't work with inheritance.
      @indices ||= {}
    end

    def index(name)
      index = Index.new(self, name)
      indices[name] = index

      meta.instance_eval do
        define_method(:"get_by_#{name}") { |value| index.get(value) }
      end
    end

    def meta
      class << self; self; end
    end
  end

  class Set
    def initialize(key)
      @key = key
    end

    def << (item)
      REDIS.sadd(@key, item)
    end

    alias_method :add, :<<

    def delete(item)
      REDIS.srem(@key, item)
    end

    def include?(item)
      REDIS.sismember(@key, item)
    end

    def size
      REDIS.scard(@key)
    end

    alias_method :length, :size
  end

  class Index
    def initialize(type, name)
      @type = type
      @name = name
    end

    def get(value)
      id = REDIS.hget(key, value)
      id && @type.new(id)
    end

    def add(value, record)
      REDIS.hset(key, value, record.id) if value
    end

    def remove(record)
      REDIS.hdel key, record.send(@name)
    end

    def key
      "#{@type.key}/by-#{@name}"
    end
  end
end

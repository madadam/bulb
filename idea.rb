require 'redis'
require 'json'

# TODO: allow configuration
$redis = Redis.new

class Idea
  include Comparable

  def self.persistent_attr_accessor(name)
    persistent_attr_reader(name)
    persistent_attr_writer(name)
  end

  def self.persistent_attr_reader(name)
    define_method(name) { read_attribute(name) }
  end

  def self.persistent_attr_writer(name)
    define_method(:"#{name}=") { |value| write_attribute(name, value) }
  end

  attr_accessor :id
  persistent_attr_accessor :text
  persistent_attr_accessor :timestamp

  def self.get(id)
    $redis.sismember('ideas', id) ? new(id) : nil
  end

  def self.all
    $redis.smembers('ideas').map { |id| new(id) }.sort
  end

  def self.create(text)
    new(next_id).tap do |idea|
      idea.text      = text
      idea.timestamp = Time.now.to_i

      $redis.sadd('ideas', idea.id)
    end
  end

  def self.update(id, text)
    get(id).tap do |idea|
      idea.text = text
    end
  end

  def self.delete(id)
    $redis.multi do
      $redis.del(attribute_key(id, :text),
                 attribute_key(id, :timestamp),
                 attribute_key(id, :votes))
      $redis.srem('ideas', id)
    end

    nil
  end

  def self.next_id
    $redis.incr('ideas/last-id')
  end

  def self.attribute_key(id, attribute)
    "ideas/#{id}/#{attribute}"
  end

  def attribute_key(attribute)
    self.class.attribute_key(id, attribute)
  end

  def read_attribute(name)
    $redis.get(attribute_key(name))
  end

  def write_attribute(name, value)
    $redis.set(attribute_key(name), value)
  end

  def votes
    read_attribute(:votes).to_i
  end

  def vote!(points)
    # FIXME: there is still possibility of a race condition, making the
    # votes negative.
    $redis.incrby(attribute_key(:votes), points) if votes + points >= 0
  end

  def ==(other)
    self.class == other.class && id == other.id && text == other.text
  end

  def <=>(other)
    if votes == other.votes
      timestamp <=> other.timestamp
    else
      other.votes <=> votes
    end
  end

  def to_json(*args)
    { :id         => id,
      :timestamp  => timestamp,
      :text       => text,
      :votes      => votes
    }.to_json(*args)
  end

  def to_s
    text
  end

  private

  def initialize(id = nil)
    @id = id.to_i
  end
end

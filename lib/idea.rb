require 'redis'
require 'json'

require File.expand_path('../../config', __FILE__)

$redis = Redis.new(:host => REDIS_HOST, :port => REDIS_PORT)

module PersistentAttributes
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
end

class Idea
  include Comparable
  extend PersistentAttributes

  attr_accessor :id
  persistent_attr_accessor :text
  persistent_attr_accessor :timestamp

  def self.get(id)
    $redis.sismember('ideas', id) ? new(id) : nil
  end

  def self.all
    $redis.smembers('ideas').map { |id| new(id) }.sort
  end

  def self.create(attributes = {})
    new(attributes[:id] || next_id).tap do |idea|
      $redis.sadd('ideas', idea.id)

      idea.timestamp = attributes[:timestamp] || Time.now.to_i
      idea.text = attributes[:text] if attributes[:text]
    end
  end

  def self.get_or_create(id)
    get(id) || create(:id => id)
  end

  def self.delete(id)
    new(id).delete
  end

  def delete
    $redis.multi do
      $redis.del(attribute_key(:text),
                 attribute_key(:timestamp),
                 attribute_key(:votes))
      $redis.srem('ideas', id)
    end

    nil
  end

  def self.next_id
    $redis.incr('ideas/last-id')
  end

  def attribute_key(attribute)
    "ideas/#{id}/#{attribute}"
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
    # votes negative. This is solvable using WATCH, but that is supported
    # only in sufficiently high version of redis server
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

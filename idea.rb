require 'redis'
require 'json'

# TODO: allow configuration
$redis = Redis.new

class Idea
  attr_accessor :id
  attr_accessor :text

  def self.get(id)
    text = $redis.hget('ideas', id)
    text && new(id, text)
  end

  def self.all
    $redis.hgetall('ideas').map do |id, text|
      new(id, text)
    end
  end

  def self.create(text)
    new(next_id, text).tap(&:save)
  end

  def self.update(id, text)
    new(id, text).tap(&:save)
  end

  def self.delete(id)
    $redis.hdel('ideas', id)
    nil
  end

  def self.next_id
    $redis.incr('ideas/last-id')
  end

  def save
    $redis.hset('ideas', id, text)
  end

  def ==(other)
    self.class == other.class && id == other.id && text == other.text
  end

  def to_json(*args)
    {:id => id, :text => text}.to_json(*args)
  end

  private

  def initialize(id = nil, text = nil)
    @id   = id.to_i
    @text = text
  end
end

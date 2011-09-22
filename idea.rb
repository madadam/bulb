require 'redis'
require 'json'

# TODO: allow configuration
$redis = Redis.new

class Idea
  include Comparable

  attr_accessor :id
  attr_accessor :text
  attr_accessor :timestamp
  attr_accessor :votes

  def self.get(id)
    data = $redis.hget('ideas', id)
    data && unserialize(id, data)
  end

  def self.all
    $redis.hgetall('ideas').map do |id, data|
      unserialize(id, data)
    end.sort
  end

  def self.create(text)
    new(next_id, text).tap(&:save)
  end

  def self.update(id, text)
    get(id).tap do |idea|
      idea.text = text
      idea.save
    end
  end

  def self.delete(id)
    $redis.hdel('ideas', id)
    nil
  end

  def self.next_id
    $redis.incr('ideas/last-id')
  end

  def self.unserialize(id, data)
    new(id).tap do |idea|
      attributes = JSON.parse(data)
      idea.timestamp  = attributes['timestamp']
      idea.text       = attributes['text']
      idea.votes      = attributes['votes']
    end
  end

  def vote!(points)
    self.votes = [0, votes + points].max
    save
  end

  def save
    $redis.hset('ideas', id, attributes.to_json)
    self
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

  def attributes
    {:timestamp => timestamp, :text => text, :votes => votes}
  end

  def to_json(*args)
    {:id => id}.merge(attributes).to_json(*args)
  end

  def to_s
    text
  end

  private

  def initialize(id = nil, text = nil)
    @id         = id.to_i
    @text       = text
    @timestamp  = Time.now.to_i
    @votes      = 0
  end
end

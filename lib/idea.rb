class Idea
  include Comparable
  include Persistent

  persistent_attr_accessor :text
  persistent_attr_accessor :timestamp

  def self.all
    super.sort
  end

  def self.create(attributes = {})
    super({:timestamp => Time.now.to_i}.merge(attributes))
  end

  def delete
    super :text, :timestamp, :votes
  end

  def votes
    read_attribute(:votes).to_i
  end

  def vote!(points)
    # FIXME: there is still possibility of a race condition, making the
    # votes negative. This is solvable using WATCH, but that is supported
    # only in sufficiently high version of redis server
    DB.incrby(attribute_key(:votes), points) if votes + points >= 0
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
end

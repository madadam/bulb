class Idea
  include Comparable
  include Persistent

  string          :text
  integer         :timestamp
  integer_reader  :votes

  def self.all
    super.sort
  end

  def self.create(attributes = {})
    super({:timestamp => Time.now.to_i}.merge(attributes))
  end

  def vote!(points)
    # FIXME: there is still possibility of a race condition, making the
    # votes negative. This is solvable using WATCH, but that is supported
    # only in sufficiently high version of redis server
    increment! :votes, points if votes + points >= 0
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

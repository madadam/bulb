class Idea
  include Comparable
  include Persistent

  string  :text
  integer :timestamp

  private

  set :upvotes
  set :downvotes

  public

  def self.all
    super.sort
  end

  def self.create(attributes = {})
    super({:timestamp => Time.now.to_i}.merge(attributes))
  end

  def upvote!(user)
    upvotes << user.id
    downvotes.delete(user.id)
  end

  def toggle_upvote!(user)
    upvoted_by?(user) ? unvote!(user) : upvote!(user)
  end

  def upvoted_by?(user)
    upvotes.include?(user.id)
  end

  def downvote!(user)
    downvotes << user.id
    upvotes.delete(user.id)
  end

  def toggle_downvote!(user)
    downvoted_by?(user) ? unvote!(user) : downvote!(user)
  end

  def downvoted_by?(user)
    downvotes.include?(user.id)
  end

  def unvote!(user)
    upvotes.delete(user.id)
    downvotes.delete(user.id)
  end

  def vote_by(user)
    case
    when upvoted_by?(user)   then :upvote
    when downvoted_by?(user) then :downvote
    else                          nil
    end
  end

  def votes
    upvotes.size - downvotes.size
  end

  def <=>(other)
    if votes == other.votes
      timestamp <=> other.timestamp
    else
      other.votes <=> votes
    end
  end

  def to_s
    text
  end
end

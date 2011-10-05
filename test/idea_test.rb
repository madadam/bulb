require 'helper'

class IdeaTest < Test::Unit::TestCase
  def setup
    setup_redis
  end

  test 'Idea.delete deletes an idea' do
    idea = Idea.create(:text => 'create artificial inteligence')
    idea.delete

    assert_nil Idea.get(idea.id)
  end

  test 'Idea.get retrieves idea by id' do
    idea1 = Idea.create(:text => 'create wormhole')
    idea2 = Idea.get(idea1.id)

    assert_equal idea1, idea2
  end

  test 'Idea.all retrieves all previously created ideas' do
    Idea.create(:text => 'invent time travel')
    Idea.create(:text => 'travel to future')
    Idea.create(:text => 'go back and profit')

    ideas = Idea.all

    assert_equal 3, ideas.size

    idea = ideas.find { |i| i.id == 1 }
    assert_equal 'invent time travel', idea.text

    idea = ideas.find { |i| i.id == 2 }
    assert_equal 'travel to future', idea.text

    idea = ideas.find { |i| i.id == 3 }
    assert_equal 'go back and profit', idea.text
  end

  test 'Idea.all retrieves the ideas sorted' do
    idea1 = Idea.create(:text => 'foo')
    idea2 = Idea.create(:text => 'bar')
    idea3 = Idea.create(:text => 'baz')

    user1 = User.create
    user2 = User.create

    idea2.upvote!(user1)
    idea3.upvote!(user1)
    idea3.upvote!(user2)

    ideas = Idea.all

    assert_equal 'baz', ideas[0].text
    assert_equal 'bar', ideas[1].text
    assert_equal 'foo', ideas[2].text
  end

  test 'ideas are created with zero votes' do
    idea = Idea.create(:text => 'foo')
    assert_equal 0, idea.votes
  end

  test 'Idea#upvote! adds one vote and marks the idea as upvoted by the given user' do
    idea = Idea.create(:text => 'foo')
    user = User.create

    idea.upvote!(user)

    assert_equal 1, idea.votes
    assert idea.upvoted_by?(user)
  end

  test 'Idea#upvote! does nothing if it is already upvoted by the given user' do
    idea = Idea.create(:text => 'foo')
    user = User.create

    idea.upvote!(user)
    idea.upvote!(user)

    assert_equal 1, idea.votes
  end

  test 'Idea#upvote! removes the downvote of a previously downvoted idea' do
    idea = Idea.create(:text => 'foo')
    user = User.create

    idea.downvote!(user)
    idea.upvote!(user)

    assert_equal 1, idea.votes
    assert !idea.downvoted_by?(user)
    assert  idea.upvoted_by?(user)
  end

  test 'Idea#downvote! removes one vote and marks the idea as downvoted by the given user' do
    idea = Idea.create(:text => 'foo')
    user = User.create

    idea.downvote!(user)

    assert_equal -1, idea.votes
    assert idea.downvoted_by?(user)
  end

  test 'Idea#downvote! does nothing if it is already downvoted by the given user' do
    idea = Idea.create(:text => 'foo')
    user = User.create

    idea.downvote!(user)
    idea.downvote!(user)

    assert_equal -1, idea.votes
  end

  test 'Idea#downvote! removes the upvote of a previously upvoted idea' do
    idea = Idea.create(:text => 'foo')
    user = User.create

    idea.upvote!(user)
    idea.downvote!(user)

    assert_equal -1, idea.votes
    assert  idea.downvoted_by?(user)
    assert !idea.upvoted_by?(user)
  end

  test 'Idea#unvote! removes upvote' do
    idea = Idea.create(:text => 'foo')
    user = User.create

    idea.upvote!(user)
    idea.unvote!(user)

    assert !idea.upvoted_by?(user)
  end

  test 'Idea#unvote! removes downvote' do
    idea = Idea.create(:text => 'foo')
    user = User.create

    idea.downvote!(user)
    idea.unvote!(user)

    assert !idea.downvoted_by?(user)
  end

  test 'Idea#votes returns total number of votes' do
    idea = Idea.create(:text => 'foo')
    user1 = User.create
    user2 = User.create

    idea.upvote!(user1)
    idea.upvote!(user2)
    assert_equal 2, idea.votes

    idea.downvote!(user1)
    assert_equal 0, idea.votes

    idea.downvote!(user2)
    assert_equal -2, idea.votes
  end

  test 'Idea#toggle_upvote! upvotes if not already upvoted' do
    idea = Idea.create(:text => 'foo')
    user = User.create

    idea.toggle_upvote!(user)
    assert idea.upvoted_by?(user)
  end

  test 'Idea#toggle_upvote! removes the upvote if already upvoted' do
    idea = Idea.create(:text => 'foo')
    user = User.create

    idea.upvote!(user)

    idea.toggle_upvote!(user)
    assert !idea.upvoted_by?(user)
  end

  test 'Idea#toggle_upvote! upvotes if downvoted' do
    idea = Idea.create(:text => 'foo')
    user = User.create

    idea.downvote!(user)

    idea.toggle_upvote!(user)
    assert idea.upvoted_by?(user)
  end

  test 'Idea#toggle_downvote! downvotes if not already downvoted' do
    idea = Idea.create(:text => 'foo')
    user = User.create

    idea.toggle_downvote!(user)
    assert idea.downvoted_by?(user)
  end

  test 'Idea#toggle_downvote! removes the downvote if already downvoted' do
    idea = Idea.create(:text => 'foo')
    user = User.create

    idea.downvote!(user)

    idea.toggle_downvote!(user)
    assert !idea.downvoted_by?(user)
  end

  test 'Idea#toggle_downvote! downvotes if upvoted' do
    idea = Idea.create(:text => 'foo')
    user = User.create

    idea.upvote!(user)

    idea.toggle_downvote!(user)
    assert idea.downvoted_by?(user)
  end

  test 'Idea#vote_by returns :upvote if the idea was upvoted by the given user' do
    idea = Idea.create(:text => 'foo')
    user = User.create

    idea.upvote!(user)
    assert_equal :upvote, idea.vote_by(user)
  end

  test 'Idea#vote_by returns :downvote if the idea was downvoted by the given user' do
    idea = Idea.create(:text => 'foo')
    user = User.create

    idea.downvote!(user)
    assert_equal :downvote, idea.vote_by(user)
  end

  test 'Idea#vote_by returns nil if the idea was not voted by the given user' do
    idea = Idea.create(:text => 'foo')
    user = User.create

    assert_nil idea.vote_by(user)
  end

  test 'older idea is before a younger one if they have the same votes' do
    idea1 = Idea.create(:text => 'foo')
    idea2 = Idea.create(:text => 'bar')

    user = User.create

    idea1.timestamp = Time.local(2011, 9, 27, 22, 10, 11)
    idea2.timestamp = Time.local(2011, 9, 27, 22, 10, 21)
    assert idea1 < idea2

    idea1.upvote!(user)
    idea2.upvote!(user)
    assert idea1 < idea2
  end

  test 'idea with more votes is before one with less votes' do
    idea1 = Idea.create(:text => 'foo')
    idea2 = Idea.create(:text => 'bar')

    user1 = User.create
    user2 = User.create

    idea1.upvote!(user1)
    idea2.upvote!(user1)
    idea2.upvote!(user2)
    assert idea2 < idea1
  end
end

require 'helper'
require 'capybara/dsl'

# TODO: Make this fucking test pass.

# # Run the websocket server only once.
# Thread.new { WebSocket.run! }.run
#
# class IntegrationTest < Test::Unit::TestCase
#   include Capybara::DSL
#
#   def setup
#     Capybara.current_driver = :webkit
#
#     # No idea what this is, but if it is true, I get weird errors. Need to
#     # investigate more.
#     Capybara.automatic_reload = false
#
#     Capybara.app = App
#
#     setup_redis
#
#     # alice = User.create :email => 'alice@example.com', :password => 'foobar'
#     # authorize alice.email, alice.password
#   end
#
#   test 'add idea' do
#     visit '/'
#     add_idea('test everything!')
#     assert has_content?('test everything!')
#   end
#
#   test 'new idea survives reloads' do
#     visit '/'
#     add_idea('test all the fucking time')
#
#     visit '/'
#     assert has_content?('test all the fucking time')
#   end
#
#   test 'edit idea' do
#     visit '/'
#     add_idea('test little bit')
#
#     edit_idea('test little bit', 'test a lot')
#     assert has_no_content?('test little bit')
#     assert has_content?('test a lot')
#   end
#
#   test 'edit is preserved after reload' do
#     visit '/'
#     add_idea('test little bit')
#
#     visit '/'
#     edit_idea('test little bit', 'test a lot')
#
#     visit '/'
#     assert has_no_content?('test little bit')
#     assert has_content?('test a lot')
#   end
#
#   test 'trash idea' do
#     text = 'never test'
#
#     visit '/'
#     add_idea 'never test'
#
#     trash_idea 'never test'
#     assert has_no_content?('never test')
#   end
#
#   test 'trashed idea is gone after reload' do
#     visit '/'
#     add_idea 'never ever test'
#
#     visit '/'
#     trash_idea 'never ever test'
#
#     visit '/'
#     assert has_no_content?('never ever test')
#   end
#
#   test 'search' do
#     visit '/'
#     add_idea 'foo'
#     add_idea 'bar'
#     add_idea 'baz'
#
#     find('#search').set('ba')
#
#     assert has_css?('li', :text => 'bar')
#     assert has_css?('li', :text => 'baz')
#     assert has_no_css?('li', :text => 'foo')
#   end
#
#   test 'vote up' do
#     visit '/'
#     add_idea 'foo'
#     add_idea 'bar'
#     assert_ideas_order 'foo', 'bar'
#
#     vote_up_idea 'bar'
#     assert_ideas_order 'bar', 'foo'
#   end
#
#   private
#
#   def add_idea(text)
#     click_link 'New idea'
#     fill_in 'value', :with => text
#     click_button 'Save'
#   end
#
#   def edit_idea(old_text, new_text)
#     find('li .text', :text => old_text).click
#     fill_in 'value', :with => new_text
#     click_button 'Save'
#   end
#
#   def trash_idea(text)
#     idea_node = find('#ideas li', :text => text)
#     idea_node.drag_to(find('#trash'))
#   end
#
#   def vote_up_idea(text)
#     idea_node = find('#ideas li', :text => text)
#     idea_node.click_link 'up'
#   end
#
#   def assert_ideas_order(one, two)
#     texts = all('#ideas li .text').map { |node| node.text }
#     assert texts.index(one) < texts.index(two),
#            "expected ideas to be in order: 1: #{one}, 2: #{two}, but were not"
#   end
#
#   # HACK: This method should be provided by capybara.
#   def authorize(username, password)
#     encoded_login = ["#{username}:#{password}"].pack("m*")
#     page.driver.header('Authorization', "Basic #{encoded_login}")
#   end
# end

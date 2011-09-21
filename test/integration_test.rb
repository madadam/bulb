require 'test/unit'
require 'capybara'
require 'capybara-webkit'
require 'capybara/dsl'

require 'app'

class IntegrationTest < Test::Unit::TestCase
  include Capybara::DSL

  def setup
    Capybara.current_driver = :webkit
    Capybara.app = Sinatra::Application
  end

  def test_add_idea
    visit '/'
    add_idea('test everything!')
    assert has_content?('test everything!')
  end

  def test_new_idea_survives_reloads
    visit '/'
    add_idea('test all the fucking time')

    visit '/'
    assert has_content?('test all the fucking time')
  end

  def test_edit_idea
    visit '/'
    add_idea('test little bit')

    edit_idea('test little bit', 'test a lot')
    assert has_no_content?('test little bit')
    assert has_content?('test a lot')
  end

  def test_trash_idea
    text = 'never test'

    visit '/'
    add_idea 'never test'

    trash_idea 'never test'
    assert has_no_content?('never test')
  end

  private

  def add_idea(text)
    click_link 'New idea'
    fill_in 'value', :with => text
    click_button 'Save'
  end

  def edit_idea(old_text, new_text)
    find('li .text', :text => old_text).click
    fill_in 'value', :with => new_text
    click_button 'Save'
  end

  def trash_idea(text)
    idea_node = find('#ideas li', :text => text)
    idea_node.drag_to(find('#trash'))
  end
end

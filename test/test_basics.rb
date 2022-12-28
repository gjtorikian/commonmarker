# frozen_string_literal: true

require "test_helper"

class TestBasics < Minitest::Test
  def test_to_html
    html = Commonmarker.to_html("Hi *there*")

    assert_equal("<p>Hi <em>there</em></p>\n", html)
  end

  # basic test that just checks that default option is accepted & no errors are thrown
  def test_to_html_accept_default_options
    text = "Hello **world** -- how are _you_ today? I'm ~~fine~~, ~yourself~?"

    html = Commonmarker.to_html(text, options: Commonmarker::Config::OPTIONS).rstrip

    assert_equal("<p>Hello <strong>world</strong> -- how are <em>you</em> today? I'm <del>fine</del>, <del>yourself</del>?</p>", html)
  end
end

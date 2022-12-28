# frozen_string_literal: true

require "test_helper"

class TestMaliciousness < Minitest::Test
  def test_rendering_with_bad_type
    assert_raises(TypeError) do
      Commonmarker.to_html(nil)
    end

    assert_raises(TypeError) do
      Commonmarker.to_html(123)
    end

    assert_raises(TypeError) do
      Commonmarker.to_html([123])
    end

    assert_raises(TypeError) do
      Commonmarker.to_html("foo \n baz", options: 123)
    end

    assert_raises(TypeError) do
      Commonmarker.to_html("foo \n baz", options: :totes_fake)
    end

    assert_raises(TypeError) do
      Commonmarker.to_html("foo \n baz", options: [])
    end

    assert_raises(TypeError) do
      Commonmarker.to_html("foo \n baz", options: [23])
    end

    assert_raises(TypeError) do
      Commonmarker.to_html("foo \n baz", options: nil)
    end

    assert_raises(TypeError) do
      Commonmarker.to_html("foo \n baz", options: [:SMART, "totes_fake"])
    end
  end

  def test_bad_options_value
    err = assert_raises(TypeError) do
      Commonmarker.to_html("foo \n baz", options: { parse: { smart: 111 } })
    end

    assert_equal("parse option `:smart` must be Boolean; got Integer", err.message)
  end

  def test_non_utf8
    err = assert_raises(TypeError) do
      Commonmarker.to_html("foo \n baz".encode("US-ASCII"))
    end

    assert_equal("text must be UTF-8 encoded; got US-ASCII!", err.message)
  end
end

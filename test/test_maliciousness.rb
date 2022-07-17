# frozen_string_literal: true

require "test_helper"

module CommonMarker
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
        Commonmarker.to_html("foo \n baz", options: { parse: { smart: 111 }})
      end
      assert_equal("smart must be a FalseClass got a Number", err.message)
    end

    def test_bad_fence_info_set
      assert_raises(NodeError) do
        @doc.fence_info = "ruby"
      end

      fence = Commonmarker.to_html("``` ruby\nputs 'wow'\n```").first_child
      assert_raises(TypeError) do
        fence.fence_info = 123
      end
    end
  end
end

require 'test_helper'

class CommonMarker::TestMaliciousness < Minitest::Test

  def test_init_with_false_type
    assert_raises NodeError do
      Node.new(99999)
    end

    assert_raises NodeError do
      Node.new(:totes_fake)
    end

    assert_raises NodeError do
      Node.new(123, 456)
    end

    assert_raises NodeError do
      Node.new(nil, nil)
    end

    assert_raises ArgumentError do
      Node.parse_string("foo \n baz", :lolnotreal)
    end

    assert_raises ArgumentError do
      Node.parse_string("foo \n baz", [])
    end

    assert_raises ArgumentError do
      Node.parse_string("foo \n baz", [23])
    end
  end
end

require 'test_helper'

class CommonMarker::TestMaliciousness < Minitest::Test

  def test_init_with_bad_type
    assert_raises TypeError do
      Node.new(123)
    end

    assert_raises NodeError do
      Node.new(:totes_fake)
    end

    assert_raises TypeError do
      Node.new([])
    end

    assert_raises TypeError do
      Node.new([23])
    end

    assert_raises TypeError do
      Node.new(nil)
    end
  end

  def test_parsing_with_bad_type
    assert_raises TypeError do
      CommonMarker.parse_string("foo \n baz", 123)
    end

    assert_raises TypeError do
      CommonMarker.parse_string("foo \n baz", :totes_fake)
    end

    assert_raises TypeError do
      CommonMarker.parse_string("foo \n baz", [])
    end

    assert_raises TypeError do
      CommonMarker.parse_string("foo \n baz", [23])
    end

    assert_raises TypeError do
      CommonMarker.parse_string("foo \n baz", nil)
    end
  end
end

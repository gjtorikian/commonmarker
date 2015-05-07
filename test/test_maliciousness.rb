require 'test_helper'

class CommonMarker::TestMaliciousness < Minitest::Unit::TestCase
  def test_init
    assert_raises NodeError do
      render = Node.new(99999)
    end
  end
end

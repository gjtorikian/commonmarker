# frozen_string_literal: true

require "test_helper"

class TestParser < Minitest::Test
  def setup
    @document = Commonmarker.parse("Hi *there*. This has __many nodes__!")
  end

  def test_knows_type
    assert_equal(:document, @document.get_type)
  end
end

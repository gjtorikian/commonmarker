# frozen_string_literal: true

require 'test_helper'

class TestPlaintext < Minitest::Test
  def setup
    @markdown = <<~MD
      Hi *there*!

      1. I am a numeric list.
      2. I continue the list.
      * Suddenly, an unordered list!
      * What fun!

      Okay, _enough_.

      | a   | b   |
      | --- | --- |
      | c   | d   |
    MD
  end

  def parse(doc)
    Markly.parse(doc, extensions: %i[table])
  end

  def test_to_commonmark
    compare = parse(@markdown).to_plaintext

    assert_equal <<~PLAINTEXT, compare
      Hi there!

      1.  I am a numeric list.
      2.  I continue the list.

        - Suddenly, an unordered list!
        - What fun!

      Okay, enough.

      | a | b |
      | --- | --- |
      | c | d |
    PLAINTEXT
  end
end

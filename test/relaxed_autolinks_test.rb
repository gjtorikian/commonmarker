# frozen_string_literal: true

require "test_helper"

class RelaxedAutolinksTest < Minitest::Test
  def test_to_html
    md = <<~MARKDOWN
      [https://foo.com]

      smb:///Volumes/shared/foo.pdf

      rdar://localhost.com/blah
    MARKDOWN

    expected = <<~HTML
      <p>[<a href="https://foo.com">https://foo.com</a>]</p>
      <p><a href="smb:///Volumes/shared/foo.pdf">smb:///Volumes/shared/foo.pdf</a></p>
      <p><a href="rdar://localhost.com/blah">rdar://localhost.com/blah</a></p>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { parse: { relaxed_autolinks: true } }))
  end
end

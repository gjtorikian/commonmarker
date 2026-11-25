# frozen_string_literal: true

require "test_helper"

class WikilinksTest < Minitest::Test
  def test_works_with_after_pipe
    md = <<~MARKDOWN
      [[url|link label]]
    MARKDOWN

    expected = <<~HTML
      <p><a href="url" data-wikilink="true">link label</a></p>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { extension: { wikilinks_title_after_pipe: true } }))
  end

  def test_works_with_before_pipe
    md = <<~MARKDOWN
      [[link label|url]]
    MARKDOWN

    expected = <<~HTML
      <p><a href="url" data-wikilink="true">link label</a></p>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { extension: { wikilinks_title_before_pipe: true } }))
  end

  def test_embeds_are_parsed_by_default
    md = <<~MARKDOWN
      ![[url]]
    MARKDOWN

    expected = <<~HTML
      <p><a href="url" data-wikilink="true">url</a></p>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { extension: { wikilinks_title_after_pipe: true } }))
  end

  def test_embeds_can_be_ignored
    md = <<~MARKDOWN
      ![[url]]
    MARKDOWN

    expected = <<~HTML
      <p>![[url]]</p>
    HTML

    options = { extension: { wikilinks_title_after_pipe: true, wikilinks_ignore_embeds: true } }

    assert_equal(expected, Commonmarker.to_html(md, options: options))
  end
end

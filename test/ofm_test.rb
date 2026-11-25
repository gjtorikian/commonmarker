# frozen_string_literal: true

require "test_helper"

class OfmTest < Minitest::Test
  def test_callouts_to_html
    md = <<~MARKDOWN
      > [!tip]
      > Watch out
    MARKDOWN
    expected = <<~HTML
      <div class="callout" data-callout="tip" data-callout-fold="none">
      <div class="callout-title">Tip</div>
      <div class="callout-content">
      <p>Watch out</p>
      </div>
      </div>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { extension: { ofm_callouts: true } }))
  end

  def test_comments_are_dropped
    md = <<~MARKDOWN
      This is an %%inline%% comment.

      %%
      block comment
      %%
    MARKDOWN
    expected = <<~HTML
      <p>This is an  comment.</p>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { extension: { ofm_comments: true } }))
  end

  def test_block_ids_label_their_block
    md = <<~MARKDOWN
      Some paragraph ^abc123
    MARKDOWN
    expected = <<~HTML
      <p id="^abc123">Some paragraph </p>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { extension: { ofm_block_ids: true } }))
  end
end

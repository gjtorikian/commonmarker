# frozen_string_literal: true

require "test_helper"

# Node types introduced by comrak 1.x: math blocks, Obsidian callouts,
# block identifiers and comments.
class NodeTypesTest < Minitest::Test
  OFM = { extension: { ofm_callouts: true, ofm_block_ids: true, ofm_comments: true } }.freeze

  def test_math_block_nodes
    options = { extension: { math_dollars: true, math_dollars_block: true } }
    doc = Commonmarker.parse("$$\nx = y\n$$\n", options: options)
    math_block = doc.first_child

    assert_equal([:document, :math_block], doc.walk.map(&:type))
    assert_equal("x = y\n", math_block.literal)

    math_block.literal = "a = b\n"

    assert_equal("<div data-math-style=\"display\">\na = b\n</div>\n", doc.to_html)
  end

  def test_callout_nodes
    doc = Commonmarker.parse("> [!tip] Custom title\n> Watch out\n", options: OFM)
    callout = doc.first_child

    assert_equal(:callout, callout.type)
    assert_equal(:tip, callout.callout_type)
    assert_equal(:callout_title, callout.first_child.type)
    assert_equal("Custom title", callout.first_child.first_child.first_child.string_content)

    callout.callout_type = :warning

    assert_includes(doc.to_html, "<div class=\"callout\" data-callout=\"warning\" data-callout-fold=\"none\">")
  end

  def test_comment_nodes
    doc = Commonmarker.parse("This is an %%inline%% comment.\n\n%%\nblock comment\n%%\n", options: OFM)
    comments = doc.walk.select { |node| node.type == :comment }

    assert_equal(["inline", "\nblock comment\n"], comments.map(&:literal))

    comments.first.literal = "changed"

    assert_equal("changed", comments.first.literal)
  end

  def test_block_id_nodes
    doc = Commonmarker.parse("Some paragraph ^abc123\n", options: OFM)

    assert_equal([:document, :paragraph, :text, :block_id], doc.walk.map(&:type))
  end

  def test_can_build_a_callout
    doc = Commonmarker::Node.new(:document)
    callout = Commonmarker::Node.new(:callout, type: :note, metadata: "meta", fold: :collapsed)
    doc.append_child(callout)

    title = Commonmarker::Node.new(:callout_title)
    callout.append_child(title)
    title_paragraph = Commonmarker::Node.new(:paragraph)
    title.append_child(title_paragraph)
    title_paragraph.append_child(Commonmarker::Node.new(:text, content: "Custom"))

    body = Commonmarker::Node.new(:paragraph)
    callout.append_child(body)
    body.append_child(Commonmarker::Node.new(:text, content: "Body"))

    expected = <<~HTML
      <div class="callout" data-callout="note" data-callout-metadata="meta" data-callout-fold="collapsed">
      <div class="callout-title">
      Custom
      </div>
      <div class="callout-content">
      <p>Body</p>
      </div>
      </div>
    HTML

    assert_equal(expected, doc.to_html)
  end

  def test_can_build_a_math_block
    doc = Commonmarker::Node.new(:document)
    doc.append_child(Commonmarker::Node.new(:math_block, literal: "x = y\n"))

    assert_equal("<div data-math-style=\"display\">\nx = y\n</div>\n", doc.to_html)
  end

  def test_can_build_comments_and_block_ids
    doc = Commonmarker::Node.new(:document)
    paragraph = Commonmarker::Node.new(:paragraph)
    doc.append_child(paragraph)
    paragraph.append_child(Commonmarker::Node.new(:text, content: "Visible "))
    paragraph.append_child(Commonmarker::Node.new(:comment, literal: "hidden"))
    paragraph.append_child(Commonmarker::Node.new(:block_id, name: "abc123"))
    doc.append_child(Commonmarker::Node.new(:comment, literal: "hidden block", multiline: true))

    assert_equal("<p id=\"^abc123\">Visible </p>\n", doc.to_html(options: OFM))
  end

  def test_callout_fold_must_be_valid
    err = assert_raises(ArgumentError) { Commonmarker::Node.new(:callout, type: :tip, fold: :sideways) }
    assert_equal("callout fold must be `none`, `expanded`, or `collapsed`", err.message)
  end

  def test_callout_type_is_only_for_callouts
    paragraph = Commonmarker::Node.new(:paragraph)

    refute_respond_to(paragraph, :callout_type)
    assert_respond_to(Commonmarker::Node.new(:callout, type: :tip), :callout_type)

    err = assert_raises(TypeError) { paragraph.callout_type }
    assert_equal("node is not a callout node", err.message)
  end
end

# frozen_string_literal: true

require "test_helper"

class InstanceTest < Minitest::Test
  SMART = { parse: { smart: true } }.freeze
  CODE = "```ruby\ndef hello\nend\n```\n"

  def test_commonmarker_is_a_class
    assert_kind_of(Class, Commonmarker)
    assert_kind_of(Commonmarker, Commonmarker.new)
  end

  def test_defaults_match_class_methods
    text = "Hello **world** -- how are _you_ today?"
    markdown = Commonmarker.new

    assert_equal(Commonmarker.to_html(text), markdown.to_html(text))
    assert_equal(Commonmarker.parse(text).to_html, markdown.parse(text).to_html)
  end

  def test_to_html_uses_instance_options
    markdown = Commonmarker.new(options: SMART)

    assert_equal("<p>“Hi <em>there</em>”</p>\n", markdown.to_html('"Hi *there*"'))
  end

  def test_parse_uses_instance_options
    markdown = Commonmarker.new(options: SMART)
    doc = markdown.parse('"Hi *there*"')

    assert_equal(:document, doc.type)
    assert_equal("<p>“Hi <em>there</em>”</p>\n", doc.to_html)
  end

  def test_options_match_class_methods
    text = "# Heading\n\nSome *text* -- here <b>bold</b>"
    options = { parse: { smart: true }, render: { unsafe: true }, extension: { header_ids: "user-" } }
    markdown = Commonmarker.new(options: options)

    assert_equal(Commonmarker.to_html(text, options: options), markdown.to_html(text))
  end

  def test_instance_is_reusable
    markdown = Commonmarker.new(options: { render: { unsafe: true } })

    assert_equal("<p>Hi <em>there</em></p>\n", markdown.to_html("Hi *there*"))
    assert_equal("<div>raw</div>\n", markdown.to_html("<div>raw</div>"))
    assert_equal("<p>Hi <em>there</em></p>\n", markdown.to_html("Hi *there*"))
  end

  def test_options_are_snapshotted_at_construction
    options = { parse: { smart: true } }
    markdown = Commonmarker.new(options: options)

    options[:parse][:smart] = false
    options[:render] = { unsafe: true }

    assert_equal("<p>“Hi”</p>\n", markdown.to_html('"Hi"'))
    assert_equal("<!-- raw HTML omitted -->\n", markdown.to_html("<div>raw</div>"))
  end

  def test_plugins_apply
    highlighted = Commonmarker.new(plugins: { syntax_highlighter: { theme: "InspiredGitHub" } })
    plain = Commonmarker.new(plugins: { syntax_highlighter: nil })

    assert_match(/background-color:#ffffff;/, highlighted.to_html(CODE))
    assert_equal("<pre lang=\"ruby\"><code>def hello\nend\n</code></pre>\n", plain.to_html(CODE))
  end

  def test_plugins_accept_custom_theme_path
    markdown = Commonmarker.new(plugins: { syntax_highlighter: { theme: "Monokai", path: FIXTURES_DIR } })

    assert_match(/background-color:#323232;/, markdown.to_html(CODE))
  end

  def test_rejects_non_hash_options
    err = assert_raises(TypeError) { Commonmarker.new(options: "nope") }

    assert_equal("options must be a Hash; got a String!", err.message)
  end

  def test_validates_option_values_at_construction
    err = assert_raises(TypeError) { Commonmarker.new(options: { parse: { smart: 1 } }) }

    assert_equal("parse option `:smart` must be Boolean; got Integer", err.message)
  end

  def test_rejects_non_hash_plugins
    assert_raises(TypeError) { Commonmarker.new(plugins: "nope") }
  end

  def test_validates_theme_at_construction
    assert_raises(ArgumentError) { Commonmarker.new(plugins: { syntax_highlighter: { theme: "WowieZowie" } }) }
  end

  def test_to_html_rejects_non_string
    err = assert_raises(TypeError) { Commonmarker.new.to_html(123) }

    assert_equal("text must be a String or a Commonmarker::Node; got a Integer!", err.message)
  end

  def test_parse_rejects_non_string
    err = assert_raises(TypeError) { Commonmarker.new.parse(nil) }

    assert_equal("text must be a String; got a NilClass!", err.message)
  end

  def test_rejects_non_utf8_text
    err = assert_raises(TypeError) { Commonmarker.new.to_html("hi".encode("UTF-16")) }

    assert_equal("text must be UTF-8 encoded; got UTF-16!", err.message)
  end

  def test_uninitialized_instance_raises
    markdown = Commonmarker.allocate

    err = assert_raises(RuntimeError) { markdown.to_html("hi") }

    assert_match(/not initialized/, err.message)
  end

  def test_cannot_be_initialized_twice
    markdown = Commonmarker.new

    assert_raises(RuntimeError) { markdown.send(:initialize) }
  end

  def test_can_be_subclassed
    klass = Class.new(Commonmarker) do
      def initialize
        super(options: { parse: { smart: true } })
      end
    end
    markdown = klass.new

    assert_kind_of(Commonmarker, markdown)
    assert_equal("<p>“Hi”</p>\n", markdown.to_html('"Hi"'))
  end

  def test_can_be_shared_across_threads
    markdown = Commonmarker.new(options: SMART)

    results = Array.new(8) do
      Thread.new { Array.new(50) { markdown.to_html('"Hi"') } } # rubocop:disable ThreadSafety/NewThread
    end.flat_map(&:value)

    assert_equal(400, results.size)
    assert(results.all?("<p>“Hi”</p>\n"))
  end

  def test_to_html_renders_a_node_with_instance_options
    markdown = Commonmarker.new(options: { render: { unsafe: true } })
    doc = markdown.parse("<div>raw</div>")

    assert_equal("<div>raw</div>\n", markdown.to_html(doc))
    # the node's own renderer still defaults to safe output
    assert_equal("<!-- raw HTML omitted -->\n", doc.to_html)
  end

  def test_to_html_renders_a_modified_node
    markdown = Commonmarker.new(options: SMART)
    doc = markdown.parse("# The site\n\n[GitHub](https://www.github.com) \"quoted\"")

    doc.walk do |node|
      node.replace(node.first_child) if node.type == :link
    end

    html = markdown.to_html(doc)

    assert_equal(doc.to_html(options: SMART), html)
    assert_match(%r{<p>GitHub “quoted”</p>}, html)
    refute_match(%r{href="https://www\.github\.com"}, html)
  end

  def test_to_html_renders_a_node_with_instance_plugins
    plain = Commonmarker.new(plugins: { syntax_highlighter: nil })
    doc = plain.parse(CODE)

    assert_equal("<pre lang=\"ruby\"><code>def hello\nend\n</code></pre>\n", plain.to_html(doc))
    assert_match(/background-color:#2b303b;/, doc.to_html)
  end

  def test_to_commonmark_renders_a_node
    markdown = Commonmarker.new
    doc = markdown.parse("# The site\n\n[GitHub](https://www.github.com)")

    doc.walk do |node|
      node.replace(node.first_child) if node.type == :link
    end

    assert_equal("# The site\n\nGitHub\n", markdown.to_commonmark(doc))
    assert_equal(doc.to_commonmark, markdown.to_commonmark(doc))
  end

  def test_to_commonmark_normalizes_text
    markdown = Commonmarker.new(options: { render: { list_style: "star" } })
    text = "- one\n- two\n"

    assert_equal("* one\n* two\n", markdown.to_commonmark(text))
    assert_equal(Commonmarker.parse(text).to_commonmark(options: { render: { list_style: "star" } }), markdown.to_commonmark(text))
  end

  def test_to_commonmark_rejects_other_input
    err = assert_raises(TypeError) { Commonmarker.new.to_commonmark(123) }

    assert_equal("text must be a String or a Commonmarker::Node; got a Integer!", err.message)
  end

  def test_class_method_renders_a_node
    doc = Commonmarker.parse("<div>raw</div>")

    assert_equal("<div>raw</div>\n", Commonmarker.to_html(doc, options: { render: { unsafe: true } }))
    assert_equal("<!-- raw HTML omitted -->\n", Commonmarker.to_html(doc))
  end
end

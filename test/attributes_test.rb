# frozen_string_literal: true

require "test_helper"

class AttributesTest < Minitest::Test
  HEADING = "## Intro {#custom .big data-x=1}\n"

  def test_attributes_are_only_parsed_when_enabled
    doc = Commonmarker.parse(HEADING)

    assert_nil(doc.first_child.attributes)
    assert_equal("Intro {#custom .big data-x=1}", doc.first_child.first_child.string_content)

    doc = Commonmarker.parse(HEADING, options: { extension: { header_attributes: true } })

    assert_equal({ id: "custom", classes: ["big"], pairs: { "data-x" => "1" } }, doc.first_child.attributes)
    assert_equal("Intro", doc.first_child.first_child.string_content)
  end

  def test_attributes_render_only_with_unsafe
    safe = { extension: { header_attributes: true, header_ids: nil }, render: { attributes: true } }

    assert_equal("<h2>Intro</h2>\n", Commonmarker.to_html(HEADING, options: safe))

    unsafe = { extension: { header_attributes: true, header_ids: nil }, render: { attributes: true, unsafe: true } }

    assert_equal("<h2 id=\"custom\" class=\"big\" data-x=\"1\">Intro</h2>\n", Commonmarker.to_html(HEADING, options: unsafe))
  end

  def test_explicit_ids_win_over_generated_header_ids
    options = { extension: { header_attributes: true, header_ids: "" }, render: { attributes: true, unsafe: true } }

    assert_includes(Commonmarker.to_html(HEADING, options: options), "<h2 id=\"custom\" class=\"big\" data-x=\"1\">Intro")
  end

  def test_attributes_on_code_links_and_images
    md = <<~MARKDOWN
      ```ruby {#ex .wide}
      puts 1
      ```

      Some `x`{.kw} and ![Comrak](comrak.png){width=100 .logo}
    MARKDOWN
    options = {
      extension: { fenced_code_attributes: true, inline_code_attributes: true, link_attributes: true },
      render: { attributes: true, unsafe: true },
    }
    expected = <<~HTML
      <pre class="wide" id="ex"><code class="language-ruby">puts 1
      </code></pre>
      <p>Some <code class="kw">x</code> and <img src="comrak.png" alt="Comrak" class="logo" width="100" /></p>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: options))
  end

  def test_attributes_can_be_assigned
    doc = Commonmarker.parse("[Comrak](https://comrak.ee)\n")
    link = doc.first_child.first_child

    assert_nil(link.attributes)

    link.attributes = { id: :home, classes: [:a, "b"], pairs: { title: "Site", "data-x" => "1" } }

    assert_equal({ id: "home", classes: ["a", "b"], pairs: { "title" => "Site", "data-x" => "1" } }, link.attributes)
    assert_equal(
      "<p><a href=\"https://comrak.ee\" id=\"home\" class=\"a b\" title=\"Site\" data-x=\"1\">Comrak</a></p>\n",
      doc.to_html(options: { render: { attributes: true, unsafe: true } }),
    )

    link.attributes = { classes: ["only"] }

    assert_equal({ id: nil, classes: ["only"], pairs: {} }, link.attributes)

    link.attributes = nil

    assert_nil(link.attributes)
  end

  def test_attributes_must_be_a_hash_of_the_right_shape
    link = Commonmarker::Node.new(:link, url: "https://comrak.ee")

    err = assert_raises(TypeError) { link.attributes = "x" }
    assert_equal("attributes must be a Hash or nil; got String", err.message)

    err = assert_raises(TypeError) { link.attributes = { classes: "a" } }
    assert_equal("attribute classes must be an Array; got String", err.message)

    err = assert_raises(TypeError) { link.attributes = { pairs: { "a" => 1 } } }
    assert_equal("attribute value must be a String or Symbol; got Integer", err.message)
  end

  def test_options_are_exposed_with_defaults
    options = Commonmarker::Config::OPTIONS

    refute(options[:render][:attributes])
    refute(options[:extension][:header_attributes])
    refute(options[:extension][:fenced_code_attributes])
    refute(options[:extension][:inline_code_attributes])
    refute(options[:extension][:link_attributes])
  end
end

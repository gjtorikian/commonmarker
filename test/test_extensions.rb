# frozen_string_literal: true

require 'test_helper'

class TestExtensions < Minitest::Test
  def setup
    @markdown = fixtures_file('table.md')
  end

  def test_uses_specified_extensions
    Markly.render_html(@markdown, extensions: %i[]).tap do |out|
      assert out.include?('| a')
      assert out.include?('| <strong>x</strong>')
      assert out.include?('~~hi~~')
    end

    Markly.render_html(@markdown, extensions: %i[table]).tap do |out|
      refute out.include?('| a')
      %w[<table> <tr> <th> a </th> <td> c </td> <strong>x</strong>].each { |html| assert out.include?(html) }
      assert out.include?('~~hi~~')
    end

    Markly.render_html(@markdown, extensions: %i[strikethrough]).tap do |out|
      assert out.include?('| a')
      refute out.include?('~~hi~~')
      assert out.include?('<del>hi</del>')
    end

    doc = Markly.parse('~a~ ~~b~~ ~~~c~~~', flags: Markly::STRIKETHROUGH_DOUBLE_TILDE, extensions: [:strikethrough])
    assert_equal doc.to_html, "<p>~a~ <del>b</del> ~~~c~~~</p>\n"

    Markly.render_html(@markdown, extensions: %i[table strikethrough]).tap do |out|
      refute out.include?('| a')
      refute out.include?('| <strong>x</strong>')
      refute out.include?('~~hi~~')
    end
  end

  def test_extensions_with_renderers
    doc = Markly.parse(@markdown, extensions: %i[table])

    doc.to_html.tap do |out|
      refute out.include?('| a')
      %w[<table> <tr> <th> a </th> <td> c </td> <strong>x</strong>].each { |html| assert out.include?(html) }
      assert out.include?('~~hi~~')
    end

    HtmlRenderer.new.render(doc).tap do |out|
      refute out.include?('| a')
      %w[<table> <tr> <th> a </th> <td> c </td> <strong>x</strong>].each { |html| assert out.include?(html) }
      assert out.include?('~~hi~~')
    end

    doc = Markly.parse('~a~ ~~b~~ ~~~c~~~', flags: Markly::STRIKETHROUGH_DOUBLE_TILDE, extensions: [:strikethrough])
    assert_equal HtmlRenderer.new.render(doc), "<p>~a~ <del>b</del> ~~~c~~~</p>\n"
  end

  def test_bad_extension_specifications
    assert_raises(TypeError) { Markly.render_html(@markdown, extensions: ['table']) }
    assert_raises(ArgumentError) { Markly.render_html(@markdown, extensions: %i[table bad]) }
  end

  def test_comments_are_kept_as_expected
    assert_equal "<!--hello--> <blah> &lt;xmp>\n", Markly.render_html("<!--hello--> <blah> <xmp>\n", flags: Markly::UNSAFE, extensions: %i[tagfilter])
  end

  def test_table_prefer_style_attributes
    assert_equal(<<~HTML, Markly.render_html(<<~MD, flags: Markly::TABLE_PREFER_STYLE_ATTRIBUTES, extensions: %i[table]))
      <table>
      <thead>
      <tr>
      <th style="text-align: left">aaa</th>
      <th>bbb</th>
      <th style="text-align: center">ccc</th>
      <th>ddd</th>
      <th style="text-align: right">eee</th>
      </tr>
      </thead>
      <tbody>
      <tr>
      <td style="text-align: left">fff</td>
      <td>ggg</td>
      <td style="text-align: center">hhh</td>
      <td>iii</td>
      <td style="text-align: right">jjj</td>
      </tr>
      </tbody>
      </table>
    HTML
      aaa | bbb | ccc | ddd | eee
      :-- | --- | :-: | --- | --:
      fff | ggg | hhh | iii | jjj
    MD
  end

  def test_plaintext
    assert_equal(<<~HTML, Markly.parse(<<~MD, extensions: %i[table strikethrough]).to_plaintext)
      Hello ~there~.

      | a |
      | --- |
      | b |
    HTML
      Hello ~~there~~.

      | a |
      | - |
      | b |
    MD
  end
end

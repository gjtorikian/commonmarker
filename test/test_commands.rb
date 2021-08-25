# frozen_string_literal: true

require 'test_helper'

class TestCommands < Minitest::Test
  def test_basic
    out = make_bin('strong.md')
    assert_equal('<p>I am <strong>strong</strong></p>', out)
  end

  def test_does_not_have_extensions
    out = make_bin('table.md')
    assert_includes out, '| a'
    refute_includes out, '<p><del>hi</del>'
    refute_includes out, '<table> <tr> <th> a </th> <td> c </td>'
  end

  def test_understands_extensions
    out = make_bin('table.md', '--extension=table')
    refute_includes out, '| a'
    refute_includes out, '<p><del>hi</del>'
    %w[<table> <tr> <th> a </th> <td> c </td>].each { |html| assert_includes out, html }
  end

  def test_understands_multiple_extensions
    out = make_bin('table.md', '--extension=table,strikethrough')
    refute_includes out, '| a'
    assert_includes out, '<p><del>hi</del>'
    %w[<table> <tr> <th> a </th> <td> c </td>].each { |html| assert_includes out, html }
  end

  def test_understands_format
    out = make_bin('strong.md', '--to=xml')
    assert_includes out, '<?xml version="1.0" encoding="UTF-8"?>'
    assert_includes out, '<text xml:space="preserve">strong</text>'
  end
end

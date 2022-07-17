# frozen_string_literal: true

require "test_helper"

class TestRenderer < Minitest::Test
  def test_multiple_tables
    content = <<~DOC
      | Input       | Expected         | Actual    |
      | ----------- | ---------------- | --------- |
      | One         | Two              | Three     |

      | Header   | Row  | Example |
      | :------: | ---: | :------ |
      | Foo      | Bar  | Baz     |
    DOC
    doc = Commonmarker.to_html(content, [:autolink, :table, :tagfilter])
    results = CommonMarker::HtmlRenderer.new.render(doc)
    assert_equal(2, results.scan(/<tbody>/).size)
  end
end

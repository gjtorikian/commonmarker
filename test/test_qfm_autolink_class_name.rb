# frozen_string_literal: true

require('test_helper')

describe 'TestQfmAutolinkClassName' do
  let(:options) { %i[AUTOLINK_CLASS_NAME] }
  let(:extensions) { %i[autolink] }
  let(:text) do
    <<~MD
      https://example.com
      <https://example.com>
      [Example](https://example.com)
      test@example.com
    MD
  end
  let(:doc) { QiitaMarker.render_doc(text, options, extensions) }
  let(:expected) do
    <<~HTML
      <p><a href="https://example.com" class="autolink">https://example.com</a>
      <a href="https://example.com">https://example.com</a>
      <a href="https://example.com">Example</a>
      <a href="mailto:test@example.com" class="autolink">test@example.com</a></p>
    HTML
  end
  let(:rendered_html) { doc.to_html(options, extensions) }

  it "appends class name to extension's autolinks" do
    assert_equal(expected, rendered_html)
  end

  describe 'without AUTOLINK_CLASS_NAME option' do
    let(:options) { %i[DEFAULT] }
    let(:expected) do
      <<~HTML
        <p><a href="https://example.com">https://example.com</a>
        <a href="https://example.com">https://example.com</a>
        <a href="https://example.com">Example</a>
        <a href="mailto:test@example.com">test@example.com</a></p>
      HTML
    end

    it "does not append class name to extension's autolink" do
      assert_equal(expected, rendered_html)
    end
  end

  describe 'without autolink extension' do
    let(:extensions) { %i[] }
    let(:expected) do
      <<~HTML
        <p>https://example.com
        <a href="https://example.com">https://example.com</a>
        <a href="https://example.com">Example</a>
        test@example.com</p>
      HTML
    end

    it 'does not append class name' do
      assert_equal(expected, rendered_html)
    end
  end
end

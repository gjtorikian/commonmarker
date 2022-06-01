# frozen_string_literal: true

require "test_helper"

class TestQfmMentionNoEmphasis < Minitest::Test
  describe "with mention_no_emphasis option" do
    [
      ["@_username_",         false],
      ["@__username__",       false],
      ["@___username___",     false],
      ["@user__name__",       false],
      ["@some__user__name__", false],
      [" @_username_",        false],
      ["あ@_username_", false],
      ["A@_username_",        true],
      ["@*username*",         true],
      ["_foo_",               true],
      ["_",                   false],
      ["_foo @username_",     false],
      ["__foo @username__",   false],
      ["___foo @username___", false],
    ].each do |text, emphasize|
      describe "with text #{text.inspect}" do
        if emphasize
          it "emphasizes the text" do
            QiitaMarker.render_html(text, :MENTION_NO_EMPHASIS).tap do |out|
              assert_match(/(<em>|<strong>)/, out.chomp)
            end
          end
        else
          it "does not emphasize the text" do
            QiitaMarker.render_html(text, :MENTION_NO_EMPHASIS).tap do |out|
              assert_match "<p>#{text.strip}</p>", out.chomp
            end
          end
        end
      end
    end
  end

  describe "without mention_no_emphasis option" do
    describe 'with text "@_username_"' do
      text = "@_username_"
      it "emphasizes the text" do
        QiitaMarker.render_html(text, :DEFAULT, []).tap do |out|
          assert_match(/<em>/, out.chomp)
        end
      end
    end

    describe 'with text "_foo @username_"' do
      text = "_foo @username_"
      it "emphasizes the text" do
        QiitaMarker.render_html(text, :DEFAULT, []).tap do |out|
          assert_match(/<em>/, out.chomp)
        end
      end
    end
  end
end

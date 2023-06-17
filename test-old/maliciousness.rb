# frozen_string_literal: true

require 'test_helper'

module Markly
  class TestMaliciousness < Minitest::Test
    def setup
      @doc = Markly.parse('Hi *there*')
    end

    def test_init_with_bad_type
      assert_raises TypeError do
        Node.new(123)
      end

      assert_raises Error do
        Node.new(:totes_fake)
      end

      assert_raises TypeError do
        Node.new([])
      end

      assert_raises TypeError do
        Node.new([23])
      end

      assert_raises TypeError do
        Node.new(nil)
      end
    end

    def test_bad_set_string_content
      assert_raises TypeError do
        @doc.string_content = 123
      end
    end

    def test_bad_walking
      assert_nil @doc.parent
      assert_nil @doc.previous
    end

    def test_bad_insertion
      code = Node.new(:code)
      assert_raises Error do
        @doc.insert_before(code)
      end

      paragraph = Node.new(:paragraph)
      assert_raises Error do
        @doc.insert_after(paragraph)
      end

      document = Node.new(:document)
      assert_raises Error do
        @doc.prepend_child(document)
      end

      assert_raises Error do
        @doc.append_child(document)
      end
    end

    def test_bad_url_get
      assert_raises Error do
        @doc.url
      end
    end

    def test_bad_url_set
      assert_raises Error do
        @doc.url = '123'
      end

      link = Markly.parse('[GitHub](https://www.github.com)').first_child.first_child
      assert_raises TypeError do
        link.url = 123
      end
    end

    def test_bad_title_get
      assert_raises Error do
        @doc.title
      end
    end

    def test_bad_title_set
      assert_raises Error do
        @doc.title = '123'
      end

      image = Markly.parse('![alt text](https://github.com/favicon.ico "Favicon")')
      image = image.first_child.first_child
      assert_raises TypeError do
        image.title = 123
      end
    end

    def test_bad_header_level_get
      assert_raises Error do
        @doc.header_level
      end
    end

    def test_bad_header_level_set
      assert_raises Error do
        @doc.header_level = 1
      end

      header = Markly.parse('### Header Three').first_child
      assert_raises TypeError do
        header.header_level = '123'
      end
    end

    def test_bad_list_type_get
      assert_raises Error do
        @doc.list_type
      end
    end

    def test_bad_list_type_set
      assert_raises Error do
        @doc.list_type = :bullet_list
      end

      ul_list = Markly.parse("* Bullet\n*Bullet").first_child
      assert_raises Error do
        ul_list.list_type = :fake
      end
      assert_raises TypeError do
        ul_list.list_type = 1234
      end
    end

    def test_bad_list_start_get
      assert_raises Error do
        @doc.list_start
      end
    end

    def test_bad_list_start_set
      assert_raises Error do
        @doc.list_start = 12
      end

      ol_list = Markly.parse("1. One\n2. Two").first_child
      assert_raises TypeError do
        ol_list.list_start = :fake
      end
    end

    def test_bad_list_tight_get
      assert_raises Error do
        @doc.list_tight
      end
    end

    def test_bad_list_tight_set
      assert_raises Error do
        @doc.list_tight = false
      end
    end

    def test_bad_fence_info_get
      assert_raises Error do
        @doc.fence_info
      end
    end

    def test_bad_fence_info_set
      assert_raises Error do
        @doc.fence_info = 'ruby'
      end

      fence = Markly.parse("``` ruby\nputs 'wow'\n```").first_child
      assert_raises TypeError do
        fence.fence_info = 123
      end
    end
  end
end

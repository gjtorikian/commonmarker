require 'test_helper'

class TestAttributes < Minitest::Test
  def setup
    contents = File.read(File.join(FIXTURES_DIR, 'dingus.md'))
    @doc = CommonMarker.render_doc(contents.strip)
  end

  def test_sourcepos
    sourcepos = []
    @doc.walk do |node|
      ap node.sourcepos
      sourcepos << node.sourcepos
    end
    # assert_equal [:document, :paragraph, :text, :emph, :text], sourcepos
  end
end

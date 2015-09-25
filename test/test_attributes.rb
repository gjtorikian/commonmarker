require 'test_helper'

class TestAttributes < Minitest::Test
  def setup

    text = '''
## Try CommonMark

You can try CommonMark here.  This dingus is powered by
[commonmark.js](https://github.com/jgm/commonmark.js), the
JavaScript reference implementation.

1. item one
2. item two
   - sublist
   - sublist
'''
    @doc = CommonMarker.render_doc(text)
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

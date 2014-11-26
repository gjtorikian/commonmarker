#!/usr/bin/env ruby
require './commonmarker'

doc = Node.parse_file(ARGF)
renderer = HtmlRenderer.new(STDOUT)
renderer.render(doc)


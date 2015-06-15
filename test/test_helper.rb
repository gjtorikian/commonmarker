require 'commonmarker'
require 'minitest/autorun'
require 'minitest/pride'

include CommonMarker

def open_spec_file(filename, options = {})
  line_number = 0
  start_line = 0
  end_line = 0
  example_number = 0
  markdown_lines = []
  html_lines = []
  state = 0 # 0 regular text, 1 markdown example, 2 html output
  headertext = ''
  tests = []

  header_re = Regexp.new('#+ ')
  filepath = File.join('ext', 'commonmarker', 'cmark', 'test', filename)

  File.readlines(filepath).each do |line|
    line_number += 1
    if state == 0 && header_re.match(line)
      headertext = line.sub(header_re, '').strip
    end

    if line.strip == '.'
      state = (state + 1) % 3
      if state == 0
        example_number += 1
        end_line = line_number
        tests << {
          :markdown => markdown_lines.join('').gsub('→', "\t"),
          :html => html_lines.join('').rstrip,
          :example => example_number,
          :start_line => start_line,
          :end_line => end_line,
          :section => headertext
        }
        start_line = 0
        markdown_lines = []
        html_lines = []
      end
    elsif state == 1
      start_line = line_number - 1 if start_line == 0
      markdown_lines << "#{line}"
    elsif state == 2
      html_lines << "#{line}"
    end
  end

  tests
end

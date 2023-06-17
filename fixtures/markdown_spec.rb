# frozen_string_literal: true

module MarkdownSpec
	def self.open(filename)
		line_number = 0
		start_line = 0
		end_line = 0
		example_number = 0
		markdown_lines = []
		html_lines = []
		state = 0 # 0 regular text, 1 markdown example, 2 html output
		headertext = ''
		tests = []
		extensions = []
		
		header_re = Regexp.new('#+ ')
		filepath = File.expand_path(filename, __dir__)
		
		File.readlines(filepath, encoding: 'utf-8').each do |line|
			line_number += 1
			
			l = line.strip
			if l =~ /^`{32} example(.*)$/
				state = 1
				extensions = Regexp.last_match(1).split
			elsif l == '`' * 32
				state = 0
				example_number += 1
				end_line = line_number
				tests << {
					markdown: markdown_lines.join('').tr('→', "\t"),
					html: html_lines.join('').tr('→', "\t").rstrip,
					example: example_number,
					start_line: start_line,
					end_line: end_line,
					section: headertext,
					extensions: extensions.map(&:to_sym)
				}
				start_line = 0
				markdown_lines = []
				html_lines = []
			elsif l == '.'
				state = 2
			elsif state == 1
				start_line = line_number - 1 if start_line.zero?
				markdown_lines << line.to_s
			elsif state == 2
				html_lines << line.to_s
			elsif state.zero? && header_re.match(line)
				headertext = line.sub(header_re, '').strip
			end
		end
		
		tests
	end
end

# frozen_string_literal: true

require "date"
require "rdoc/task"

namespace :docs do
  desc "Generate API documentation"
  RDoc::Task.new do |rd|
    rd.rdoc_dir = "docs"
    rd.main     = "README.md"
    rd.rdoc_files.include("README.md", "lib/**/*.rb", "ext/commonmarker/commonmarker.c")

    rd.options << "--markup tomdoc"
    rd.options << "--inline-source"
    rd.options << "--line-numbers"
    rd.options << "--all"
    rd.options << "--fileboxes"
  end

  desc "Generate the documentation and run a web server"
  task serve: [:rdoc] do
    require "webrick"

    puts "Navigate to http://localhost:3000 to see the docs"

    server = WEBrick::HTTPServer.new(Port: 3000)
    server.mount("/", WEBrick::HTTPServlet::FileHandler, "docs")
    trap("INT") { server.stop }
    server.start
  end

  desc "Generate and publish docs to gh-pages"
  task publish: [:rdoc] do
    require "tmpdir"
    require "shellwords"

    Dir.mktmpdir do |tmp|
      system "mv docs/* #{tmp}"
      system "git checkout origin/gh-pages"
      system "rm -rf *"
      system "mv #{tmp}/* ."
      message = Shellwords.escape("Site updated at #{Time.now.utc}")
      system "git add ."
      system "git commit -am #{message}"
      system "git push origin gh-pages --force"
      system "git checkout master"
      system "echo yolo"
    end
  end
end

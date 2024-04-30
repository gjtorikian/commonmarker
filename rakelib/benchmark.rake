# frozen_string_literal: true

desc "Run benchmarks"
task :benchmark do
  unless File.exist?("test/progit")
    %x(rm -rf test/progit)
    %x(git clone https://github.com/progit/progit.git test/progit)
    langs = ["ar", "az", "be", "ca", "cs", "de", "en", "eo", "es", "es-ni", "fa", "fi", "fr", "hi", "hu", "id", "it", "ja", "ko", "mk", "nl", "no-nb", "pl", "pt-br", "ro", "ru", "sr", "th", "tr", "uk", "vi", "zh", "zh-tw"]
    langs.each do |lang|
      %x(cat test/progit/#{lang}/*/*.markdown >> test/benchmark/large.md)
    end
  end
  $LOAD_PATH.unshift("lib")
  load "test/benchmark.rb"
end

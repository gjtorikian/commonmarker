# frozen_string_literal: true

desc "Run benchmarks"
task :benchmark do
  unless File.exist?("benchmark/progit")
    %x(rm -rf benchmark/progit)
    %x(git clone https://github.com/progit/progit.git benchmark/progit)
    langs = ["ar", "az", "be", "ca", "cs", "de", "en", "eo", "es", "es-ni", "fa", "fi", "fr", "hi", "hu", "id", "it", "ja", "ko", "mk", "nl", "no-nb", "pl", "pt-br", "ro", "ru", "sr", "th", "tr", "uk", "vi", "zh", "zh-tw"]
    langs.each do |lang|
      %x(cat benchmark/progit/#{lang}/*/*.markdown >> benchmark/large.md)
    end
  end
  $LOAD_PATH.unshift("lib")
  load "benchmark/benchmark.rb"
end

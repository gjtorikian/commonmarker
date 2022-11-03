# frozen_string_literal: true

CrossRuby = Struct.new(:version, :platform) do
  WINDOWS_PLATFORM_REGEX = /mingw|mswin/
  MINGWUCRT_PLATFORM_REGEX = /mingw-ucrt/
  MINGW32_PLATFORM_REGEX = /mingw32/
  LINUX_PLATFORM_REGEX = /linux/
  X86_LINUX_PLATFORM_REGEX = /x86.*linux/
  AARCH_LINUX_PLATFORM_REGEX = /aarch.*linux/
  ARM_LINUX_PLATFORM_REGEX = /arm-linux/
  DARWIN_PLATFORM_REGEX = /darwin/

  def windows?
    !!(platform =~ WINDOWS_PLATFORM_REGEX)
  end

  def linux?
    !!(platform =~ LINUX_PLATFORM_REGEX)
  end

  def darwin?
    !!(platform =~ DARWIN_PLATFORM_REGEX)
  end

  def ver
    @ver ||= version[/\A[^-]+/]
  end

  def minor_ver
    @minor_ver ||= ver[/\A\d\.\d(?=\.)/]
  end

  def api_ver_suffix
    case minor_ver
    when nil
      raise "CrossRuby.api_ver_suffix: unsupported version: #{ver}"
    else
      minor_ver.delete(".") << "0"
    end
  end

  def host
    @host ||= case platform
    when "x64-mingw-ucrt"
      "x86_64-w64-mingw32"
    when "x64-mingw32"
      "x86_64-w64-mingw32"
    when "x86-mingw32"
      "i686-w64-mingw32"
    when "x86_64-linux"
      "x86_64-linux-gnu"
    when "x86-linux"
      "i686-linux-gnu"
    when "aarch64-linux"
      "aarch64-linux"
    when "x86_64-darwin"
      "x86_64-darwin"
    when "arm64-darwin"
      "aarch64-darwin"
    else
      raise "CrossRuby.platform: unsupported platform: #{platform}"
    end
  end

  def tool(name)
    (@binutils_prefix ||= case platform
     when "x64-mingw-ucrt", "x64-mingw32"
       "x86_64-w64-mingw32-"
     when "x86-mingw32"
       "i686-w64-mingw32-"
     when "x86_64-linux"
       "x86_64-redhat-linux-"
     when "x86-linux"
       "i686-redhat-linux-"
     when "aarch64-linux"
       "aarch64-linux-gnu-"
     when "x86_64-darwin"
       "x86_64-apple-darwin-"
     when "arm64-darwin"
       "aarch64-apple-darwin-"
     when "arm-linux"
       "arm-linux-gnueabihf-"
     else
       raise "CrossRuby.tool: unmatched platform: #{platform}"
     end) + name
  end

  def target_file_format
    case platform
    when "x64-mingw-ucrt", "x64-mingw32"
      "pei-x86-64"
    when "x86-mingw32"
      "pei-i386"
    when "x86_64-linux"
      "elf64-x86-64"
    when "x86-linux"
      "elf32-i386"
    when "aarch64-linux"
      "elf64-littleaarch64"
    when "x86_64-darwin"
      "Mach-O 64-bit x86-64" # hmm
    when "arm64-darwin"
      "Mach-O arm64"
    when "arm-linux"
      "elf32-littlearm"
    else
      raise "CrossRuby.target_file_format: unmatched platform: #{platform}"
    end
  end

  def libruby_dll
    case platform
    when "x64-mingw-ucrt"
      "x64-ucrt-ruby#{api_ver_suffix}.dll"
    when "x64-mingw32"
      "x64-msvcrt-ruby#{api_ver_suffix}.dll"
    when "x86-mingw32"
      "msvcrt-ruby#{api_ver_suffix}.dll"
    else
      raise "CrossRuby.libruby_dll: unmatched platform: #{platform}"
    end
  end
end

CROSS_RUBIES = File.read(".cross_rubies").split("\n").filter_map do |line|
  case line
  when /\A([^#]+):([^#]+)/
    CrossRuby.new(Regexp.last_match(1), Regexp.last_match(2))
  end
end

ENV["RUBY_CC_VERSION"] = CROSS_RUBIES.map(&:ver).uniq.join(":")

CROSS_PLATFORMS = CROSS_RUBIES.find_all { |cr| cr.windows? || cr.linux? || cr.darwin? }.map(&:platform).uniq

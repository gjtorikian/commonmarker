require_relative "_dependencies"

# what follows is pretty much an abuse of miniportile2, but it works
# I just need something to download files and run a cargo build;
# miniportile2 comes with sha checks and retries
def make_mini_portile(name, version, repo:)
  require "rubygems"
  gem("mini_portile2", REQUIRED_MINI_PORTILE_VERSION) # gemspec is not respected at install time
  require "mini_portile2"

  MiniPortile.new(name, version, repo: repo).tap do |recipe|
    def recipe.dependencies
      raise "dependencies.yml not found at #{File.join(GEM_ROOT_DIR, "dependencies.yml")}" unless File.exist?(File.join(GEM_ROOT_DIR, "dependencies.yml"))

      return @dependencies if defined?(@dependencies)
      @dependencies = YAML.load_file(File.join(GEM_ROOT_DIR, "dependencies.yml"))
    end

    def recipe.dependency_sha256
      dependencies[@name]["sha256"]
    end

    def recipe.files_hashs
      files
    end

    def recipe.port_path
      "#{@target}/#{RUBY_PLATFORM}/#{@name}/#{@version}"
    end

    def recipe.checkpoint
      "#{@target}/#{@name}-#{@version}-#{RUBY_PLATFORM}.compiled"
    end

    def recipe.rename
      curr_name = File.join(archive_path, "#{@version}.tar.gz")
      new_name = File.join(archive_path, "#{@name}-#{@version}.tar.gz")

      # could've been previously downloaded and never removed
      # (rake clean leaves it alone)
      return if File.exist?(new_name)

      File.rename(curr_name, new_name)
    end

    def recipe.cargo_build(target: "")
      commands = ["cargo", "build", "--manifest-path=./c-api/Cargo.toml", "--release"]

      commands << "--target=#{target}" unless target.empty?

      execute('cargo_build', commands)
    end

    def recipe.extracted_ffi_path
      File.join(GEM_ROOT_DIR, "tmp", RUBY_PLATFORM, "commonmarker", RUBY_VERSION, tmp_path, "#{@name}-#{@version}", "c-api")
    end

    def recipe.archive_path
      File.join(GEM_ROOT_DIR, "ports", "archives")
    end

    def recipe.output_path_from_ffi
      File.join(extracted_ffi_path, "target", "release")
    end

    def recipe.output_path
      File.join(path, "release")
    end

    def recipe.header_path_from_ffi
      File.join(extracted_ffi_path, "include")
    end

    def recipe.header_path
      File.join(path, "include")
    end

    def recipe.compiled?
      cargo_toml  = File.join(extracted_ffi_path, 'Cargo.toml')

      newer?(cargo_toml, checkpoint)
    end

    @repo = repo
    recipe.target = File.join(GEM_ROOT_DIR, "ports")
    recipe.host = RbConfig::CONFIG["host_alias"].empty? ? RbConfig::CONFIG["host"] : RbConfig::CONFIG["host_alias"]
    recipe.configure_options << "--libdir=#{File.join(recipe.path, "lib")}"

    env = Hash.new do |hash, key|
      hash[key] = (ENV[key]).to_s
    end

    if config_static?
      recipe.configure_options += [
        "--disable-shared",
        "--enable-static",
      ]
      env["CFLAGS"] = concat_flags(env["CFLAGS"], "-fPIC")
    else
      recipe.configure_options += [
        "--enable-shared",
        "--disable-static",
      ]
    end

    if config_cross_build?
      recipe.configure_options += [
        "--target=#{recipe.host}",
        "--host=#{recipe.host}",
      ]
    end

    if RbConfig::CONFIG["target_cpu"] == "universal"
      ["CFLAGS", "LDFLAGS"].each do |key|
        unless env[key].include?("-arch")
          env[key] = concat_flags(env[key], RbConfig::CONFIG["ARCH_FLAG"])
        end
      end
    end

    recipe.configure_options += env.map do |key, value|
      "#{key}=#{value.strip}"
    end

    tarball_url = "https://github.com/#{@repo}/archive/#{recipe.version}.tar.gz"

    recipe.files = [{
      url: tarball_url,
      local_path: File.join(recipe.archive_path, "#{recipe.name}-#{recipe.version}.tar.gz"),
      sha256: recipe.dependency_sha256,
    }]

    checkpoint = "#{recipe.target}/#{recipe.name}-#{recipe.version}-#{RUBY_PLATFORM}.compiled"
    if !File.exist?(checkpoint)
      chdir_for_build do
        puts "Downloading tarball from #{tarball_url} ..."
        recipe.download unless recipe.downloaded?
        recipe.rename
        recipe.extract

        # we want to target mingw, but rust gives msvc by default
        target = if windows?
                    x86_64? ? "x86_64-pc-windows-gnu" : "i686-pc-windows-gnu"
                 else
                    ""
                 end

        recipe.cargo_build(target: target) unless recipe.compiled?

        FileUtils.rm_rf(recipe.path, secure: true)

        FileUtils.touch(recipe.checkpoint)
      end
    else
      puts "Checkpoint found at #{checkpoint}, skipping download and build"
    end
    FileUtils.mkdir_p(recipe.path)

    # mingw insists on files not being present when copying
    if File.exist?(recipe.extracted_ffi_path)
      FileUtils.rm_rf(recipe.output_path, secure: true)
      FileUtils.cp_r(recipe.output_path_from_ffi, recipe.output_path)

      FileUtils.rm_rf(recipe.header_path, secure: true)
      FileUtils.cp_r(recipe.header_path_from_ffi, recipe.header_path)

      puts "Output files copied to #{recipe.path}"
    end

    recipe.activate
  end
end

def build_comrak
  dependency_name = "comrak"
  dependency = DEPENDENCIES[dependency_name]
  dependency_repo = dependency["repo"]
  dependency_version = dependency["version"]

  make_mini_portile(dependency_name, dependency_version, repo: dependency_repo)
end

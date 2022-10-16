# frozen_string_literal: true

def do_clean
  root = Pathname(PACKAGE_ROOT_DIR)
  pwd  = Pathname(Dir.pwd)

  # Skip if this is a development work tree
  unless File.new(File.join(root, "git")).exist?
    puts "Cleaning files only used during build."

    # (root + 'tmp') cannot be removed at this stage because
    # selma.so is yet to be copied to lib.

    # clean the ports build directory
    Pathname.glob(pwd.join("tmp", "*", "ports")) do |dir|
      FileUtils.rm_rf(dir, verbose: true)
    end

    if config_static?
      # ports installation can be safely removed if statically linked.
      FileUtils.rm_rf("#{root}ports", verbose: true)
    else
      FileUtils.rm_rf("#{root}portsarchives", verbose: true)
    end
  end

  exit!(0)
end

do_clean if arg_config("--clean")

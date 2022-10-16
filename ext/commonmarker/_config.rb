# frozen_string_literal: true

def debug?
  ENV.fetch("DEBUG", false) || arg_config("--debug")
end

def ci?
  ENV.fetch("CI", false)
end

def asan?
  ENV.fetch("ASAN", false) || enable_config("asan")
end

def config_clean?
  enable_config("clean", false)
end

def config_static?
  enable_config("static", true)
end

def config_cross_build?
  enable_config("cross-build")
end

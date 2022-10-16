# frozen_string_literal: true

SELMA_HELP_MESSAGE = <<~HELP
  USAGE: ruby #{$PROGRAM_NAME} [options]

    Flags that are always valid:

      --disable-clean
          Do not clean out intermediate files after successful build.


    Flags only used when using system libraries:

      General:

        --with-opt-dir=DIRECTORY
            Look for headers and libraries in DIRECTORY.

        --with-opt-lib=DIRECTORY
            Look for libraries in DIRECTORY.

        --with-opt-include=DIRECTORY
            Look for headers in DIRECTORY.

    Flags only used when building and using the packaged libraries:

      --disable-static
          Do not statically link packaged libraries, instead use shared libraries.

      --enable-cross-build
          Enable cross-build mode. (You probably do not want to set this manually.)

      --debug
          Take steps to prevent stripping the symbol table and debugging info from the shared
          library, potentially overriding RbConfig's CFLAGS/LDFLAGS/DLDFLAGS.

    Environment variables used:

      CC
          Use this path to invoke the compiler instead of `RbConfig::CONFIG['CC']`

      CPPFLAGS
          If this string is accepted by the C preprocessor, add it to the flags passed to the C preprocessor

      CFLAGS
          If this string is accepted by the compiler, add it to the flags passed to the compiler

      LDFLAGS
          If this string is accepted by the linker, add it to the flags passed to the linker

      LIBS
          Add this string to the flags passed to the linker
HELP

def do_help
  print(SELMA_HELP_MESSAGE)
  exit!(0)
end

do_help if arg_config("--help")

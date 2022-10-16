# frozen_string_literal: true

require "rake/clean"
CLEAN.add(
  "coverage",
  "ext/commonmarker/include",
  "lib/commonmarker/[0-9].[0-9]",
  "lib/commonmarker/commonmarker.{bundle,jar,rb,so}",
  "pkg",
  "tmp",
)
CLEAN.add("ports/*").exclude(%r{ports/archives$})

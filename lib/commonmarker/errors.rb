# frozen_string_literal: true

class Commonmarker
  # Raised when a document nests more deeply than the `max_nesting_depth`
  # parse option allows.
  class NestingDepthExceededError < StandardError; end
end

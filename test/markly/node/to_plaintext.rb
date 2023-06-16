# frozen_string_literal: true

require 'markly'

MARKDOWN = <<~MD
Hi *there*!

1. I am a numeric list.
2. I continue the list.
* Suddenly, an unordered list!
* What fun!

Okay, _enough_.

| a   | b   |
| --- | --- |
| c   | d   |
MD

PLAINTEXT = <<~PLAINTEXT
Hi there!

1.  I am a numeric list.
2.  I continue the list.

  - Suddenly, an unordered list!
  - What fun!

Okay, enough.

| a | b |
| --- | --- |
| c | d |
PLAINTEXT

describe Markly do
  let(:document) {Markly.parse(MARKDOWN, extensions: %i[table])}
  
  it "can generate plaintext" do
    expect(document.to_plaintext).to be == PLAINTEXT
  end
end

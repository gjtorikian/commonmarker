# frozen_string_literal: true

require "test_helper"

class TasklistsTest < Minitest::Test
  def test_to_html
    text = <<-MD
 - [x] Add task list
 - [ ] Define task list
    MD
    html = Commonmarker.to_html(text, options: { extension: { tasklist: true } })
    expected = <<~HTML
      <ul>
      <li><input type="checkbox" checked="" disabled="" /> Add task list</li>
      <li><input type="checkbox" disabled="" /> Define task list</li>
      </ul>
    HTML

    assert_equal(expected, html)
  end

  def test_to_html_with_tasklist_classes
    text = <<-MD
 - [x] Add task list
 - [ ] Define task list
    MD
    html = Commonmarker.to_html(text, options: { extension: { tasklist: true }, render: { tasklist_classes: true } })
    expected = <<~HTML
      <ul class="contains-task-list">
      <li class="task-list-item"><input type="checkbox" class="task-list-item-checkbox" checked="" disabled="" /> Add task list</li>
      <li class="task-list-item"><input type="checkbox" class="task-list-item-checkbox" disabled="" /> Define task list</li>
      </ul>
    HTML

    assert_equal(expected, html)
  end
end

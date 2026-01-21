# Heading 1

## Heading 2

### Heading 3

#### Heading 4

##### Heading 5

###### Heading 6

---

## Text Formatting

**Bold text** and __also bold__

*Italic text* and _also italic_

~~Strikethrough text~~

**Bold and _italic_ combined**

## Links and Images

[Inline link](https://example.com)

[Reference link][ref]

![Alt text](https://example.com/image.png "Image title")

[ref]: https://example.com/reference

## Lists

### Unordered

- Item 1
- Item 2
  - Nested item
  - Another nested
    - Deep nested
- Item 3

### Ordered

1. First
2. Second
   1. Nested first
   2. Nested second
3. Third

### Task Lists

- [x] Completed task
- [ ] Incomplete task
- [x] Another completed

## Blockquotes

> Single blockquote with some text that spans
> multiple lines to test wrapping behavior.

> Blockquote with multiple paragraphs.
>
> Second paragraph in the same blockquote.

> Outer blockquote
>
> > Nested blockquote
> >
> > > Deeply nested

## Code

Inline `code` example and `another one`.

```ruby
# Ruby code block
def hello(name)
  puts "Hello, #{name}!"
end

hello("World")
```

```javascript
// JavaScript code block
function greet(name) {
  return `Hello, ${name}!`;
}

console.log(greet("World"));
```

```python
# Python code block
def factorial(n):
    if n <= 1:
        return 1
    return n * factorial(n - 1)

print(factorial(5))
```

    # Indented code block
    def indented_example
      puts "This is indented code"
    end

## Tables

| Left Aligned | Center Aligned | Right Aligned |
|:-------------|:--------------:|--------------:|
| Left 1       | Center 1       | Right 1       |
| Left 2       | Center 2       | Right 2       |
| Left 3       | Center 3       | Right 3       |

| Column A | Column B | Column C |
|----------|----------|----------|
| A1       | B1       | C1       |
| A2       | B2       | C2       |

## Horizontal Rules

---

***

___

## Autolinks

Visit https://github.com/gjtorikian/commonmarker for more info.

Contact support@example.com for help.

## HTML Elements

<div>
A div element with some content.
</div>

<details>
<summary>Click to expand</summary>

This content is hidden by default.

- Item inside details
- Another item

</details>

## Escaping

\*Not italic\*

\`Not code\`

\[Not a link\]

## Line Breaks

This line has two spaces at the end
to create a line break.

This line uses a backslash\
to create a line break.

## Paragraphs

This is the first paragraph. It contains multiple sentences to test how paragraph handling works with longer content.

This is the second paragraph. It's separated from the first by a blank line.

## Mixed Content

Here's a paragraph with **bold**, *italic*, `code`, and a [link](https://example.com) all mixed together. This tests how the parser handles multiple inline elements.

> A blockquote containing **bold text**, *italic text*, and `inline code`.
>
> - A list inside a blockquote
> - With multiple items

1. An ordered list item with `code`
2. Another item with **bold** and *italic*
3. Third item with a [link](https://example.com)

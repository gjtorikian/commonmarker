#include "cmark_ctype.h"
#include "cmark-gfm.h"
#include "config.h"

static bool is_wordchar(char c) {
  return cmark_isalnum(c) || c == '_' || c == '-';
}

bool is_part_of_mention(unsigned char *data, bufsize_t offset) {
  int i;
  int lookbehind_limit = (int)-offset;
  char character;

  for (i = 0; i >= lookbehind_limit; i--) {
    character = data[i];

    if (is_wordchar(character)) {
      // Continue lookbehind.
    } else if (character == '@') {
      if (i == offset) {
        // The "@" is at beginning of the text. (e.g. "@foo")
        return true;
      } else {
        // Check if the previous character of the "@" is alphanumeric or not.
        //   " @foo" and "あ@foo" are mentions.
        //   "a@foo" is not a mention.
        char prev_character = data[i - 1];
        return !cmark_isalnum(prev_character);
      }
    } else {
      // Found non-mention character, so this is not a mention.
      return false;
    }
  }

  return false;
}

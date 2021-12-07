/*!re2c re2c:flags:no-debug-info = 1; */
/*!re2c re2c:indent:string = '  '; */

#include "qfm_scanners.h"
#include <stdlib.h>

bufsize_t _qfm_scan_at(bufsize_t (*scanner)(const unsigned char *),
                       unsigned char *ptr, int len, bufsize_t offset) {
  bufsize_t res;

  if (ptr == NULL || offset >= len) {
    return 0;
  } else {
    unsigned char lim = ptr[len];

    ptr[len] = '\0';
    res = scanner(ptr + offset);
    ptr[len] = lim;
  }

  return res;
}

/*!re2c
  re2c:define:YYCTYPE  = "unsigned char";
  re2c:define:YYCURSOR = p;
  re2c:define:YYMARKER = marker;
  re2c:define:YYCTXMARKER = marker;
  re2c:yyfill:enable = 0;
*/

// Scan an opening qfm_custom_block fence.
bufsize_t _scan_open_qfm_custom_block_fence(const unsigned char *p) {
  const unsigned char *marker = NULL;
  const unsigned char *start = p;
  /*!re2c
    [:]{3,} / [^:\r\n\x00]*[\r\n] { return (bufsize_t)(p - start); }
    * { return 0; }
  */
}

// Scan a closing qfm_custom_block fence with length at least len.
bufsize_t _scan_close_qfm_custom_block_fence(const unsigned char *p) {
  const unsigned char *marker = NULL;
  const unsigned char *start = p;
  /*!re2c
    [:]{3,} / [ \t]*[\r\n] { return (bufsize_t)(p - start); }
    * { return 0; }
  */
}

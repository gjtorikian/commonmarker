#include "chunk.h"
#include "cmark-gfm.h"

#ifdef __cplusplus
extern "C" {
#endif

bufsize_t _qfm_scan_at(bufsize_t (*scanner)(const unsigned char *),
                       unsigned char *ptr, int len, bufsize_t offset);
bufsize_t _scan_open_qfm_custom_block_fence(const unsigned char *p);
bufsize_t _scan_close_qfm_custom_block_fence(const unsigned char *p);

#define scan_open_qfm_custom_block_fence(c, l, n)                              \
  _qfm_scan_at(&_scan_open_qfm_custom_block_fence, c, l, n)
#define scan_close_qfm_custom_block_fence(c, l, n)                             \
  _qfm_scan_at(&_scan_close_qfm_custom_block_fence, c, l, n)

#ifdef __cplusplus
}
#endif

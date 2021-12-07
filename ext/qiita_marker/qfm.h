#ifndef QFM_H
#define QFM_H

#ifdef __cplusplus
extern "C" {
#endif

/** Use <pre><code data-metadata="x"> tags for code blocks instead of <pre><code
 * class="language-x">. **/
#define CMARK_OPT_CODE_DATA_METADATA (1 << 25)

/* Prevent parsing Qiita-style Mentions as emphasis. */
#define CMARK_OPT_MENTION_NO_EMPHASIS (1 << 26)

#ifdef __cplusplus
}
#endif

#endif

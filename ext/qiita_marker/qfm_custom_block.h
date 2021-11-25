#ifndef QFM_CUSTOM_BLOCK_H
#define QFM_CUSTOM_BLOCK_H

#include "cmark-gfm-core-extensions.h"

extern cmark_node_type CMARK_NODE_QFM_CUSTOM_BLOCK;

cmark_syntax_extension *create_qfm_custom_block_extension(void);

#endif

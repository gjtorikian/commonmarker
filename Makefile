C_SOURCES = $(wildcard ext/commonmarker/cmark/*/*)

update-c-sources: $(C_SOURCES)

ext/commonmarker/cmark/%: ext/commonmarker/cmark-upstream/%
	cp $< $@

ext/commonmarker/cmark/src/config.h: ext/commonmarker/cmark-upstream/build/src/config.h
	cp $< $@

ext/commonmarker/cmark/src/cmark_export.h: ext/commonmarker/cmark-upstream/build/src/cmark_export.h
	cp $< $@

ext/commonmarker/cmark/src/cmark_version.h: ext/commonmarker/cmark-upstream/build/src/cmark_version.h
	cp $< $@

ext/commonmarker/cmark/extensions/cmarkextensions_export.h: ext/commonmarker/cmark-upstream/build/extensions/cmarkextensions_export.h
	cp $< $@

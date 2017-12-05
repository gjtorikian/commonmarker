C_SOURCES = $(wildcard ext/commonmarker/*.[ch])

update-c-sources: $(C_SOURCES)

ext/commonmarker/%: ext/commonmarker/cmark-upstream/src/%
	cp $< $@

ext/commonmarker/%: ext/commonmarker/cmark-upstream/extensions/%
	cp $< $@

ext/commonmarker/config.h: ext/commonmarker/cmark-upstream/build/src/config.h
	cp $< $@

ext/commonmarker/cmark_export.h: ext/commonmarker/cmark-upstream/build/src/cmark_export.h
	cp $< $@

ext/commonmarker/cmark_version.h: ext/commonmarker/cmark-upstream/build/src/cmark_version.h
	cp $< $@

ext/commonmarker/cmarkextensions_export.h: ext/commonmarker/cmark-upstream/build/extensions/cmarkextensions_export.h
	cp $< $@

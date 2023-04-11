C_SOURCES = $(wildcard ext/commonmarker/*.[ch])

update-c-sources: build-upstream $(C_SOURCES)

.PHONY: build-upstream

build-upstream:
	cd ext/commonmarker/cmark-upstream && make

ext/commonmarker/%: ext/commonmarker/cmark-upstream/src/%
	cp $< $@

ext/commonmarker/%: ext/commonmarker/cmark-upstream/extensions/%
	cp $< $@

ext/commonmarker/config.h: ext/commonmarker/cmark-upstream/build/src/config.h
	cp $< $@

ext/commonmarker/cmark-gfm_export.h: ext/commonmarker/cmark-upstream/build/src/cmark-gfm_export.h
	cp $< $@

ext/commonmarker/cmark-gfm_version.h: ext/commonmarker/cmark-upstream/build/src/cmark-gfm_version.h
	cp $< $@

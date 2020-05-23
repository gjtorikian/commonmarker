C_SOURCES = $(wildcard ext/markly/*.[ch])

update-c-sources: build-upstream $(C_SOURCES)

.PHONY: build-upstream

build-upstream:
	cd cmark-gfm && make

ext/markly/%: cmark-gfm/src/%
	cp $< $@

ext/markly/%: cmark-gfm/extensions/%
	cp $< $@

ext/markly/config.h: cmark-gfm/build/src/config.h
	cp $< $@

ext/markly/cmark-gfm_export.h: cmark-gfm/build/src/cmark-gfm_export.h
	cp $< $@

ext/markly/cmark-gfm_version.h: cmark-gfm/build/src/cmark-gfm_version.h
	cp $< $@

ext/markly/cmark-gfm-extensions_export.h: cmark-gfm/build/extensions/cmark-gfm-extensions_export.h
	cp $< $@

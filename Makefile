C_SOURCES = $(wildcard ext/qiita_marker/*.[ch])

update-c-sources: build-upstream $(C_SOURCES)

.PHONY: build-upstream

build-upstream:
	cd ext/qiita_marker/cmark-upstream && make

ext/qiita_marker/%: ext/qiita_marker/cmark-upstream/src/%
	cp $< $@

ext/qiita_marker/%: ext/qiita_marker/cmark-upstream/extensions/%
	cp $< $@

ext/qiita_marker/config.h: ext/qiita_marker/cmark-upstream/build/src/config.h
	cp $< $@

ext/qiita_marker/cmark-gfm_export.h: ext/qiita_marker/cmark-upstream/build/src/cmark-gfm_export.h
	cp $< $@

ext/qiita_marker/cmark-gfm_version.h: ext/qiita_marker/cmark-upstream/build/src/cmark-gfm_version.h
	cp $< $@

ext/qiita_marker/cmark-gfm-extensions_export.h: ext/qiita_marker/cmark-upstream/build/extensions/cmark-gfm-extensions_export.h
	cp $< $@

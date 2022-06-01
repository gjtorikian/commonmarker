# Changelog

## [v0.23.4](https://github.com/gjtorikian/qiita_marker/tree/v0.23.4) (2022-03-03)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.23.2...v0.23.4)

**Fixed bugs:**

- `#render_html` way slower than `#render_doc.to_html` [\#141](https://github.com/gjtorikian/qiita_marker/issues/141)

**Closed issues:**

- allow keeping text content of unknown tags [\#169](https://github.com/gjtorikian/qiita_marker/issues/169)
- STRIKETHROUGH\_DOUBLE\_TILDE not working [\#168](https://github.com/gjtorikian/qiita_marker/issues/168)
- Allow disabling 4-space code blocks [\#167](https://github.com/gjtorikian/qiita_marker/issues/167)
- tables with escaped pipes are not recognized [\#166](https://github.com/gjtorikian/qiita_marker/issues/166)

**Merged pull requests:**

- CI: Drop a duplicate 'bundle install' [\#173](https://github.com/gjtorikian/qiita_marker/pull/173) ([olleolleolle](https://github.com/olleolleolle))
- CI: Drop duplicate bundle install [\#172](https://github.com/gjtorikian/qiita_marker/pull/172) ([olleolleolle](https://github.com/olleolleolle))
- Fixup benchmark and speedup a little, fixes \#141 [\#171](https://github.com/gjtorikian/qiita_marker/pull/171) ([ojab](https://github.com/ojab))

## [v0.23.2](https://github.com/gjtorikian/qiita_marker/tree/v0.23.2) (2021-09-17)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.23.1...v0.23.2)

**Merged pull requests:**

- Update GFM release to `0.29.0.gfm.2` [\#148](https://github.com/gjtorikian/qiita_marker/pull/148) ([phillmv](https://github.com/phillmv))

## [v0.23.1](https://github.com/gjtorikian/qiita_marker/tree/v0.23.1) (2021-09-03)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.23.0...v0.23.1)

**Closed issues:**

- Incorrect processing of list and next block of code [\#146](https://github.com/gjtorikian/qiita_marker/issues/146)

**Merged pull requests:**

- Normalize parse and render options [\#145](https://github.com/gjtorikian/qiita_marker/pull/145) ([phillmv](https://github.com/phillmv))

## [v0.23.0](https://github.com/gjtorikian/qiita_marker/tree/v0.23.0) (2021-08-30)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.22.0...v0.23.0)

**Closed issues:**

- Latest version of qiita_marker breaks with jekyll build [\#142](https://github.com/gjtorikian/qiita_marker/issues/142)

**Merged pull requests:**

- Add support for rendering XML from cmark-gfm [\#144](https://github.com/gjtorikian/qiita_marker/pull/144) ([digitalmoksha](https://github.com/digitalmoksha))

## [v0.22.0](https://github.com/gjtorikian/qiita_marker/tree/v0.22.0) (2021-06-20)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.21.2...v0.22.0)

**Closed issues:**

- Recommendations on how to have autolink for phone numbers? [\#139](https://github.com/gjtorikian/qiita_marker/issues/139)
- Add option to disable indented code blocs [\#138](https://github.com/gjtorikian/qiita_marker/issues/138)
- Tagging "tasklist" lists with a class for easy styling? [\#137](https://github.com/gjtorikian/qiita_marker/issues/137)
- Escape math environments [\#136](https://github.com/gjtorikian/qiita_marker/issues/136)
- Open to removing the ruby-enum dependency? [\#135](https://github.com/gjtorikian/qiita_marker/issues/135)
- In HtmlRenderer, escape\_html\(\) returns a string with encoding \#\<Encoding:ASCII-8BIT\> [\#130](https://github.com/gjtorikian/qiita_marker/issues/130)

**Merged pull requests:**

- Remove `ruby-enum` dependency [\#140](https://github.com/gjtorikian/qiita_marker/pull/140) ([ojab](https://github.com/ojab))
- Copy encoding when escaping hrefs/HTML [\#133](https://github.com/gjtorikian/qiita_marker/pull/133) ([kivikakk](https://github.com/kivikakk))

## [v0.21.2](https://github.com/gjtorikian/qiita_marker/tree/v0.21.2) (2021-02-11)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.21.1...v0.21.2)

**Closed issues:**

- Potential to cut a new release? [\#129](https://github.com/gjtorikian/qiita_marker/issues/129)

**Merged pull requests:**

- Switch to GitHub Actions [\#132](https://github.com/gjtorikian/qiita_marker/pull/132) ([gjtorikian](https://github.com/gjtorikian))
- Support :FOOTNOTES option for rendering HTML [\#131](https://github.com/gjtorikian/qiita_marker/pull/131) ([aharpole](https://github.com/aharpole))

## [v0.21.1](https://github.com/gjtorikian/qiita_marker/tree/v0.21.1) (2021-01-21)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.21.0...v0.21.1)

**Closed issues:**

- Dependency error on new M1 Mac [\#128](https://github.com/gjtorikian/qiita_marker/issues/128)
- Inlines containing a pipe are not properly parsed within table rows [\#125](https://github.com/gjtorikian/qiita_marker/issues/125)
- Allow code snippets in multiple programming language [\#124](https://github.com/gjtorikian/qiita_marker/issues/124)
- Provide access to `refmap`. [\#121](https://github.com/gjtorikian/qiita_marker/issues/121)
- Numbered checklist [\#120](https://github.com/gjtorikian/qiita_marker/issues/120)
- Is there a specification for how URL slugs for headers are generated? [\#118](https://github.com/gjtorikian/qiita_marker/issues/118)

**Merged pull requests:**

- Fix mismatched indentation [\#127](https://github.com/gjtorikian/qiita_marker/pull/127) ([naoty](https://github.com/naoty))
- Avoid a YARD annotation warning [\#119](https://github.com/gjtorikian/qiita_marker/pull/119) ([olleolleolle](https://github.com/olleolleolle))

## [v0.21.0](https://github.com/gjtorikian/qiita_marker/tree/v0.21.0) (2020-01-23)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.20.2...v0.21.0)

**Closed issues:**

- Changelog [\#110](https://github.com/gjtorikian/qiita_marker/issues/110)
- Documentation out of date [\#109](https://github.com/gjtorikian/qiita_marker/issues/109)

**Merged pull requests:**

- Add Node\#tasklist\_item\_checked= [\#116](https://github.com/gjtorikian/qiita_marker/pull/116) ([tomoasleep](https://github.com/tomoasleep))
- clear up an example in the README [\#115](https://github.com/gjtorikian/qiita_marker/pull/115) ([kivikakk](https://github.com/kivikakk))
- Update GFM release [\#113](https://github.com/gjtorikian/qiita_marker/pull/113) ([gjtorikian](https://github.com/gjtorikian))
- Rubocop updates [\#111](https://github.com/gjtorikian/qiita_marker/pull/111) ([gjtorikian](https://github.com/gjtorikian))

## [v0.20.2](https://github.com/gjtorikian/qiita_marker/tree/v0.20.2) (2019-12-18)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.20.1...v0.20.2)

**Closed issues:**

- Bug when parse word with spaces in tags [\#106](https://github.com/gjtorikian/qiita_marker/issues/106)
- UNSAFE mode inserts \<p\> tags inside \<pre\> tag [\#102](https://github.com/gjtorikian/qiita_marker/issues/102)
- Wrong path gets encoded in Makefile: /home/conda/feedstock\_root/build\_artifacts/ruby\_1552262701982/\_build\_env/bin/x86\_64-conda\_cos6-linux-gnu-cc: Command not found [\#101](https://github.com/gjtorikian/qiita_marker/issues/101)

**Merged pull requests:**

- Add command line input for parse and render options [\#108](https://github.com/gjtorikian/qiita_marker/pull/108) ([digitalmoksha](https://github.com/digitalmoksha))
- Add tasklist extension description to README [\#103](https://github.com/gjtorikian/qiita_marker/pull/103) ([tomoasleep](https://github.com/tomoasleep))

## [v0.20.1](https://github.com/gjtorikian/qiita_marker/tree/v0.20.1) (2019-04-29)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.20.0...v0.20.1)

**Closed issues:**

- 100mb test/benchinput.md file is included in published rubygem [\#99](https://github.com/gjtorikian/qiita_marker/issues/99)

**Merged pull requests:**

- tasklist state inverted [\#100](https://github.com/gjtorikian/qiita_marker/pull/100) ([kivikakk](https://github.com/kivikakk))

## [v0.20.0](https://github.com/gjtorikian/qiita_marker/tree/v0.20.0) (2019-04-09)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.19.0...v0.20.0)

**Closed issues:**

- Footnotes not working with autolink when its including "w" ? [\#95](https://github.com/gjtorikian/qiita_marker/issues/95)

**Merged pull requests:**

- update to cmark-gfm 0.29.0.gfm.0 [\#98](https://github.com/gjtorikian/qiita_marker/pull/98) ([kivikakk](https://github.com/kivikakk))

## [v0.19.0](https://github.com/gjtorikian/qiita_marker/tree/v0.19.0) (2019-04-03)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.18.2...v0.19.0)

**Closed issues:**

- .render\_html throws an error when given a parse-only option such as :SMART [\#96](https://github.com/gjtorikian/qiita_marker/issues/96)
- code in header produce invalid anchor [\#93](https://github.com/gjtorikian/qiita_marker/issues/93)
- Escaping of square brackets for reference-style links [\#91](https://github.com/gjtorikian/qiita_marker/issues/91)
- Please add an option for accessible footnotes [\#89](https://github.com/gjtorikian/qiita_marker/issues/89)
- ISSUE [\#82](https://github.com/gjtorikian/qiita_marker/issues/82)

**Merged pull requests:**

- Indicte the context of an option [\#97](https://github.com/gjtorikian/qiita_marker/pull/97) ([gjtorikian](https://github.com/gjtorikian))
- Bump dependencies to support tasklists [\#94](https://github.com/gjtorikian/qiita_marker/pull/94) ([gjtorikian](https://github.com/gjtorikian))
- Remove cmake dependency from Travis [\#92](https://github.com/gjtorikian/qiita_marker/pull/92) ([gjtorikian](https://github.com/gjtorikian))
- Fixes up whitespace problems introduced in \#87 [\#90](https://github.com/gjtorikian/qiita_marker/pull/90) ([diachini](https://github.com/diachini))
- GitHub is https by default [\#88](https://github.com/gjtorikian/qiita_marker/pull/88) ([amatsuda](https://github.com/amatsuda))

## [v0.18.2](https://github.com/gjtorikian/qiita_marker/tree/v0.18.2) (2018-11-28)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.18.1...v0.18.2)

**Closed issues:**

- Request: Support for Description Lists [\#86](https://github.com/gjtorikian/qiita_marker/issues/86)
- Code block vanishes in latest with qiita_marker-rouge [\#85](https://github.com/gjtorikian/qiita_marker/issues/85)
- Request : Image Size Issues [\#84](https://github.com/gjtorikian/qiita_marker/issues/84)
- 'stdlib.h' file not found [\#83](https://github.com/gjtorikian/qiita_marker/issues/83)

**Merged pull requests:**

- Allow `:UNSAFE` option for parsing [\#87](https://github.com/gjtorikian/qiita_marker/pull/87) ([gjtorikian](https://github.com/gjtorikian))

## [v0.18.1](https://github.com/gjtorikian/qiita_marker/tree/v0.18.1) (2018-10-18)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.18.0...v0.18.1)

## [v0.18.0](https://github.com/gjtorikian/qiita_marker/tree/v0.18.0) (2018-10-17)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.17.13...v0.18.0)

**Closed issues:**

- Math engine support \($$ $$\) [\#80](https://github.com/gjtorikian/qiita_marker/issues/80)

**Merged pull requests:**

- Latest upstream [\#81](https://github.com/gjtorikian/qiita_marker/pull/81) ([kivikakk](https://github.com/kivikakk))

## [v0.17.13](https://github.com/gjtorikian/qiita_marker/tree/v0.17.13) (2018-09-10)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.17.12...v0.17.13)

**Merged pull requests:**

- bump to cmark-gfm 0.28.3.gfm.16 [\#79](https://github.com/gjtorikian/qiita_marker/pull/79) ([kivikakk](https://github.com/kivikakk))

## [v0.17.12](https://github.com/gjtorikian/qiita_marker/tree/v0.17.12) (2018-09-07)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.17.11...v0.17.12)

**Closed issues:**

- Bump gem to latest cmark-gfm... [\#77](https://github.com/gjtorikian/qiita_marker/issues/77)
- Tag 0.17.10 and 0.17.11 [\#75](https://github.com/gjtorikian/qiita_marker/issues/75)

**Merged pull requests:**

- Update cmark-upstream  [\#78](https://github.com/gjtorikian/qiita_marker/pull/78) ([gjtorikian](https://github.com/gjtorikian))
- grab header/define fixes [\#76](https://github.com/gjtorikian/qiita_marker/pull/76) ([kivikakk](https://github.com/kivikakk))

## [v0.17.11](https://github.com/gjtorikian/qiita_marker/tree/v0.17.11) (2018-08-10)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/0.17.10...v0.17.11)

**Closed issues:**

- Parsing additional info string as meta data on \<pre\> tags [\#72](https://github.com/gjtorikian/qiita_marker/issues/72)

**Merged pull requests:**

- Bring in plaintext strikethrough rendering fix [\#74](https://github.com/gjtorikian/qiita_marker/pull/74) ([kivikakk](https://github.com/kivikakk))

## [0.17.10](https://github.com/gjtorikian/qiita_marker/tree/0.17.10) (2018-08-08)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.17.10...0.17.10)

## [v0.17.10](https://github.com/gjtorikian/qiita_marker/tree/v0.17.10) (2018-08-08)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.17.9...v0.17.10)

**Closed issues:**

- Unable to install qiita_marker on OS X [\#71](https://github.com/gjtorikian/qiita_marker/issues/71)

**Merged pull requests:**

- --full-info-string [\#73](https://github.com/gjtorikian/qiita_marker/pull/73) ([kivikakk](https://github.com/kivikakk))

## [v0.17.9](https://github.com/gjtorikian/qiita_marker/tree/v0.17.9) (2018-03-12)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.17.8...v0.17.9)

**Closed issues:**

- Failed to build gem native extension/ no rule to make target [\#67](https://github.com/gjtorikian/qiita_marker/issues/67)

**Merged pull requests:**

- Remove square brackets when rendering HTML for footnotes [\#69](https://github.com/gjtorikian/qiita_marker/pull/69) ([pyrmont](https://github.com/pyrmont))
- Update both parse and render options in README [\#68](https://github.com/gjtorikian/qiita_marker/pull/68) ([blackst0ne](https://github.com/blackst0ne))

## [v0.17.8](https://github.com/gjtorikian/qiita_marker/tree/v0.17.8) (2018-02-21)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.17.7.1...v0.17.8)

**Closed issues:**

- extension tasklist not found [\#64](https://github.com/gjtorikian/qiita_marker/issues/64)
- Request: mermaid rendering support within markdown [\#63](https://github.com/gjtorikian/qiita_marker/issues/63)
- Installation / make error in windows 10 [\#62](https://github.com/gjtorikian/qiita_marker/issues/62)
- Permissions error when installing on Windows 7 machine [\#61](https://github.com/gjtorikian/qiita_marker/issues/61)

**Merged pull requests:**

- Support the TABLE\_PREFER\_STYLE\_ATTRIBUTES render option [\#66](https://github.com/gjtorikian/qiita_marker/pull/66) ([gfx](https://github.com/gfx))
- Fix issues with tables during a round-trip parsing CM and then producing CM again. [\#65](https://github.com/gjtorikian/qiita_marker/pull/65) ([jerryjvl](https://github.com/jerryjvl))

## [v0.17.7.1](https://github.com/gjtorikian/qiita_marker/tree/v0.17.7.1) (2017-12-10)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.17.7...v0.17.7.1)

**Closed issues:**

- 0.17.6 install fails [\#59](https://github.com/gjtorikian/qiita_marker/issues/59)

## [v0.17.7](https://github.com/gjtorikian/qiita_marker/tree/v0.17.7) (2017-12-05)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.17.6...v0.17.7)

**Closed issues:**

- Bump cmark-gfm to get support of footnotes [\#58](https://github.com/gjtorikian/qiita_marker/issues/58)

**Merged pull requests:**

- No cmake required! [\#60](https://github.com/gjtorikian/qiita_marker/pull/60) ([kivikakk](https://github.com/kivikakk))

## [v0.17.6](https://github.com/gjtorikian/qiita_marker/tree/v0.17.6) (2017-11-16)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.17.5...v0.17.6)

## [v0.17.5](https://github.com/gjtorikian/qiita_marker/tree/v0.17.5) (2017-10-19)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/0.17.4...v0.17.5)

**Closed issues:**

- \<tbody\> is missed on rendering doc [\#56](https://github.com/gjtorikian/qiita_marker/issues/56)
- Bold link in italics followed by a period [\#53](https://github.com/gjtorikian/qiita_marker/issues/53)
- Extensions are not documented [\#52](https://github.com/gjtorikian/qiita_marker/issues/52)

**Merged pull requests:**

- Reset `needs_close_tbody` when entering tables [\#57](https://github.com/gjtorikian/qiita_marker/pull/57) ([gjtorikian](https://github.com/gjtorikian))
- Link to libcmark-gfm [\#55](https://github.com/gjtorikian/qiita_marker/pull/55) ([kivikakk](https://github.com/kivikakk))
- Document the extensions in the README [\#54](https://github.com/gjtorikian/qiita_marker/pull/54) ([gjtorikian](https://github.com/gjtorikian))

## [0.17.4](https://github.com/gjtorikian/qiita_marker/tree/0.17.4) (2017-10-03)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/0.17.3...0.17.4)

## [0.17.3](https://github.com/gjtorikian/qiita_marker/tree/0.17.3) (2017-09-11)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/0.17.2...0.17.3)

## [0.17.2](https://github.com/gjtorikian/qiita_marker/tree/0.17.2) (2017-09-08)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/0.17.1...0.17.2)

## [0.17.1](https://github.com/gjtorikian/qiita_marker/tree/0.17.1) (2017-09-06)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/0.17.0...0.17.1)

## [0.17.0](https://github.com/gjtorikian/qiita_marker/tree/0.17.0) (2017-08-25)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/0.16.9...0.17.0)

## [0.16.9](https://github.com/gjtorikian/qiita_marker/tree/0.16.9) (2017-08-17)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/0.16.8...0.16.9)

**Closed issues:**

- Deployment - Cannot bundle qiita_marker due to cmake [\#50](https://github.com/gjtorikian/qiita_marker/issues/50)

**Merged pull requests:**

- Update link to the CMark docs options [\#51](https://github.com/gjtorikian/qiita_marker/pull/51) ([unRob](https://github.com/unRob))

## [0.16.8](https://github.com/gjtorikian/qiita_marker/tree/0.16.8) (2017-07-17)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/0.16.7...0.16.8)

## [0.16.7](https://github.com/gjtorikian/qiita_marker/tree/0.16.7) (2017-07-12)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/0.16.6...0.16.7)

## [0.16.6](https://github.com/gjtorikian/qiita_marker/tree/0.16.6) (2017-07-11)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/0.16.5...0.16.6)

## [0.16.5](https://github.com/gjtorikian/qiita_marker/tree/0.16.5) (2017-06-30)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/0.16.4...0.16.5)

## [0.16.4](https://github.com/gjtorikian/qiita_marker/tree/0.16.4) (2017-06-27)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/0.16.3...0.16.4)

**Merged pull requests:**

- Full support for options and extensions in HtmlRenderer [\#48](https://github.com/gjtorikian/qiita_marker/pull/48) ([kivikakk](https://github.com/kivikakk))

## [0.16.3](https://github.com/gjtorikian/qiita_marker/tree/0.16.3) (2017-06-21)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/0.16.2...0.16.3)

## [0.16.2](https://github.com/gjtorikian/qiita_marker/tree/0.16.2) (2017-06-21)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/0.16.1...0.16.2)

## [0.16.1](https://github.com/gjtorikian/qiita_marker/tree/0.16.1) (2017-06-21)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.16.0...0.16.1)

**Closed issues:**

- Cannot bundle qiita_marker due to cmake [\#47](https://github.com/gjtorikian/qiita_marker/issues/47)

## [v0.16.0](https://github.com/gjtorikian/qiita_marker/tree/v0.16.0) (2017-05-08)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.15.0...v0.16.0)

**Merged pull requests:**

- Plaintext renderer support [\#46](https://github.com/gjtorikian/qiita_marker/pull/46) ([kivikakk](https://github.com/kivikakk))
- Drop the remaining cached gems from the project [\#45](https://github.com/gjtorikian/qiita_marker/pull/45) ([Empact](https://github.com/Empact))

## [v0.15.0](https://github.com/gjtorikian/qiita_marker/tree/v0.15.0) (2017-04-22)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.14.16...v0.15.0)

**Closed issues:**

- Request: PrettyPrint support for QiitaMarker::Node [\#42](https://github.com/gjtorikian/qiita_marker/issues/42)

**Merged pull requests:**

- support p and pp for QiitaMarker::Node [\#44](https://github.com/gjtorikian/qiita_marker/pull/44) ([gfx](https://github.com/gfx))
- Fix a typo [\#43](https://github.com/gjtorikian/qiita_marker/pull/43) ([muan](https://github.com/muan))

## [v0.14.16](https://github.com/gjtorikian/qiita_marker/tree/v0.14.16) (2017-04-04)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.14.15...v0.14.16)

**Closed issues:**

- Github/QiitaMarker is parsing images/markup inconsistently. [\#41](https://github.com/gjtorikian/qiita_marker/issues/41)
- doc: contains corrupt UTF-8; thus gem does not install cleanly [\#40](https://github.com/gjtorikian/qiita_marker/issues/40)

## [v0.14.15](https://github.com/gjtorikian/qiita_marker/tree/v0.14.15) (2017-04-03)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.14.14...v0.14.15)

## [v0.14.14](https://github.com/gjtorikian/qiita_marker/tree/v0.14.14) (2017-03-27)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.14.13...v0.14.14)

## [v0.14.13](https://github.com/gjtorikian/qiita_marker/tree/v0.14.13) (2017-03-26)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.14.12...v0.14.13)

**Closed issues:**

- Encoding error [\#39](https://github.com/gjtorikian/qiita_marker/issues/39)

**Merged pull requests:**

- Add Yuki [\#38](https://github.com/gjtorikian/qiita_marker/pull/38) ([gjtorikian](https://github.com/gjtorikian))

## [v0.14.12](https://github.com/gjtorikian/qiita_marker/tree/v0.14.12) (2017-03-22)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.14.11...v0.14.12)

## [v0.14.11](https://github.com/gjtorikian/qiita_marker/tree/v0.14.11) (2017-03-22)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.14.10...v0.14.11)

## [v0.14.10](https://github.com/gjtorikian/qiita_marker/tree/v0.14.10) (2017-03-21)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.14.9...v0.14.10)

## [v0.14.9](https://github.com/gjtorikian/qiita_marker/tree/v0.14.9) (2017-03-20)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.14.8...v0.14.9)

**Closed issues:**

- option ':default' does not exist for QiitaMarker::Config::Render [\#37](https://github.com/gjtorikian/qiita_marker/issues/37)

## [v0.14.8](https://github.com/gjtorikian/qiita_marker/tree/v0.14.8) (2017-03-15)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.14.7...v0.14.8)

## [v0.14.7](https://github.com/gjtorikian/qiita_marker/tree/v0.14.7) (2017-03-13)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.14.6...v0.14.7)

## [v0.14.6](https://github.com/gjtorikian/qiita_marker/tree/v0.14.6) (2017-03-13)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.14.5...v0.14.6)

## [v0.14.5](https://github.com/gjtorikian/qiita_marker/tree/v0.14.5) (2017-03-06)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.14.4...v0.14.5)

**Closed issues:**

- ruby-enum v0.7.1 breaks the gem [\#35](https://github.com/gjtorikian/qiita_marker/issues/35)

**Merged pull requests:**

- Capitalize symbol names [\#36](https://github.com/gjtorikian/qiita_marker/pull/36) ([gjtorikian](https://github.com/gjtorikian))

## [v0.14.4](https://github.com/gjtorikian/qiita_marker/tree/v0.14.4) (2017-02-23)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.14.3...v0.14.4)

**Closed issues:**

- Table extension with HTML Renderer causes segfault [\#34](https://github.com/gjtorikian/qiita_marker/issues/34)

## [v0.14.3](https://github.com/gjtorikian/qiita_marker/tree/v0.14.3) (2017-02-06)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.14.2...v0.14.3)

**Closed issues:**

- Extensions disabled in IRB? [\#33](https://github.com/gjtorikian/qiita_marker/issues/33)

## [v0.14.2](https://github.com/gjtorikian/qiita_marker/tree/v0.14.2) (2017-01-27)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.14.1...v0.14.2)

## [v0.14.1](https://github.com/gjtorikian/qiita_marker/tree/v0.14.1) (2017-01-23)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.14.0...v0.14.1)

## [v0.14.0](https://github.com/gjtorikian/qiita_marker/tree/v0.14.0) (2016-12-13)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.13.0...v0.14.0)

**Merged pull requests:**

- Extensions targetting github/cmark [\#32](https://github.com/gjtorikian/qiita_marker/pull/32) ([kivikakk](https://github.com/kivikakk))

## [v0.13.0](https://github.com/gjtorikian/qiita_marker/tree/v0.13.0) (2016-11-27)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.12.0...v0.13.0)

**Closed issues:**

- `node.string_content` is not utf-8 [\#30](https://github.com/gjtorikian/qiita_marker/issues/30)

**Merged pull requests:**

- Update cmark to 0.27.1 [\#31](https://github.com/gjtorikian/qiita_marker/pull/31) ([gjtorikian](https://github.com/gjtorikian))

## [v0.12.0](https://github.com/gjtorikian/qiita_marker/tree/v0.12.0) (2016-10-11)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.11.0...v0.12.0)

**Merged pull requests:**

- Revert "cmark extensions" [\#29](https://github.com/gjtorikian/qiita_marker/pull/29) ([gjtorikian](https://github.com/gjtorikian))

## [v0.11.0](https://github.com/gjtorikian/qiita_marker/tree/v0.11.0) (2016-09-18)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.10.0...v0.11.0)

**Closed issues:**

- No rule to make target libcmark\_static [\#22](https://github.com/gjtorikian/qiita_marker/issues/22)

**Merged pull requests:**

- cmark extensions [\#28](https://github.com/gjtorikian/qiita_marker/pull/28) ([kivikakk](https://github.com/kivikakk))

## [v0.10.0](https://github.com/gjtorikian/qiita_marker/tree/v0.10.0) (2016-07-21)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.9.2...v0.10.0)

**Merged pull requests:**

- Update cmark to https://github.com/jgm/cmark/commit/e91dc12128b156f1b… [\#27](https://github.com/gjtorikian/qiita_marker/pull/27) ([gjtorikian](https://github.com/gjtorikian))

## [v0.9.2](https://github.com/gjtorikian/qiita_marker/tree/v0.9.2) (2016-06-07)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.9.1...v0.9.2)

**Closed issues:**

- Using render options with a custom renderer [\#25](https://github.com/gjtorikian/qiita_marker/issues/25)

**Merged pull requests:**

- Get memory magic [\#26](https://github.com/gjtorikian/qiita_marker/pull/26) ([gjtorikian](https://github.com/gjtorikian))

## [v0.9.1](https://github.com/gjtorikian/qiita_marker/tree/v0.9.1) (2016-05-24)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.9.0...v0.9.1)

## [v0.9.0](https://github.com/gjtorikian/qiita_marker/tree/v0.9.0) (2016-05-18)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.8.0...v0.9.0)

**Closed issues:**

- Make `Node` an `Enumerable` so that it can iterate over its children [\#23](https://github.com/gjtorikian/qiita_marker/issues/23)

**Merged pull requests:**

- Make `Node` an `Enumerable` [\#24](https://github.com/gjtorikian/qiita_marker/pull/24) ([gjtorikian](https://github.com/gjtorikian))

## [v0.8.0](https://github.com/gjtorikian/qiita_marker/tree/v0.8.0) (2016-04-04)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.7.0...v0.8.0)

**Merged pull requests:**

- Update cmark to 0.25.2 [\#21](https://github.com/gjtorikian/qiita_marker/pull/21) ([gjtorikian](https://github.com/gjtorikian))

## [v0.7.0](https://github.com/gjtorikian/qiita_marker/tree/v0.7.0) (2016-01-20)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.6.0...v0.7.0)

**Merged pull requests:**

- Bump to 0.24 [\#20](https://github.com/gjtorikian/qiita_marker/pull/20) ([gjtorikian](https://github.com/gjtorikian))

## [v0.6.0](https://github.com/gjtorikian/qiita_marker/tree/v0.6.0) (2016-01-05)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.5.1...v0.6.0)

**Merged pull requests:**

- Update cmark to 0.23 [\#19](https://github.com/gjtorikian/qiita_marker/pull/19) ([gjtorikian](https://github.com/gjtorikian))

## [v0.5.1](https://github.com/gjtorikian/qiita_marker/tree/v0.5.1) (2015-11-04)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.5.0...v0.5.1)

**Closed issues:**

- Smart punctuation and hardbreaks don't mix in render\_doc [\#17](https://github.com/gjtorikian/qiita_marker/issues/17)

**Merged pull requests:**

- Mix and match options [\#18](https://github.com/gjtorikian/qiita_marker/pull/18) ([gjtorikian](https://github.com/gjtorikian))

## [v0.5.0](https://github.com/gjtorikian/qiita_marker/tree/v0.5.0) (2015-09-25)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.4.1...v0.5.0)

**Closed issues:**

- Direct access to sourcepos on the Node [\#15](https://github.com/gjtorikian/qiita_marker/issues/15)

**Merged pull requests:**

- Add `sourcepos` information [\#16](https://github.com/gjtorikian/qiita_marker/pull/16) ([gjtorikian](https://github.com/gjtorikian))

## [v0.4.1](https://github.com/gjtorikian/qiita_marker/tree/v0.4.1) (2015-08-26)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.4.0...v0.4.1)

**Closed issues:**

- libcmark is missing [\#13](https://github.com/gjtorikian/qiita_marker/issues/13)

**Merged pull requests:**

- Don't perform `find_library` on OS X's system Ruby [\#14](https://github.com/gjtorikian/qiita_marker/pull/14) ([gjtorikian](https://github.com/gjtorikian))

## [v0.4.0](https://github.com/gjtorikian/qiita_marker/tree/v0.4.0) (2015-08-24)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.3.0...v0.4.0)

**Merged pull requests:**

- Update cmark to 1f4632b8e761da5aaeebcefb2e43332ad267dba8 [\#12](https://github.com/gjtorikian/qiita_marker/pull/12) ([gjtorikian](https://github.com/gjtorikian))

## [v0.3.0](https://github.com/gjtorikian/qiita_marker/tree/v0.3.0) (2015-07-20)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.2.1...v0.3.0)

**Merged pull requests:**

- Bump cmark@0.21.0 [\#11](https://github.com/gjtorikian/qiita_marker/pull/11) ([gjtorikian](https://github.com/gjtorikian))

## [v0.2.1](https://github.com/gjtorikian/qiita_marker/tree/v0.2.1) (2015-07-07)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.2.0...v0.2.1)

**Closed issues:**

- Error "incompatible character encodings: UTF-8 and ASCII-8BIT" when combined with a rails app [\#9](https://github.com/gjtorikian/qiita_marker/issues/9)

**Merged pull requests:**

- UTF-8 issues [\#10](https://github.com/gjtorikian/qiita_marker/pull/10) ([gjtorikian](https://github.com/gjtorikian))

## [v0.2.0](https://github.com/gjtorikian/qiita_marker/tree/v0.2.0) (2015-06-26)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.1.3...v0.2.0)

**Closed issues:**

- Test all the tests/options in CMark [\#6](https://github.com/gjtorikian/qiita_marker/issues/6)

**Merged pull requests:**

- Implement Node class in C, fix memory management [\#8](https://github.com/gjtorikian/qiita_marker/pull/8) ([nwellnhof](https://github.com/nwellnhof))
- More testing [\#7](https://github.com/gjtorikian/qiita_marker/pull/7) ([gjtorikian](https://github.com/gjtorikian))

## [v0.1.3](https://github.com/gjtorikian/qiita_marker/tree/v0.1.3) (2015-05-27)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.1.2...v0.1.3)

**Closed issues:**

- Look into using the C AST walk  [\#3](https://github.com/gjtorikian/qiita_marker/issues/3)
- Don't force users to call `free`, if possible [\#2](https://github.com/gjtorikian/qiita_marker/issues/2)

**Merged pull requests:**

- Better memory management [\#5](https://github.com/gjtorikian/qiita_marker/pull/5) ([gjtorikian](https://github.com/gjtorikian))

## [v0.1.2](https://github.com/gjtorikian/qiita_marker/tree/v0.1.2) (2015-05-14)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.1.1...v0.1.2)

## [v0.1.1](https://github.com/gjtorikian/qiita_marker/tree/v0.1.1) (2015-05-14)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.1.0...v0.1.1)

## [v0.1.0](https://github.com/gjtorikian/qiita_marker/tree/v0.1.0) (2015-05-13)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/v0.0.1...v0.1.0)

**Merged pull requests:**

- Start wrapping C in Ruby [\#1](https://github.com/gjtorikian/qiita_marker/pull/1) ([gjtorikian](https://github.com/gjtorikian))

## [v0.0.1](https://github.com/gjtorikian/qiita_marker/tree/v0.0.1) (2015-05-10)

[Full Changelog](https://github.com/gjtorikian/qiita_marker/compare/963ec7e72ff5125b11b3fbc842bd077031fc6c90...v0.0.1)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*

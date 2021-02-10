set dir="%cd%"

git submodule sync
git submodule update --init
bundle
bundle exec rake clean compile
bundle exec rake test

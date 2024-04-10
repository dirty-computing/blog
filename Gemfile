source "https://rubygems.org"
ruby RUBY_VERSION

# This will help ensure the proper Jekyll version is running.
gem "jekyll", "4.2.0"
gem "webrick"
gem "cli-ui"
gem 'wdm', '~> 0.1.0' if Gem.win_platform?
gem 'execjs', '~> 2.8.1'
gem 'duktape', '~> 2.6.0.0'

group :development do
  gem 'dotenv', '~> 3.1'
end

group :jekyll_plugins do
  gem 'jekyll-katex'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]


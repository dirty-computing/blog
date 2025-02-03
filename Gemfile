source "https://rubygems.org"
ruby RUBY_VERSION

# This will help ensure the proper Jekyll version is running.
gem "jekyll", "4.3.3"
gem "webrick"
gem "cli-ui"
gem 'wdm', '~> 0.1.0' if Gem.win_platform?
gem 'execjs', '~> 2.8.1'
gem 'duktape', '~> 2.6.0.0'

gem 'sass-embedded', '~> 1.83'
gem 'google-protobuf', force_ruby_platform: RUBY_PLATFORM.include?('linux-musl')

group :development do
  gem 'dotenv', '~> 3.1'
end

group :jekyll_plugins do
  gem 'jekyll-katex'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]


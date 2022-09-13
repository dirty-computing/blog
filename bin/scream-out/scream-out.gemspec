# frozen_string_literal: true

require "rake"
require_relative "lib/scream-out/version"

Gem::Specification.new do |spec|
    spec.name = "scream-out"
    spec.version = ScreamOut::VERSION
    spec.authors = [ "Jefferson Quesado" ]
    spec.email = [ "jeff.quesado@gmail.com" ]

    spec.summary = "Grita para o Discord publicações do Computaria"
    spec.license = "MIT"
    spec.required_ruby_version = "~> 3.0"
    spec.bindir = "bin"

    spec.files = FileList[
        "lib/**/*.rb"
    ].to_a
    spec.executables << "scream-out"
end
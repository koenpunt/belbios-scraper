# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'belbios/scraper/version'

Gem::Specification.new do |spec|
  spec.name          = "belbios-scraper"
  spec.version       = Belbios::Scraper::VERSION
  spec.authors       = ["Koen Punt"]
  spec.email         = ["koen@koenpunt.nl"]
  spec.description   = %q{Belbios index scraper}
  spec.summary       = %q{A simple scraper for belbios.nl}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency "nokogiri", "~> 1.5"
  spec.add_dependency "chronic", "~> 0.9"
end

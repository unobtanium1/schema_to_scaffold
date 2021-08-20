# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'schema_to_scaffold/version'

Gem::Specification.new do |gem|
  gem.name          = "schema_to_scaffold"
  gem.version       = SchemaToScaffold::VERSION
  gem.authors       = ["João Soares", "Humberto Pinto"]
  gem.email         = ["jsoaresgeral@gmail.com", "hlsp999@gmail.com"]
  #if gem.respond_to?(:metadata)
  #  gem.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  #  gem.metadata['bug_tracker_uri'] = ""   => "https://example.com/user/bestgemever/issues",
  #  gem.metadata['changelog_uri'] = ""     => "https://example.com/user/bestgemever/CHANGELOG.md",
  #  gem.metadata['documentation_uri'] = "" => "https://www.example.info/gems/bestgemever/0.0.1",
  #  gem.metadata['homepage_uri'] = ""      => "https://bestgemever.example.io",
  #  gem.metadata['mailing_list_uri'] = ""  => "https://groups.example.com/bestgemever",
  #  gem.metadata['source_code_uri'] = ""   => "https://example.com/user/bestgemever",
  #  gem.metadata['wiki_uri'] = ""          => "https://example.com/user/bestgemever/wiki"
  #  gem.metadata['funding_uri'] = ""       => "https://example.com/donate"
  #else
  #  raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  #end
  gem.description   = <<-EOD
  Command line app which parses a schema.rb file obtained from your rails repo or by running rake:schema:dump
EOD
  gem.summary               = %q{Generate rails scaffold script from a schema.rb file.}
  gem.homepage              = "http://github.com/frenesim/schema_to_scaffold"
  gem.bindir                = "bin"
  gem.files                 = `git ls-files`.split($/)
  gem.executables           = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.require_paths         = ["lib"]
  gem.licenses              = ['MIT']
  gem.required_ruby_version = '>= 1.9.3'

  gem.add_runtime_dependency('activesupport', '>= 3.2.1')
  gem.add_development_dependency('pry', '~> 0.10', '>= 0.10.0')
  gem.add_development_dependency('rspec')
  gem.add_development_dependency('simplecov')
end

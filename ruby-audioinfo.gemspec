# -*- encoding: utf-8 -*-
# stub: ruby-audioinfo 0.3.3.20131025192033 ruby lib

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'audioinfo/version'

Gem::Specification.new do |s|
  s.name = "ruby-audioinfo"
  s.version = AudioInfo::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Guillaume Pierronnet", "Marcello Barnaba"]
  s.date = "2013-10-25"
  s.description = "ruby-audioinfo glue together various audio ruby libraries and presents a unified\nAPI to the developper. Currently, supported formats are: mp3, ogg, mpc, ape,\nwma, flac, aac, mp4, m4a."
  s.email = ["guillaume.pierronnet@gmail.com", "unknown"]
  s.homepage = "http://ruby-audioinfo.rubyforge.org"
  s.rdoc_options = ["--main", "README.rdoc"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.rdoc", "README.rdoc"]
  s.rubyforge_project = "ruby-audioinfo"
  s.rubygems_version = "2.1.5"
  s.summary = "ruby-audioinfo glue together various audio ruby libraries and presents a unified API to the developper"
  s.license = 'GPL-3.0'

  s.files = `git ls-files -z`.split("\x0")
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_runtime_dependency(%q<ruby-mp3info>, [">= 0.8"])
  s.add_runtime_dependency(%q<ruby-ogginfo>, [">= 0.6.13"])
  s.add_runtime_dependency(%q<mp4info>, [">= 1.7.3"])
  s.add_runtime_dependency(%q<moumar-wmainfo-rb>, [">= 0.7"])
  s.add_runtime_dependency(%q<flacinfo-rb>, [">= 0.4"])
  s.add_runtime_dependency(%q<apetag>, [">= 1.1.4"])
  s.add_runtime_dependency(%q<wavefile>, ["~> 0.6.0"])
  s.add_development_dependency(%q<rdoc>, ["~> 3.10"])
  s.add_development_dependency(%q<hoe>, ["~> 3.5"])
end

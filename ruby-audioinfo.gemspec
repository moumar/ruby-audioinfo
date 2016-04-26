# -*- encoding: utf-8 -*-
# stub: ruby-audioinfo 0.3.3.20131025192033 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby-audioinfo"
  s.version = AudioInfo::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Guillaume Pierronnet", "Marcello Barnaba"]
  s.date = "2013-10-25"
  s.description = "ruby-audioinfo glue together various audio ruby libraries and presents a unified\nAPI to the developper. Currently, supported formats are: mp3, ogg, mpc, ape,\nwma, flac, aac, mp4, m4a."
  s.email = ["guillaume.pierronnet@gmail.com", "unknown"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.rdoc", "README.rdoc"]
  s.files = ["History.txt", "Manifest.txt", "README.rdoc", "Rakefile", "lib/audioinfo.rb", "lib/audioinfo/album.rb", "lib/audioinfo/mpcinfo.rb", "lib/audioinfo/case_insensitive_hash.rb", "test/mpcinfo.rb", "test/test_audioinfo.rb", "test/test_case_insensitive_hash.rb", "test/test_helper.rb"]
  s.homepage = "http://ruby-audioinfo.rubyforge.org"
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "ruby-audioinfo"
  s.rubygems_version = "2.1.5"
  s.summary = "ruby-audioinfo glue together various audio ruby libraries and presents a unified API to the developper"
  s.test_files = ["test/test_audioinfo.rb", "test/test_case_insensitive_hash.rb", "test/test_helper.rb"]
  s.license = 'GPL-3.0'

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

# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "ruby-audioinfo"
  s.version = "0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Guillaume Pierronnet", "Marcello Barnaba"]
  s.date = "2012-04-02"
  s.description = "ruby-audioinfo glue together various audio ruby libraries and presents a unified\nAPI to the developper. Currently, supported formats are: mp3, ogg, mpc, ape,\nwma, flac, aac, mp4, m4a."
  s.email = ["guillaume.pierronnet@gmail.com", "unknown"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.rdoc"]
  s.files = ["History.txt", "Manifest.txt", "README.rdoc", "Rakefile", "lib/audioinfo.rb", "lib/audioinfo/album.rb", "lib/audioinfo/mpcinfo.rb", "test/mpcinfo.rb", ".gemtest"]
  s.homepage = "http://ruby-audioinfo.rubyforge.org"
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "ruby-audioinfo"
  s.rubygems_version = "1.8.17"
  s.summary = "ruby-audioinfo glue together various audio ruby libraries and presents a unified API to the developper"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ruby-mp3info>, [">= 0.7"])
      s.add_runtime_dependency(%q<ruby-ogginfo>, [">= 0.6.8"])
      s.add_runtime_dependency(%q<mp4info>, [">= 1.7.3"])
      s.add_runtime_dependency(%q<moumar-wmainfo-rb>, [">= 0.7"])
      s.add_runtime_dependency(%q<flacinfo-rb>, [">= 0.4"])
      s.add_runtime_dependency(%q<apetag>, [">= 1.1.4"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_development_dependency(%q<hoe>, ["~> 2.12"])
    else
      s.add_dependency(%q<ruby-mp3info>, [">= 0.7"])
      s.add_dependency(%q<ruby-ogginfo>, [">= 0.6.8"])
      s.add_dependency(%q<mp4info>, [">= 1.7.3"])
      s.add_dependency(%q<moumar-wmainfo-rb>, [">= 0.7"])
      s.add_dependency(%q<flacinfo-rb>, [">= 0.4"])
      s.add_dependency(%q<apetag>, [">= 1.1.4"])
      s.add_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_dependency(%q<hoe>, ["~> 2.12"])
    end
  else
    s.add_dependency(%q<ruby-mp3info>, [">= 0.7"])
    s.add_dependency(%q<ruby-ogginfo>, [">= 0.6.8"])
    s.add_dependency(%q<mp4info>, [">= 1.7.3"])
    s.add_dependency(%q<moumar-wmainfo-rb>, [">= 0.7"])
    s.add_dependency(%q<flacinfo-rb>, [">= 0.4"])
    s.add_dependency(%q<apetag>, [">= 1.1.4"])
    s.add_dependency(%q<rdoc>, ["~> 3.10"])
    s.add_dependency(%q<hoe>, ["~> 2.12"])
  end
end

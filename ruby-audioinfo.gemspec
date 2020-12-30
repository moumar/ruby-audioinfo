# frozen_string_literal: true

require_relative 'lib/audioinfo/version'

Gem::Specification.new do |spec|
  spec.name          = 'ruby-audioinfo'
  spec.version       = AudioInfo::VERSION
  spec.authors       = ['Guillaume Pierronnet', 'Marcello Barnaba']
  spec.email         = ['guillaume.pierronnet@gmail.com']
  spec.summary       = 'glues together various audio ruby libraries and presents a unified API to the developer'
  spec.description   = "#{spec.summary} Currently, supported formats are: mp3, ogg, mpc, ape, wma, flac, aac, mp4, m4a."
  spec.homepage      = 'https://github.com/moumar/ruby-audioinfo'
  spec.license       = 'GPL-3.0'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.7')
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/moumar/ruby-audioinfo/History.txt'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'apetag', '>= 1.1.4'
  spec.add_dependency 'flacinfo-rb', '>= 0.4'
  spec.add_dependency 'moumar-wmainfo-rb', '>= 0.7'
  spec.add_dependency 'mp4info', '>= 1.7.3'
  spec.add_dependency 'ruby-mp3info', '>= 0.8'
  spec.add_dependency 'ruby-ogginfo', '>= 0.6.13'
  spec.add_dependency 'wavefile', '~> 0.6.0'
end

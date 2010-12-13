require 'rubygems'
require "rake/rdoctask"

require File.join(File.expand_path(File.dirname(__FILE__)), 'lib', 'audioinfo')

begin
  require 'jeweler'

  #Jeweler::GemcutterTasks.new

  Jeweler::Tasks.new do |gemspec|
    gemspec.name        = 'ruby-audioinfo'
    gemspec.version     = AudioInfo::VERSION
    gemspec.authors     = ['Guillaume Pierronnet', 'Marcello Barnaba']
    gemspec.email       = 'moumar@rubyforge.org'
    gemspec.date        = '2010-03-20'

    gemspec.homepage    = 'http://ruby-audioinfo.rubyforge.org'
    gemspec.summary     = 'Unified audio info access library'
    gemspec.description = 'ruby-audioinfo glues together various audio libraries and presents a single API to the developer.'
                          'Currently, supported formats are: mp3, ogg, mpc, ape, wma, flac, aac, mp4, m4a.'

    gemspec.files            = %w( README.rdoc Rakefile History.txt) + Dir['{lib,test}/**/*']
    gemspec.extra_rdoc_files = %w( README.rdoc )
    gemspec.has_rdoc         = true
    gemspec.require_path     = 'lib'

    gemspec.add_dependency 'ruby-mp3info', '>= 0.6.3'
    gemspec.add_dependency 'ruby-ogginfo', '>= 0.3.1'
    gemspec.add_dependency 'mp4info',      '>= 1.7.3'
    gemspec.add_dependency 'wmainfo-rb',   '>= 0.5'
    gemspec.add_dependency 'flacinfo-rb',  '>= 0.4'
    gemspec.add_dependency 'apetag',  '= 1.1.2'
  end
  Jeweler::GemcutterTasks.new  

  Jeweler::RubyforgeTasks.new

rescue LoadError
  puts 'Jeweler not available. Install it with: gem install jeweler'
end

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_dir = "rdoc"
  rd.rdoc_files.include("README.rdoc", "History.txt", "lib/**/*.rb")
  rd.title = "ruby-audioinfo #{AudioInfo::VERSION}"
end

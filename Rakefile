# -*- ruby -*-

require 'hoe'

Hoe.plugin :yard
Hoe.plugin :gemspec

Hoe.spec('ruby-audioinfo') do 
  developer "Guillaume Pierronnet", "guillaume.pierronnet@gmail.com"
  developer 'Marcello Barnaba', "unknown"
  remote_rdoc_dir = ''
  rdoc_locations << "rubyforge.org:/var/www/gforge-projects/ruby-audioinfo/"

  self.extra_rdoc_files = FileList["*.rdoc"]
  #history_file = "History.txt"
  self.readme_file = "README.rdoc"
  self.test_globs = ["test/test_*.rb"]
  self.rsync_args = "-rv --delete" 

  extra_deps << ['ruby-mp3info', '>= 0.8']
  extra_deps << ['ruby-ogginfo', '>= 0.6.13']
  extra_deps << ['mp4info',      '>= 1.7.3']
  extra_deps << ['moumar-wmainfo-rb',   '>= 0.7']
  extra_deps << ['flacinfo-rb',  '>= 0.4']
  extra_deps << ['apetag',       '>= 1.1.4']
  #extra_dev_deps << ["rake", ">=0"]
end

=begin
# vim: syntax=Ruby
require 'rubygems'
require "rake/rdoctask"

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_dir = "rdoc"
  rd.rdoc_files.include("README.rdoc", "History.txt", "lib/**/*.rb")
  rd.title = "ruby-audioinfo #{AudioInfo::VERSION}"
end
=end

require 'rubygems'
require 'hoe'

$: << 'lib'
require 'audioinfo'

Hoe.spec('ruby-audioinfo') do
  self.version     = AudioInfo::VERSION
  self.author      = 'Guillaume Pierronnet'
  self.email       = 'moumar@rubyforge.org'

  self.url         = 'http://ruby-audioinfo.rubyforge.org'
  self.summary     = 'ruby-audioinfo glue together various audio ruby libraries and presents a single API to the developper. Currently, supported formats are: mp3, ogg, mpc, ape, wma, flac, aac, mp4, m4a.'
  self.description = paragraphs_of('README.txt', 3).first
  self.changes     = paragraphs_of('History.txt', 0..1).join("\n\n")

  self.extra_deps << [ "ruby-mp3info", ">= 0.6.3" ]
  self.extra_deps << [ "ruby-ogginfo", ">= 0.3.1" ]
  self.extra_deps << [ "mp4Info",      ">= 1.7.3" ]
  self.extra_deps << [ "wmainfo-rb",   ">= 0.5"   ]
  self.extra_deps << [ "flacinfo-rb",  ">= 0.4"   ]
end

#task :tag_svn do
#  svn_repo = "svn+ssh://rubyforge.org/var/svn/ruby-audioinfo"
#  sh "svn copy -m 'tagged version #{hoe.version}' #{svn_repo}/trunk #{svn_repo}/tags/REL-#{hoe.version}"
#end

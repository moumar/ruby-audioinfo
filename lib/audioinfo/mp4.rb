# frozen_string_literal: true

require 'mp4info'
require 'open3'

module AudioInfo
  class Mp4 < AudioFile
    def parse(filename)
      @extension = 'mp4'
      @info = MP4Info.open(filename)
      @artist = @info.ART
      @album = @info.ALB
      @title = @info.NAM
      @tracknum = (t = @info.TRKN) ? t.first : 0
      @date = @info.DAY
      @bitrate = @info.BITRATE
      @length = @info.SECS
      mapping = MUSICBRAINZ_FIELDS.invert

      faad_info(filename).scan(/^MusicBrainz (.+): (.+)$/) do |match|
        name, value = match
        key = mapping[name]
        next unless key

        @musicbrainz_infos[key] = value.strip.gsub("\u0000", '')
      end
    end

    def faad_info(path)
      output = ''
      status = nil

      return unless system('which faad > /dev/null')

      Open3.popen3('faad', '-i', path) do |_stdin, _stdout, stderr, wait_thr|
        output = stderr.read.chomp
        status = wait_thr.value
      end

      status.exitstatus.zero? ? output : ''
    end
  end
end

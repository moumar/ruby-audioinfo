# frozen_string_literal: true

require 'ogginfo'

module AudioInfo
  class Ogg < AudioFile
    def parse(filename)
      @info = OggInfo.new(filename)
      default_fill_musicbrainz_fields
      default_tag_fill
      @bitrate = @info.bitrate / 1000
      @tracknum = @info.tag.tracknumber.to_i
      @length = @info.length.to_i
      @date = @info.tag['date']
      @vbr = true
      @info.close
    rescue OggInfoError => e
      raise AudioInfoError, e.to_s, e.backtrace
    end

    def close
      return unless @needs_commit

      OggInfo.open(@path) do |ogg|
        { 'artist' => @artist,
          'album' => @album,
          'title' => @title,
          'tracknumber' => @tracknum }.each do |k, v|
          ogg.tag[k] = v.to_s
        end
        ogg.picture = @picture if @picture
      end

      @needs_commit
    end
  end
end

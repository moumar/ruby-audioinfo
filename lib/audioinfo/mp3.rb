# frozen_string_literal: true

require 'mp3info'

module AudioInfo
  class Mp3 < AudioFile
    def parse(filename)
      @info = Mp3Info.new(filename)
      default_tag_fill

      # Mp3Info parses additional tags into TXXX
      if (arr = @info.tag2['TXXX']).is_a?(Array)
        fields = MUSICBRAINZ_FIELDS.invert
        arr.each do |val|
          next unless val =~ /^MusicBrainz (.+)\000(.*)$/

          short_name = fields[Regexp.last_match(1)]
          next unless short_name

          @musicbrainz_infos[short_name] =
            Regexp.last_match(2).gsub(String.new("\xEF\xBB\xBF").force_encoding('UTF-8'), '')
        end
      end

      # MusicBrainz Track ID is over here:
      @musicbrainz_infos['trackid'] = @info.tag2['UFID']&.split("\x00")&.last

      @bitrate = @info.bitrate
      i = @info.tag.tracknum
      @tracknum = (i.is_a?(Array) ? i.last : i).to_i
      @length = @info.length.to_i
      @date = @info.tag['date']
      @vbr = @info.vbr
      @info.close
    rescue Mp3InfoError => e
      raise AudioInfoError, e.to_s, e.backtrace
    end

    def close
      return unless @needs_commit

      Mp3Info.open(@path) do |info|
        info.tag.artist = @artist
        info.tag.title = @title
        info.tag.album = @album
        info.tag.tracknum = @tracknum
        if @picture
          info.tag2.remove_pictures
          info.tag2.add_picture(File.binread(@picture))
        end
      end

      @needs_commit
    end
  end
end

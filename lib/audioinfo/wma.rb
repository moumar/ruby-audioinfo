# frozen_string_literal: true

require 'wmainfo'

module AudioInfo
  class Wma < AudioFile
    def parse(filename)
      @info = WmaInfo.new(filename, encoding: 'utf-8')
      tags = @info.tags.map { |k, v| [k.strip, v.strip] }.to_h

      @artist = tags['Author']
      @album = tags['AlbumTitle']
      @title = tags['Title']
      @tracknum = tags['TrackNumber'].to_i
      @date = tags['Year']
      @bitrate = @info.info['bitrate']
      @length = @info.info['playtime_seconds']

      info = @info.info.map do |k, v|
        [
          k.respond_to?(:strip) ? k.strip : k,
          v.respond_to?(:strip) ? v.strip : v
        ]
      end.to_h

      MUSICBRAINZ_FIELDS.each do |key, original_key|
        @musicbrainz_infos[key] =
          info["MusicBrainz/#{original_key.tr(' ', '')}"] ||
          info["MusicBrainz/#{original_key}"]
      end
    end
  end
end

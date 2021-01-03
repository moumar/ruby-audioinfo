# frozen_string_literal: true

require 'flacinfo'

require_relative 'case_insensitive_hash'

module AudioInfo
  class Flac < AudioFile
    def parse(filename)
      @info = FlacInfo.new(filename)
      # Unfortunately, FlacInfo doesn't allow us to fiddle inside
      # their class, so we have to brute force it. Any other
      # solution (e.g. creating another abstraction or getting
      # methods) lands up being more messy and brittle.
      @info.instance_variable_set('@tags', CaseInsensitiveHash.new(@info.tags))

      @artist = get_tag('artist')
      @album = get_tag('album')
      @title = get_tag('title')
      @tracknum = @info.tags['tracknumber'].to_i
      @date = get_tag('date')
      @bitrate = 0
      @length = @info.streaminfo['total_samples'] / @info.streaminfo['samplerate'].to_f
      @bitrate = File.size(filename).to_f * 8 / @length / 1024 if @length.positive?
      @info.tags.each do |tagname, _tagvalue|
        next unless tagname =~ /^musicbrainz_(.+)$/

        @musicbrainz_infos[Regexp.last_match(1)] = get_tag(tagname)
      end
      @musicbrainz_infos['trmid'] = @info.tags['musicip_puid']
      # default_fill_musicbrainz_fields
    end

    def close
      return unless @needs_commit

      have_metaflac = system('which metaflac > /dev/null')

      if have_metaflac
        tags = { 'ARTIST' => @artist,
                 'ALBUM' => @album,
                 'TITLE' => @title,
                 'TRACKNUMBER' => @tracknum }.inject([]) do |t, (key, value)|
          t + ['--set-tag', "#{key}=#{value}"]
        end
        tag_with_shell_command('metaflac', '--remove-all', :src)
        tag_with_shell_command('metaflac', tags, :src)
      else
        super
      end

      @needs_commit
    end

    private

    def get_tag(name)
      @info.tags[name]&.dup&.force_encoding('utf-8')
    end
  end
end

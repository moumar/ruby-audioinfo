# frozen_string_literal: true

module AudioInfo
  class AudioFile
    MUSICBRAINZ_FIELDS = {
      'trmid'         => 'TRM Id',
      'artistid'      => 'Artist Id',
      'albumid'       => 'Album Id',
      'albumtype'	    => 'Album Type',
      'albumstatus'   => 'Album Status',
      'albumartistid' => 'Album Artist Id',
      'sortname'      => 'Sort Name',
      'trackid'       => 'Track Id'
    }.freeze

    attr_reader :path, :extension, :musicbrainz_infos, :tracknum, :bitrate, :vbr, :artist, :album, :title, :length,
                :date

    def initialize(filename, extension)
      @path = filename
      ext = File.extname(@path)
      @extension = extension || (ext && ext[1..].downcase)
      @musicbrainz_infos = {}
      @tracknum = nil
      @artist = nil
      @album = nil
      @title = nil
      # @date = nil

      parse(filename)

      @tracknum = nil if @tracknum&.zero?
      @needs_commit = false
      @musicbrainz_infos.delete_if { |_k, v| v.nil? }

      @hash = {
        'artist'   => @artist,
        'album'    => @album,
        'title'    => @title,
        'tracknum' => @tracknum,
        'date'     => @date,
        'length'   => @length,
        'bitrate'  => @bitrate
      }
    end

    def mb_tagged?
      !@musicbrainz_infos.empty?
    end

    # convert tags to hash
    def to_h
      @hash
    end

    def title=(new_title)
      return if @title == new_title

      @needs_commit = true
      @title = new_title
    end

    def artist=(new_artist)
      return if @artist == new_artist

      @needs_commit = true
      @artist = new_artist
    end

    def album=(new_album)
      return if @album == new_album

      @needs_commit = true
      @album = new_album
    end

    def tracknum=(tracknum_s)
      new_tracknum = tracknum_s.to_i
      return if @tracknum == new_tracknum

      @needs_commit = true
      @tracknum = new_tracknum
    end

    def picture=(filepath)
      return if @picture == filepath

      @needs_commit = true
      @picture = filepath
    end

    # hash-like access to tag
    def [](key)
      @hash[key]
    end

    def close
      return unless @needs_commit

      have_ffmpeg = system('which ffmpeg > /dev/null')

      raise(AudioInfoError, "ffmpeg is required to write this file type and wasn't found") unless have_ffmpeg

      tags = { 'artist' => @artist,
               'album' => @album,
               'title' => @title }.inject([]) do |t, (key, value)|
        t + ['-metadata', "#{key}=#{value}"]
      end

      tag_with_shell_command('ffmpeg', '-y', '-i', :src, '-loglevel', 'quiet', tags, :dst)

      @needs_commit
    end

    protected

    def default_tag_fill(tags = @info.tag)
      %w[artist album title].each do |v|
        instance_variable_set("@#{v}".to_sym, sanitize(tags[v] || ''))
      end
    end

    def default_fill_musicbrainz_fields(tags = @info.tag)
      MUSICBRAINZ_FIELDS.each_key do |field|
        val = tags["musicbrainz_#{field}"]
        @musicbrainz_infos[field] = val if val
      end
    end

    def sanitize(input)
      s = input.is_a?(Array) ? input.first : input
      s.delete("\000")
    end

    def tag_with_shell_command(*command_arr)
      expand_command = proc do |hash|
        command_arr.collect do |token|
          token.is_a?(Symbol) ? hash[token] : token
        end.flatten
      end

      hash = { src: @path }
      if command_arr.include?(:dst)
        Tempfile.open(['ruby-audioinfo', ".#{@extension}"]) do |tf|
          cmd = expand_command.call(hash.merge(dst: tf.path))
          tf.close

          raise(AudioInfoError, "error while running #{command_arr[0]}") unless system(*cmd)

          FileUtils.mv(tf.path, @path)
        end
      else
        cmd = expand_command.call(hash)
        system(*cmd) || raise(AudioInfoError, "error while running #{command_arr[0]}")
      end
    end
  end
end

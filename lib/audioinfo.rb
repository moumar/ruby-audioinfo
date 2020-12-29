# frozen_string_literal: true

require 'stringio'

require 'mp3info'
require 'ogginfo'
require 'wmainfo'
require 'mp4info'
require 'flacinfo'
require 'apetag'
require 'wavefile'

$LOAD_PATH << __dir__

require 'audioinfo/mpcinfo'
require 'audioinfo/case_insensitive_hash'
require 'audioinfo/version'

class AudioInfoError < StandardError; end

class AudioInfo
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

  SUPPORTED_EXTENSIONS = %w(mp3 ogg opus spx mpc wma mp4 aac m4a flac wav).freeze

  attr_reader :path, :extension, :musicbrainz_infos, :tracknum, :bitrate, :vbr, :artist, :album, :title, :length, :date

  # Part of testing API - you should not use this directly
  attr_reader :info

  # "block version" of #new()
  def self.open(*args)
    audio_info = new(*args)
    ret = nil
    if block_given?
      begin
        ret = yield(audio_info)
      ensure
        audio_info.close
      end
    else
      ret = audio_info
    end
    ret
  end

  # test whether +path+ is a valid and supported audiofile
  def self.is_audio_file?(path)
    AudioInfo.new(path)
    return true
  rescue AudioInfoError
    return false
  end

  # open the file with path +fn+
  def initialize(filename, extension = nil)
    raise(AudioInfoError, 'path is nil') if filename.nil?

    @path = filename
    ext = File.extname(@path)
    @extension = extension || (ext && ext[1..-1].downcase)
    raise(AudioInfoError, 'cannot find extension') if @extension.empty?

    @musicbrainz_infos = {}

    begin
      case @extension
      when 'mp3'
        @info = Mp3Info.new(filename)
        default_tag_fill
        # "TXXX"=>
        # ["MusicBrainz TRM Id\000",
        # "MusicBrainz Artist Id\000aba64937-3334-4c65-90a1-4e6b9d4d7ada",
        # "MusicBrainz Album Id\000e1a223c1-cbc2-427f-a192-5d22fefd7c4c",
        # "MusicBrainz Album Type\000album",
        # "MusicBrainz Album Status\000official",
        # "MusicBrainz Album Artist Id\000"]

        if (arr = @info.tag2['TXXX']).is_a?(Array)
          fields = MUSICBRAINZ_FIELDS.invert
          arr.each do |val|
            if val =~ /^MusicBrainz (.+)\000(.*)$/
              short_name = fields[Regexp.last_match(1)]
              @musicbrainz_infos[short_name] = Regexp.last_match(2).gsub("\xEF\xBB\xBF".force_encoding('UTF-8'), '')
            end
          end
        end
        @bitrate = @info.bitrate
        i = @info.tag.tracknum
        @tracknum = (i.is_a?(Array) ? i.last : i).to_i
        @length = @info.length.to_i
        @date = @info.tag['date']
        @vbr = @info.vbr
        @info.close

      when 'ogg', 'opus', 'spx'
        @info = OggInfo.new(filename)
        default_fill_musicbrainz_fields
        default_tag_fill
        @bitrate = @info.bitrate / 1000
        @tracknum = @info.tag.tracknumber.to_i
        @length = @info.length.to_i
        @date = @info.tag['date']
        @vbr = true
        @info.close

      when 'mpc'
        fill_ape_tag(filename)
        mpc_info = MpcInfo.new(filename)
        @bitrate = mpc_info.infos['bitrate'] / 1000
        @length = mpc_info.infos['length']

      when 'ape'
        fill_ape_tag(filename)

      when 'wma'
        @info = WmaInfo.new(filename, encoding: 'utf-8')
        @artist = @info.tags['Author']
        @album = @info.tags['AlbumTitle']
        @title = @info.tags['Title']
        @tracknum = @info.tags['TrackNumber'].to_i
        @date = @info.tags['Year']
        @bitrate = @info.info['bitrate']
        @length = @info.info['playtime_seconds']
        MUSICBRAINZ_FIELDS.each do |key, original_key|
          @musicbrainz_infos[key] =
            @info.info['MusicBrainz/' + original_key.tr(' ', '')] ||
            @info.info['MusicBrainz/' + original_key]
        end

      when 'mp4', 'aac', 'm4a'
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

        faad_info(filename).match(/^MusicBrainz (.+)$/) do
          name, value = Regexp.last_match(1).split(/: /, 2)
          key = mapping[name]
          @musicbrainz_infos[key] = value
        end

      when 'flac'
        @info = FlacInfo.new(filename)
        # Unfortunately, FlacInfo doesn't allow us to fiddle inside
        # their class, so we have to brute force it. Any other
        # solution (e.g. creating another abstraction or getting
        # methods) lands up being more messy and brittle.
        @info.instance_variable_set('@tags', CaseInsensitiveHash.new(@info.tags))

        get_tag = proc do |name|
          if t = @info.tags[name]
            t.dup.force_encoding('utf-8')
          end
        end

        @artist = get_tag.call('artist')
        @album = get_tag.call('album')
        @title = get_tag.call('title')
        @tracknum = @info.tags['tracknumber'].to_i
        @date = get_tag.call('date')
        @bitrate = 0
        @length = @info.streaminfo['total_samples'] / @info.streaminfo['samplerate'].to_f
        @bitrate = File.size(filename).to_f * 8 / @length / 1024 if @length > 0
        @info.tags.each do |tagname, _tagvalue|
          next unless tagname =~ /^musicbrainz_(.+)$/

          @musicbrainz_infos[Regexp.last_match(1)] = get_tag.call(tagname)
        end
        @musicbrainz_infos['trmid'] = @info.tags['musicip_puid']
      # default_fill_musicbrainz_fields

      when 'wav'
        @info = WaveFile::Reader.info(filename)
        @length = @info.duration.hours * 3600 + @info.duration.minutes * 60 + @info.duration.seconds + @info.duration.milliseconds * 0.001
        @bitrate = File.size(filename) * 8 / @length / 1024

      else
        raise(AudioInfoError, "unsupported extension '.#{@extension}'")
      end

      @tracknum = nil if @tracknum == 0

      @musicbrainz_infos.delete_if { |_k, v| v.nil? }
      @hash = { 'artist' => @artist,
                'album' => @album,
                'title' => @title,
                'tracknum' => @tracknum,
                'date' => @date,
                'length' => @length,
                'bitrate' => @bitrate }
    rescue StandardError, Mp3InfoError, OggInfoError, ApeTagError => e
      raise AudioInfoError, e.to_s, e.backtrace
    end

    @needs_commit = false
  end

  # set the title of the file
  def title=(v)
    if @title != v
      @needs_commit = true
      @title = v
    end
  end

  # set the artist of the file
  def artist=(v)
    if @artist != v
      @needs_commit = true
      @artist = v
    end
  end

  # set the album of the file
  def album=(v)
    if @album != v
      @needs_commit = true
      @album = v
    end
  end

  # set the track number of the file
  def tracknum=(v)
    v = v.to_i
    if @tracknum != v
      @needs_commit = true
      @tracknum = v
    end
  end

  def picture=(filepath)
    if @picture != filepath
      @needs_commit = true
      @picture = filepath
    end
  end

  # hash-like access to tag
  def [](key)
    @hash[key]
  end

  # convert tags to hash
  def to_h
    @hash
  end

  # close the file and commits changes to disk
  def close
    if @needs_commit
      case @info
      when Mp3Info
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
      when OggInfo
        OggInfo.open(@path) do |ogg|
          { 'artist' => @artist,
            'album' => @album,
            'title' => @title,
            'tracknumber' => @tracknum }.each do |k, v|
            ogg.tag[k] = v.to_s
          end
          ogg.picture = @picture if @picture
        end

      when ApeTag
        ape = ApeTag.new(@path)
        ape.update do |fields|
          fields['Artist'] = @artist
          fields['Album'] = @album
          fields['Title'] = @title
          fields['Track'] = @tracknum.to_s
        end
      else
        have_metaflac = system('which metaflac > /dev/null')
        have_ffmpeg = system('which ffmpeg > /dev/null')
        if have_metaflac && @info.is_a?(FlacInfo)
          tags = { 'ARTIST' => @artist,
                   'ALBUM' => @album,
                   'TITLE' => @title,
                   'TRACKNUMBER' => @tracknum }.inject([]) do |tags, (key, value)|
            tags + ['--set-tag', "#{key}=#{value}"]
          end
          tag_with_shell_command('metaflac', '--remove-all', :src)
          tag_with_shell_command('metaflac', tags, :src)
        elsif have_ffmpeg
          tags = { 'artist' => @artist,
                   'album' => @album,
                   'title' => @title }.inject([]) do |tags, (key, value)|
            tags + ['-metadata', "#{key}=#{value}"]
          end
          tag_with_shell_command('ffmpeg', '-y', '-i', :src, '-loglevel', 'quiet', tags, :dst)
        else
          raise(AudioInfoError, 'implement me')
        end
      end
    end
    @needs_commit
  end
  #    {"musicbrainz_albumstatus"=>"official",
  #     "artist"=>"Jill Scott",
  #     "replaygain_track_gain"=>"-3.29 dB",
  #     "tracknumber"=>"1",
  #     "title"=>"A long walk (A touch of Jazz Mix)..Jazzanova Love Beats...",
  #     "musicbrainz_sortname"=>"Scott, Jill",
  #     "musicbrainz_artistid"=>"b1fb6a18-1626-4011-80fb-eaf83dfebcb6",
  #     "musicbrainz_albumid"=>"cb2ad8c7-4a02-4e46-ae9a-c7c2463c7235",
  #     "replaygain_track_peak"=>"0.82040048",
  #     "musicbrainz_albumtype"=>"compilation",
  #     "album"=>"...Mixing (Jazzanova)",
  #     "musicbrainz_trmid"=>"1ecec0a6-c7c3-4179-abea-ef12dabc7cbd",
  #     "musicbrainz_trackid"=>"0a368e63-dddf-441f-849c-ca23f9cb2d49",
  #     "musicbrainz_albumartistid"=>"89ad4ac3-39f7-470e-963a-56509c546377"}>

  # check if the file is correctly tagged by MusicBrainz
  def mb_tagged?
    !@musicbrainz_infos.empty?
  end

  private

  def sanitize(input)
    s = input.is_a?(Array) ? input.first : input
    s.delete("\000")
  end

  def default_fill_musicbrainz_fields(tags = @info.tag)
    MUSICBRAINZ_FIELDS.each_key do |field|
      val = tags["musicbrainz_#{field}"]
      @musicbrainz_infos[field] = val if val
    end
  end

  def default_tag_fill(tags = @info.tag)
    %w(artist album title).each do |v|
      instance_variable_set("@#{v}".to_sym, sanitize(tags[v] || ''))
    end
  end

  def fill_ape_tag(filename)
    @info = ApeTag.new(filename)
    tags = @info.fields.each_with_object({}) do |(k, v), hash|
      hash[k.downcase] = v ? v.first : nil
    end
    default_fill_musicbrainz_fields(tags)
    default_tag_fill(tags)

    @date = tags['year']
    @tracknum = tags['track'].to_i
  rescue ApeTagError
  end

  def faad_info(file)
    stdout, stdout_w = IO.pipe
    stderr, stderr_w = IO.pipe

    fork do
      stdout.close
      stderr.close
      $stdout.reopen(stdout_w)
      $stderr.reopen(stderr_w)
      exec 'faad', '-i', file
    end

    stdout_w.close
    stderr_w.close
    pid, status = Process.wait2

    out = stdout.read.chomp
    stdout.close
    err = stderr.read.chomp
    stderr.close

    # Return the stderr because faad prints info on that fd...
    status.exitstatus.zero? ? err : ''
  end

  def shell_escape(s)
    "'" + s.gsub(/'/) { "'\\''" } + "'"
  end

  def tag_with_shell_command(*command_arr)
    expand_command = proc do |hash|
      command_arr.collect do |token|
        token.is_a?(Symbol) ? hash[token] : token
      end.flatten
    end

    hash = { src: @path }
    if command_arr.include?(:dst)
      Tempfile.open(['ruby-audioinfo', '.' + @extension]) do |tf|
        cmd = expand_command.call(hash.merge(dst: tf.path))
        tf.close
        if system(*cmd)
          FileUtils.mv(tf.path, @path)
        else
          raise(AudioInfoError, "error while running #{command_arr[0]}")
        end
      end
    else
      cmd = expand_command.call(hash)
      system(*cmd) || raise(AudioInfoError, "error while running #{command_arr[0]}")
    end
  end
end

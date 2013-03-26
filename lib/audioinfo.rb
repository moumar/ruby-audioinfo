# encoding: utf-8
require "stringio"

require "mp3info"
require "ogginfo"
require "wmainfo"
require "mp4info"
require "flacinfo"
require "apetag"

$: << File.expand_path(File.dirname(__FILE__))

require "audioinfo/mpcinfo"
require "audioinfo/case_insensitive_hash"

class AudioInfoError < StandardError ; end

class AudioInfo
  if RUBY_VERSION[0..2] == "1.8"
    RUBY_1_8 = true
    require "iconv"
  else
    RUBY_1_8 = false
  end

  MUSICBRAINZ_FIELDS = { 
    "trmid" 	=> "TRM Id",
    "artistid" 	=> "Artist Id",
    "albumid" 	=> "Album Id",
    "albumtype"	=> "Album Type", 
    "albumstatus" => "Album Status",
    "albumartistid" => "Album Artist Id",
    "sortname" => "Sort Name",
    "trackid" => "Track Id"
  }

  SUPPORTED_EXTENSIONS = %w{mp3 ogg mpc wma mp4 aac m4a flac}

  VERSION = "0.2.3"

  attr_reader :path, :extension, :musicbrainz_infos, :tracknum, :bitrate, :vbr
  attr_reader :artist, :album, :title, :length, :date

  # Part of testing API - you should not use this directly
  attr_reader :info
  
  # "block version" of #new()
  def self.open(*args)
    audio_info = self.new(*args)
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
    begin
      AudioInfo.new(path)
      return true
    rescue  AudioInfoError
      return false
    end
  end

  # open the file with path +fn+
  def initialize(filename)
    raise(AudioInfoError, "path is nil") if filename.nil?
    @path = filename
    ext = File.extname(@path)
    raise(AudioInfoError, "cannot find extension") if ext.empty?
    @extension = ext[1..-1].downcase
    @musicbrainz_infos = {}

    begin
      case @extension
	when 'mp3'
	  @info = Mp3Info.new(filename)
	  default_tag_fill
	  #"TXXX"=>
	  #["MusicBrainz TRM Id\000",
	  #"MusicBrainz Artist Id\000aba64937-3334-4c65-90a1-4e6b9d4d7ada",
	  #"MusicBrainz Album Id\000e1a223c1-cbc2-427f-a192-5d22fefd7c4c",
	  #"MusicBrainz Album Type\000album",
	  #"MusicBrainz Album Status\000official",
	  #"MusicBrainz Album Artist Id\000"]
          
	  if (arr = @info.tag2["TXXX"]).is_a?(Array)
	    fields = MUSICBRAINZ_FIELDS.invert
	    arr.each do |val|
	      if val =~ /^MusicBrainz (.+)\000(.*)$/
		short_name = fields[$1]
	        @musicbrainz_infos[short_name] = $2.gsub("\xEF\xBB\xBF".force_encoding("UTF-8"), '')
	      end
	    end
	  end
          @bitrate = @info.bitrate
	  i = @info.tag.tracknum
	  @tracknum = (i.is_a?(Array) ? i.last : i).to_i
	  @length = @info.length.to_i
	  @date = @info.tag["date"]
	  @vbr = @info.vbr
	  @info.close

	when 'ogg'
	  @info = OggInfo.new(filename)
	  default_fill_musicbrainz_fields
	  default_tag_fill
          @bitrate = @info.bitrate/1000
          @tracknum = @info.tag.tracknumber.to_i
	  @length = @info.length.to_i
	  @date = @info.tag["date"]
	  @vbr = true
	  @info.close
	  
	when 'mpc'
          fill_ape_tag(filename)

	  mpc_info = MpcInfo.new(filename)
          @bitrate = mpc_info.infos['bitrate']/1000
	  @length = mpc_info.infos['length']

        when 'ape'
	  fill_ape_tag(filename)

        when 'wma'
	  @info = WmaInfo.new(filename, :encoding => 'utf-8')
	  @artist = @info.tags["Author"]
	  @album = @info.tags["AlbumTitle"]
	  @title = @info.tags["Title"]
	  @tracknum = @info.tags["TrackNumber"].to_i
	  @date = @info.tags["Year"]
	  @bitrate = @info.info["bitrate"]
	  @length = @info.info["playtime_seconds"]
	  MUSICBRAINZ_FIELDS.each do |key, original_key|
	    @musicbrainz_infos[key] = 
              @info.info["MusicBrainz/" + original_key.tr(" ", "")] ||
              @info.info["MusicBrainz/" + original_key]
	  end
          
	when 'mp4', 'aac', 'm4a'
          @extension = 'mp4'
	  @info = MP4Info.open(filename)
	  @artist = @info.ART
	  @album = @info.ALB
	  @title = @info.NAM
	  @tracknum = ( t = @info.TRKN ) ? t.first : 0
	  @date = @info.DAY
	  @bitrate = @info.BITRATE
	  @length = @info.SECS
	  mapping = MUSICBRAINZ_FIELDS.invert

	  faad_info(filename).match(/^MusicBrainz (.+)$/) do
	    name, value = $1.split(/: /, 2)
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

	  @artist = @info.tags["artist"]
	  @album = @info.tags["album"]
	  @title = @info.tags["title"]
	  @tracknum = @info.tags["tracknumber"].to_i
	  @date = @info.tags["data"]
	  @length = @info.streaminfo["total_samples"] / @info.streaminfo["samplerate"].to_f
	  @bitrate = File.size(filename).to_f*8/@length/1024
          @info.tags.each do |tagname, tagvalue|
            next unless tagname =~ /^musicbrainz_(.+)$/
            @musicbrainz_infos[$1] = @info.tags[tagname]
          end
          @musicbrainz_infos["trmid"] = @info.tags["musicip_puid"]
	  #default_fill_musicbrainz_fields

	else
	  raise(AudioInfoError, "unsupported extension '.#{@extension}'")
      end

      if @tracknum == 0
        @tracknum = nil
      end

      @musicbrainz_infos.delete_if { |k, v| v.nil? }
      @hash = { "artist" => @artist,
	"album"  => @album,
	"title"  => @title,
	"tracknum" => @tracknum,
	"date" => @date,
	"length" => @length,
	"bitrate" => @bitrate,
      }

    rescue Exception, Mp3InfoError, OggInfoError, ApeTagError => e
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
	  end
	when OggInfo
	  OggInfo.open(@path) do |ogg|
            { "artist" => @artist,
	      "album"  => @album,
	      "title"  => @title,
              "tracknumber" => @tracknum}.each do |k,v|
	      ogg.tag[k] = v.to_s
	    end
	  end

        when ApeTag
          ape = ApeTag.new(@path)
          ape.update do |fields|
            fields["Artist"] = @artist
            fields["Album"] = @album
            fields["Title"] = @title
            fields["Track"] = @tracknum.to_s
          end
	else
          have_metaflac = system("which metaflac > /dev/null")
          have_ffmpeg = system("which ffmpeg > /dev/null")
          if have_metaflac and @info.is_a?(FlacInfo)
            tags = {"ARTIST" => @artist, 
                    "ALBUM" => @album, 
                    "TITLE" => @title, 
                    "TRACKNUMBER" => @tracknum}.inject([]) do |tags, (key, value)|
              tags + ["--set-tag", "#{key}=#{value.to_s}"]
            end
            tag_with_shell_command("metaflac", "--remove-all", :src)
            tag_with_shell_command("metaflac", tags, :src)
          elsif have_ffmpeg
            tags = {"artist" => @artist, 
                    "album" => @album, 
                    "title" => @title, 
                    "track" => @tracknum}.inject("") do |tags, (key, value)|
              tags + ["-metadata", "#{key}=#{value.to_s}"]
            end
            tag_with_shell_command("ffmpeg", "-i", :src, "-loglevel", "quiet", tags, :dst)
          else
	    raise(AudioInfoError, "implement me")
          end
      end
      
    end
    @needs_commit
  end
=begin
   {"musicbrainz_albumstatus"=>"official",
    "artist"=>"Jill Scott",
    "replaygain_track_gain"=>"-3.29 dB",
    "tracknumber"=>"1",
    "title"=>"A long walk (A touch of Jazz Mix)..Jazzanova Love Beats...",
    "musicbrainz_sortname"=>"Scott, Jill",
    "musicbrainz_artistid"=>"b1fb6a18-1626-4011-80fb-eaf83dfebcb6",
    "musicbrainz_albumid"=>"cb2ad8c7-4a02-4e46-ae9a-c7c2463c7235",
    "replaygain_track_peak"=>"0.82040048",
    "musicbrainz_albumtype"=>"compilation",
    "album"=>"...Mixing (Jazzanova)",
    "musicbrainz_trmid"=>"1ecec0a6-c7c3-4179-abea-ef12dabc7cbd",
    "musicbrainz_trackid"=>"0a368e63-dddf-441f-849c-ca23f9cb2d49",
    "musicbrainz_albumartistid"=>"89ad4ac3-39f7-470e-963a-56509c546377"}>
=end

  # check if the file is correctly tagged by MusicBrainz
  def mb_tagged?
    ! @musicbrainz_infos.empty?
  end

  private 

  def sanitize(input)
    s = input.is_a?(Array) ? input.first : input
    s.gsub("\000", "")
  end

  def default_fill_musicbrainz_fields(tags = @info.tag)
    MUSICBRAINZ_FIELDS.keys.each do |field|
      val = tags["musicbrainz_#{field}"]
      @musicbrainz_infos[field] = val if val
    end
  end

  def default_tag_fill(tags = @info.tag)
    %w{artist album title}.each do |v|
      instance_variable_set( "@#{v}".to_sym, sanitize(tags[v]||"") )
    end
  end

  def fill_ape_tag(filename)
    begin
      @info = ApeTag.new(filename)
      tags = @info.fields.inject({}) do |hash, (k, v)|
        hash[k.downcase] = v ? v.first : nil
        hash
      end
      default_fill_musicbrainz_fields(tags)
      default_tag_fill(tags)

      @date = tags["year"]
      @tracknum = tags['track'].to_i
    rescue ApeTagError
    end
  end

  def faad_info(file)
    stdout, stdout_w = IO.pipe
    stderr, stderr_w = IO.pipe

    fork do
      stdout.close
      stderr.close
      STDOUT.reopen(stdout_w)
      STDERR.reopen(stderr_w)
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

    hash = {:src => @path}
    if command_arr.include?(:dst)
      Tempfile.open(["ruby-audioinfo", "."+@extension]) do |tf|
        cmd = expand_command.call(hash.merge(:dst => tf.path))
        tf.close
        if system(*cmd)
          FileUtils.mv(tf.path, @path)
        else
          raise(AudioInfoError, "error while running #{command_arr[0]}")
        end
      end
    else
      cmd = expand_command.call(hash)
      p cmd
      system(*cmd) || raise(AudioInfoError, "error while running #{command_arr[0]}")
    end
  end
end

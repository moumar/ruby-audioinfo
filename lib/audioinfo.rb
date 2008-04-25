#!/usr/bin/env ruby

require "iconv"
require "stringio"

$: << File.dirname(__FILE__)+"/audioinfo"

require "mp3info"
require "ogginfo"
require "mpcinfo"
require "apetag"
require "wmainfo"
require "mp4info"
require "flacinfo"
require "shell_escape"

class AudioInfoError < Exception ; end

class AudioInfo
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

  VERSION = "0.1.2"

  attr_reader :path, :extension, :musicbrainz_infos, :tracknum, :bitrate, :vbr
  attr_reader :artist, :album, :title, :length, :date
  
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

  # open the file with path +fn+ and convert all tags from/to specified +encoding+
  def initialize(fn, encoding = 'utf-8')
    raise(AudioInfoError, "path is nil") if fn.nil?
    @path = fn
    ext = File.extname(@path)
    raise(AudioInfoError, "cannot find extension") if ext.empty?
    @extension = ext[1..-1].downcase
    @musicbrainz_infos = {}
    @encoding = encoding

    begin
      case @extension
	when 'mp3'
	  @info = Mp3Info.new(fn, :encoding => @encoding)
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
	        @musicbrainz_infos[short_name] = $2
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
	  @info = OggInfo.new(fn, @encoding)
	  default_fill_musicbrainz_fields
	  default_tag_fill
          @bitrate = @info.bitrate/1000
          @tracknum = @info.tag.tracknumber.to_i
	  @length = @info.length.to_i
	  @date = @info.tag["date"]
	  @vbr = true
	  @info.close
	  
	when 'mpc'
	  fill_ape_tag(fn)
	  
	  mpc_info = MpcInfo.new(fn)
          @bitrate = mpc_info.infos['bitrate']/1000
	  @length = mpc_info.infos['length']

        when 'ape'
	  fill_ape_tag(fn)

        when 'wma'
	  @info = WmaInfo.new(fn, :encoding => @encoding)
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
          
	when 'aac', 'mp4', 'm4a'
	  @info = MP4Info.open(fn)
	  @artist = @info.ART
	  @album = @info.ALB
	  @title = @info.NAM
	  @tracknum = ( t = @info.TRKN ) ? t.first : 0
	  @date = @info.DAY
	  @bitrate = @info.BITRATE
	  @length = @info.SECS
	  mapping = MUSICBRAINZ_FIELDS.invert

	  `faad -i #{fn.shell_escape} 2>&1 `.grep(/^MusicBrainz (.+)$/) do
	    name, value = $1.split(/: /, 2)
	    key = mapping[name]
	    @musicbrainz_infos[key] = value
	  end
	
	when 'flac'
	  @info = FlacInfo.new(fn)
          tags = convert_tags_encoding(@info.tags, "UTF-8")
	  @artist = tags["ARTIST"]
	  @album = tags["ALBUM"]
	  @title = tags["TITLE"]
	  @tracknum = tags["TRACKNUMBER"].to_i
	  @date = tags["DATE"]
	  @length = @info.streaminfo["total_samples"] / @info.streaminfo["samplerate"].to_f
	  @bitrate = File.size(fn).to_f*8/@length/1024
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
    @needs_commit = true
    @title = v
  end

  # set the artist of the file
  def artist=(v)
    @needs_commit = true
    @artist = v
  end

  # set the album of the file
  def album=(v)
    @needs_commit = true
    @album = v
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
	  end
	when OggInfo
	  OggInfo.open(@path) do |ogg|
            { "artist" => @artist,
	      "album"  => @album,
	      "title"  => @title }.each do |k,v|
	      ogg.tag[k] = v
	    end
	  end

	else
	  raise(AudioInfoError, "implement me")
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

  def default_fill_musicbrainz_fields
    MUSICBRAINZ_FIELDS.keys.each do |field|
      val = @info.tag["musicbrainz_#{field}"]
      @musicbrainz_infos[field] = val if val
    end
  end

  def default_tag_fill(tag = @info.tag)
    %w{artist album title}.each do |v|
      instance_variable_set( "@#{v}".to_sym, sanitize(tag[v].to_s) )
    end
  end

  def fill_ape_tag(fn)
    begin
      @info = ApeTag.new(fn)
      tags = convert_tags_encoding(@info.tag, "UTF-8")
      default_tag_fill(tags)
      default_fill_musicbrainz_fields
      @date = @info.tag["year"]
      @tracknum = 0

      if track = @info.tag['track']
        @tracknum = @info.tag['track'].split("/").first.to_i
      end
    rescue ApeTagError
    end
  end

  def convert_tags_encoding(tags_orig, from_encoding)
    tags = {}
    Iconv.open(@encoding, from_encoding) do |ic|
      tags_orig.inject(tags) do |hash, (k, v)| 
        if v.is_a?(String)
          hash[ic.iconv(k)] = ic.iconv(v)
        end
        hash
      end
    end
    tags
  end
end

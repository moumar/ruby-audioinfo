# frozen_string_literal: true

require 'audioinfo'

module AudioInfo
  class Album
    IMAGE_EXTENSIONS = %w[jpg jpeg gif png].freeze

    # a regexp to match the "multicd" suffix of a "multicd" string
    # example: "toto (disc 1)" will match ' (disc 1)'
    MULTICD_REGEXP = /\s*(\(|\[)?\s*(disc|cd):?-?\s*(\d+).*(\)|\])?\s*$/i.freeze

    attr_reader :files, :discnum, :multicd, :basename, :infos, :path

    # return the list of images in the album directory, with "folder.*" in first
    def self.images(path)
      path = path.dup.force_encoding('binary')
      arr = Dir.glob(File.join(path, "*.{#{IMAGE_EXTENSIONS.join(',')}}"), File::FNM_CASEFOLD).collect do |f|
        File.expand_path(f)
      end
      # move "folder.*" image on top of the array
      if folder = arr.detect { |f| f =~ /folder\.[^.]+$/ }
        arr.delete(folder)
        arr.unshift(folder)
      end
      arr
    end

    # strip the "multicd" string from the given +name+
    def self.basename(name)
      name.sub(MULTICD_REGEXP, '')
    end

    # return the number of the disc in the box or 0
    def self.discnum(name)
      if name =~ MULTICD_REGEXP
        Regexp.last_match(3).to_i
      else
        0
      end
    end

    # open the Album with +path+. +fast_lookup+ will only check
    # first and last file of the directory
    def initialize(path, fast_lookup = false)
      @path = path
      @multicd = false
      @basename = @path
      exts = AudioInfo::SUPPORTED_EXTENSIONS.collect do |ext|
        ext.gsub(/[a-z]/) { |c| "[#{c.downcase}#{c.upcase}]" }
      end.join(',')

      # need to escape the glob path
      glob_escaped_path = @path.gsub(/([{}?*\[\]])/) { |s| '\\' << s }

      glob_val = File.join(glob_escaped_path, "*.{#{exts}}")
      file_names = Dir.glob(glob_val).sort

      file_names = [file_names.first, file_names.last] if fast_lookup

      @files = file_names.collect do |f|
        AudioInfo.new(f)
      end

      @infos = {}
      @infos['album'] = @files.collect(&:album).uniq
      @infos['album'] = @infos['album'].first if @infos['album'].size == 1
      artists = @files.collect(&:artist).uniq
      @infos['artist'] = artists.size > 1 ? 'various' : artists.first
      @discnum = self.class.discnum(@infos['album'])

      unless @discnum.zero?
        @multicd = true
        @basename = self.class.basename(@infos['album'])
      end
    end

    # is the album empty?
    def empty?
      @files.empty?
    end

    # are all the files of the album MusicBrainz tagged ?
    def mb_tagged?
      return false if @files.empty?

      mb = true
      @files.each do |f|
        mb &&= f.mb_tagged?
      end
      mb
    end

    # return an array of images with "folder.*" in first
    def images
      self.class.images(@path)
    end

    # title of the album
    def title
      # count the occurences of the title and take the one who has most
      hash_counted = files.collect(&:album).each_with_object(Hash.new(0)) { |album, hash| hash[album] += 1; }
      if hash_counted.empty?
        nil
      else
        hash_counted.max_by { |_k, v| v }[0]
      end
    end

    # mbid (MusicBrainz ID) of the album
    def mbid
      return nil unless mb_tagged?

      @files.collect { |f| f.musicbrainz_infos['albumid'] }.uniq.first
    end

    # is the album multi-artist?
    def va?
      @files.collect(&:artist).uniq.size > 1
    end

    # pretty print
    def to_s
      out = StringIO.new
      out.puts(@path)
      out.print "'#{title}'"

      out.print " by '#{@files.first.artist}' " unless va?

      out.puts

      @files.sort_by(&:tracknum).each do |f|
        out.printf('%02d %s %3d %s', f.tracknum, f.extension, f.bitrate, f.title)
        out.print(" #{f.artist}") if va?
        out.puts
      end

      out.string
    end

    def inspect
      @infos.inspect
    end
  end
end

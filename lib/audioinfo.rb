# frozen_string_literal: true

require 'stringio'

require 'audioinfo/audio_file'
require 'audioinfo/mp3'
require 'audioinfo/mpcinfo'
require 'audioinfo/ogg'
require 'audioinfo/version'
require 'audioinfo/wma'
require 'audioinfo/wav'
require 'audioinfo/mp4'
require 'audioinfo/flac'

class AudioInfoError < StandardError; end

module AudioInfo
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
    true
  rescue AudioInfoError
    false
  end

  # open the file with path +fn+
  def self.new(filename, extension = nil)
    raise(AudioInfoError, 'path is nil') if filename.nil?

    ext = File.extname(filename)

    extension ||= (ext && ext[1..].downcase)

    raise(AudioInfoError, 'cannot find extension') if extension.empty?

    klass =
      case extension
      when 'mp3' then Mp3
      when 'ogg', 'opus', 'spx' then Ogg
      when 'mpc' then Mpc
      when 'ape' then Ape
      when 'wma' then Wma
      when 'mp4', 'aac', 'm4a' then Mp4
      when 'flac' then Flac
      when 'wav' then Wav
      else
        raise(AudioInfoError, "unsupported extension '.#{@extension}'")
      end

    klass.new(filename, extension)
  end
end

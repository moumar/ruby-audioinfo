#!/usr/bin/env ruby
# frozen_string_literal: true

require 'stringio'
require 'mp3info/id3v2'

class MpcInfoError < StandardError; end

class MpcInfo
  PROFILES_NAMES = [
    'no profile',
    'Experimental',
    'unused',
    'unused',
    'unused',
    'below Telephone (q = 0.0)',
    'below Telephone (q = 1.0)',
    'Telephone (q = 2.0)',
    'Thumb (q = 3.0)',
    'Radio (q = 4.0)',
    'Standard (q = 5.0)',
    'Extreme (q = 6.0)',
    'Insane (q = 7.0)',
    'BrainDead (q = 8.0)',
    'above BrainDead (q = 9.0)',
    'above BrainDead (q = 10.0)'
  ].freeze

  FREQUENCIES = [44_100, 48_000, 37_800, 32_000].freeze

  SV4_6_HEADER = Regexp.new(
    '^[\x00\x01\x10\x11\x40\x41\x50\x51\x80\x81\x90\x91\xC0\xC1\xD0\xD1][\x20-37][\x00\x20\x40\x60\x80\xA0\xC0\xE0]/',
    Regexp::NOENCODING
  )

  attr_reader :infos, :id3v2_tag

  def initialize(filename)
    @file = File.open(filename, 'rb')

    @infos = {}
    @infos['raw'] = {}
    parse_infos
  end

  private

  def parse_infos
    mpc_header = @file.read(3)

    case mpc_header
    when 'MP+'
      # this is SV7+

      header = StringIO.new(@file.read(25))
      header_size = 28
      # stream_version_byte = header.read(4).unpack("V").first
      stream_version_byte = header.read(1)[0].ord # .unpack("c").first

      @infos['stream_major_version'] = (stream_version_byte & 0x0F)
      @infos['stream_minor_version'] = (stream_version_byte & 0xF0) >> 4

      @infos['frame_count']          = read32(header)
      raise(MpcInfoError, 'Only Musepack SV7 supported') if @infos['stream_major_version'] != 7

      flags_dword1 = read32(header)

      @infos['intensity_stereo']       = ((flags_dword1 & 0x80000000) >> 31) == 1
      @infos['mid_side_stereo']        = ((flags_dword1 & 0x40000000) >> 30) == 1
      @infos['max_subband']            = (flags_dword1 & 0x3F000000) >> 24
      @infos['raw']['profile']         = (flags_dword1 & 0x00F00000) >> 20
      @infos['begin_loud']             = ((flags_dword1 & 0x00080000) >> 19) == 1
      @infos['end_loud']               = ((flags_dword1 & 0x00040000) >> 18) == 1
      @infos['raw']['sample_rate']     = (flags_dword1 & 0x00030000) >> 16
      @infos['max_level']              = (flags_dword1 & 0x0000FFFF)

      @infos['raw']['title_peak']      = read16(header)
      @infos['raw']['title_gain']      = read16(header)

      @infos['raw']['album_peak']      = read16(header)
      @infos['raw']['album_gain']      = read16(header)

      flags_dword2 = read32(header)
      @infos['true_gapless']           = ((flags_dword2 & 0x80000000) >> 31) == 1
      @infos['last_frame_length']      = (flags_dword2 & 0x7FF00000) >> 20

      not_sure_what = read32(header, 3)
      @infos['raw']['encoder_version'] = read8(header)

      @infos['profile']     = PROFILES_NAMES[@infos['raw']['profile']] || 'invalid'
      @infos['sample_rate'] = FREQUENCIES[@infos['raw']['sample_rate']]

      raise(MpcInfoError, 'Corrupt MPC file: frequency == zero') if (@infos['sample_rate']).zero?

      sample_rate = @infos['sample_rate']
      channels = 2 # appears to be hardcoded
      @infos['samples'] = (((@infos['frame_count'] - 1) * 1152) + @infos['last_frame_length']) * channels
      @infos['length'] = (((@infos['frame_count'] - 1) * 1152) + @infos['last_frame_length']) * channels

      @infos['length'] = (@infos['samples'] / channels) / @infos['sample_rate'].to_f
      raise(MpcInfoError, 'Corrupt MPC file: playtime_seconds == zero') if (@infos['length']).zero?

      # add size of file header to avdataoffset - calc bitrate correctly + MD5 data
      avdataoffset = header_size

      # FIXME: is $ThisFileInfo['avdataend']  == File.size ????
      @infos['bitrate'] = ((@file.stat.size - avdataoffset) * 8) / @infos['length']

      @infos['title_peak'] = @infos['raw']['title_peak']
      @infos['title_peak_db'] = @infos['title_peak'].zero? ? 0 : peak_db(@infos['title_peak'])
      @infos['title_gain_db'] = if (@infos['raw']['title_gain']).negative?
                                  (32_768 + @infos['raw']['title_gain']) / -100.0
                                else
                                  @infos['raw']['title_gain'] / 100.0
                                end

      @infos['album_peak']        = @infos['raw']['album_peak']
      @infos['album_peak_db']     = @infos['album_peak'].zero? ? 0 : peak_db(@infos['album_peak'])

      @infos['album_gain_db'] = if (@infos['raw']['album_gain']).negative?
                                  (32_768 + @infos['raw']['album_gain']) / -100.0
                                else
                                  @infos['raw']['album_gain'] / 100.0
                                end
      @infos['encoder_version'] = encoder_version(@infos['raw']['encoder_version'])

    #       #FIXME
    #       $ThisFileInfo['replay_gain']['track']['adjustment'] = @infos['title_gain_db'];
    #       $ThisFileInfo['replay_gain']['album']['adjustment'] = @infos['album_gain_db'];
    #       if @infos['title_peak'] > 0
    #         #$ThisFileInfo['replay_gain']['track']['peak'] = @infos['title_peak']
    #       elsif round(@infos['max_level'] * 1.18) > 0)
    #         // why? I don't know - see mppdec.c
    #         # ThisFileInfo['replay_gain']['track']['peak'] = getid3_lib::CastAsInt(round(@infos['max_level'] * 1.18));
    #       end
    #
    #       if @infos['album_peak'] > 0
    # 	      #$ThisFileInfo['replay_gain']['album']['peak'] = @infos['album_peak'];
    #       end
    #
    #       #ThisFileInfo['audio']['encoder'] =
    #       #  'SV'.@infos['stream_major_version'].'.'.@infos['stream_minor_version'].', '.@infos['encoder_version'];
    #       #$ThisFileInfo['audio']['encoder'] = @infos['encoder_version'];
    #       #$ThisFileInfo['audio']['encoder_options'] = @infos['profile'];
    when SV4_6_HEADER
      # this is SV4 - SV6, handle seperately
      header_size = 8
    when 'ID3'
      @id3v2_tag = ID3v2.new
      @id3v2_tag.from_io(@file)
      @file.seek(@id3v2_tag.io_position)
      # very dirty hack to allow parsing of mpc infos after id3v2 tag
      while @file.read(1) != 'M'; end
      if @file.read(2) == 'P+'
        @file.seek(-3, IO::SEEK_CUR)
        # we need to reparse the tag, since we have the beggining of the mpc file
        parse_infos
      else
        raise(MpcInfoError, 'cannot find MPC header after id3 tag')
      end
    else
      raise(MpcInfoError, 'cannot find MPC header')
    end
  end

  def read8(io)
    io.read(1)[0].ord
  end

  def read16(io)
    io.read(2).unpack1('v')
  end

  def read32(io, size = 4)
    io.read(size).unpack1('V')
  end

  def peak_db(i)
    ((Math.log10(i) / Math.log10(2)) - 15) * 6
  end

  def encoder_version(encoderversion)
    # Encoder version * 100  (106 = 1.06)
    # EncoderVersion % 10 == 0        Release (1.0)
    # EncoderVersion %  2 == 0        Beta (1.06)
    # EncoderVersion %  2 == 1        Alpha (1.05a...z)

    if encoderversion.zero?
      # very old version, not known exactly which
      'Buschmann v1.7.0-v1.7.9 or Klemm v0.90-v1.05'
    elsif (encoderversion % 10).zero?
      # release version
      format('%.2f', encoderversion / 100.0)
    elsif encoderversion.even?
      format('%.2f beta', encoderversion / 100.0)
    else
      format('%.2f alpha', encoderversion / 100.0)
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  require 'pp'

  mpcinfo = MpcInfo.new(ARGV[0])
  pp mpcinfo.infos.sort

end

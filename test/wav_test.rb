# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

require_relative 'test_helper'

class TestWav < MiniTest::Test
  WAV_FILE = "#{Dir.tmpdir}/ruby-audioinfo-test.wav"

  def setup
    FileUtils.cp(File.join(SUPPORT_DIR, 'piano2.wav'), WAV_FILE)
    @i = AudioInfo.new(WAV_FILE)
  end

  def test_wav_whitelist
    assert_kind_of WaveFile::Info, @i.info
  end

  def test_wav_length
    assert_in_delta(@i.length, 6.306)
  end
end

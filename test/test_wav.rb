require_relative "../lib/audioinfo"
require "minitest/autorun"

require "fileutils"
require "tmpdir"

require_relative "test_helper"

class TestWav < MiniTest::Unit::TestCase

  WAV_FILE = "#{Dir.tmpdir}/ruby-audioinfo-test.wav" 

  def setup
    FileUtils.cp(File.join(SUPPORT_DIR, "piano2.wav"), WAV_FILE)
  end

  def test_wav_whitelist
    i = AudioInfo.new(WAV_FILE)
    assert_kind_of WaveFile::Info, i.info
  end

  def test_wav_length
    i = AudioInfo.new(WAV_FILE)
    assert_equal i.length, 6
  end

end

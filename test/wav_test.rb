# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

require_relative 'test_helper'

class TestWav < MiniTest::Test
  WAV_FILE = "#{Dir.tmpdir}/ruby-audioinfo-test.wav"

  def setup
    FileUtils.cp(File.join(SUPPORT_DIR, 'cantina_band.wav'), WAV_FILE)
    @i = AudioInfo.new(WAV_FILE)
  end

  def test_default_fields
    assert_equal({ 'length' => 3.0, 'bitrate' => 352.8645833333333 }, @i.to_h.compact)
  end

  def test_musicbrainz
    assert_equal({}, @i.musicbrainz_infos)
  end
end

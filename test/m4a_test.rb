# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

require_relative 'test_helper'

class M4aTest < MiniTest::Test
  M4A_FILE = "#{Dir.tmpdir}/ruby-audioinfo-test.m4a"

  def setup
    FileUtils.cp(File.join(SUPPORT_DIR, 'cantina_band.m4a'), M4A_FILE)
    @i = AudioInfo.new(M4A_FILE)
  end

  def test_default_fields
    assert_equal(
      DEFAULT_INFO.slice("artist", "length", "tracknum").merge("bitrate" => 113),
      @i.to_h.compact
    )
  end

  def test_musicbrainz
    assert_equal(MUSICBRAINZ_INFO, @i.musicbrainz_infos)
  end
end

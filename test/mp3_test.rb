# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

require_relative 'test_helper'

class MP3Test < MiniTest::Test
  MP3_FILE = "#{Dir.tmpdir}/ruby-audioinfo-test.mp3"

  # mp3 loads both artists here while some other formats do not
  ARTIST = "#{MUSICBRAINZ_INFO['artistid']}/4ebf48b9-9b17-43e2-b4aa-7f29b7e608d1"

  def setup
    FileUtils.cp(File.join(SUPPORT_DIR, 'cantina_band.mp3'), MP3_FILE)
    @i = AudioInfo.new(MP3_FILE)
  end

  def test_default_fields
    assert_equal(DEFAULT_INFO.merge('date' => nil, 'length' => 3.056326530612245), @i.to_h)
  end

  def test_musicbrainz
    assert_equal(
      MUSICBRAINZ_INFO.merge('artistid' => ARTIST, 'albumartistid' => ARTIST),
      @i.musicbrainz_infos
    )
  end
end

# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

require_relative 'test_helper'

class WmaTest < MiniTest::Test
  WMA_FILE = "#{Dir.tmpdir}/ruby-audioinfo-test.wma"

  def setup
    FileUtils.cp(File.join(SUPPORT_DIR, 'cantina_band.wma'), WMA_FILE)
    @i = AudioInfo.new(WMA_FILE)
  end

  def test_default_fields
    assert_equal(DEFAULT_INFO.merge('bitrate' => 24, 'length' => 4), @i.to_h)
  end

  def test_musicbrainz
    assert_equal MUSICBRAINZ_INFO.sort, @i.musicbrainz_infos.sort
  end
end

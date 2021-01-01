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

  def test_whitelist
    assert_kind_of MP4Info, @i.info
  end

  def test_length
    assert_in_delta(@i.length, 3)
  end

  def test_musicbrainz
    assert_equal('57c051a1-41db-4764-bfab-ecac5cb3a144', @i.musicbrainz_infos['artistid'])
  end
end

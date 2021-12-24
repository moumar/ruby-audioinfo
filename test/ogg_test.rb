# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

require_relative 'test_helper'

class OggTest < MiniTest::Test
  OGG_FILE = "#{Dir.tmpdir}/ruby-audioinfo-test.ogg"

  def setup
    FileUtils.cp(File.join(SUPPORT_DIR, 'cantina_band.ogg'), OGG_FILE)
    @i = AudioInfo.new(OGG_FILE)
  end

  def test_default_fields
    assert_equal DEFAULT_INFO.merge('bitrate' => 31.557333333333332), @i.to_h
  end
end

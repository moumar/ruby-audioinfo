# frozen_string_literal: true

require_relative '../lib/audioinfo'
require 'minitest/autorun'

require 'fileutils'
require 'tmpdir'

require_relative 'test_helper'

class FlacTest < MiniTest::Test
  FLAC_FILE = "#{Dir.tmpdir}/ruby-audioinfo-test.flac"

  def setup
    FileUtils.cp(File.join(SUPPORT_DIR, 'cantina_band.flac'), FLAC_FILE)
    @i = AudioInfo.new(FLAC_FILE)
  end

  def test_default_fields
    assert_equal(DEFAULT_INFO.merge('length' => 3.0, 'bitrate' => 216.0859375), @i.to_h)
  end

  def test_flac_writing
    title = 'test with utf8éblèàqsf'
    @i.title = title
    @i.close
    ai = AudioInfo.new(FLAC_FILE)
    assert_equal title, ai.title
  end
end

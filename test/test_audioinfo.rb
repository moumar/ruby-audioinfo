require "audioinfo"
require "minitest/autorun"

require_relative "test_helper"

class TestAudioinfo < MiniTest::Unit::TestCase

  def test_flac_whitelist
    flac_file = File.join(SUPPORT_DIR, "440Hz-5sec.flac")
    i = AudioInfo.new(flac_file)
    assert_kind_of FlacInfo, i.info
  end
end

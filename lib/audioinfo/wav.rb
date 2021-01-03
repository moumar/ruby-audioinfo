# frozen_string_literal: true

require 'wavefile'

module AudioInfo
  class Wav < AudioFile
    def parse(filename)
      @info = WaveFile::Reader.info(filename)
      @length = @info.duration.hours * 3600 + @info.duration.minutes * 60 + @info.duration.seconds +
                @info.duration.milliseconds * 0.001
      @bitrate = File.size(filename) * 8 / @length / 1024
    end
  end
end

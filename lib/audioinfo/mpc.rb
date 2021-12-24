# frozen_string_literal: true

require 'apetag'
require 'mpcinfo'

module AudioInfo
  class Mpc < Ape
    def parse(filename)
      super(filename)

      mpc_info = MpcInfo.new(filename)
      @bitrate = mpc_info.infos['bitrate'] / 1000
      @length = mpc_info.infos['length']
    end
  end
end

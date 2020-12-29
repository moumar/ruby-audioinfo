require File.dirname(__FILE__) + "/../lib/audioinfo/mpcinfo"

require "pp"

fn = "file.mpc"
mpc = MpcInfo.new(fn)
pp mpc.id3v2_tag
pp mpc.infos

# see http://www.personal.uni-jena.de/~pfk/mpp/sv8/apetag.html for specs

class ApeTagError < StandardError ; end

class ApeTag
  attr_reader :tag, :version

  def initialize(filename)
    @tag = {}

    begin
      @file = File.new(filename, "rb")
      @file.seek(-32, IO::SEEK_END)

      preamble, version, tagsize, itemcount, flags = 
        @file.read(24).unpack("A8VVVV")
      @version = version/1000

      raise(ApeTagError, "cannot find preamble") if preamble != 'APETAGEX'
      @file.seek(-tagsize, IO::SEEK_END)
      itemcount.times do |i|
        len, flags = @file.read(8).unpack("VV")
	key = ""
	loop do
	  c = @file.getc
	  break if c == 0
	  key << c
	end
	#ugly FIX
	@tag[key.downcase] = @file.read(len) unless len > 100_000
      end
    ensure
      @file.close
    end
  end
end

if $0 == __FILE__
  while filename = ARGV.shift
    puts "Getting info from #{filename}"
    begin
      ape = ApeTag.new(filename)
    rescue ApeTagError
     puts "error: doesn't appear to be an ape tagged file"
    else
      puts ape
      ape.tag.each do |key, value|
        puts "#{key} => #{value}"
      end
    end
    puts
  end
end

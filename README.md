# ruby-audioinfo

Glues together various audio ruby libraries and presents a unified API to the developer.
Currently, supported formats are: mp3, ogg, mpc, ape, wma, flac, aac, mp4, m4a.

Does not depend on any gems with native extensions for portability.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby-audioinfo', require: 'audioinfo'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ruby-audioinfo

## Usage

```
AudioInfo.open("audio_file.one_of_supported_extensions") do |info|
  info.artist   # or info["artist"]
  info.title    # or info["title"]
  info.length   # playing time of the file
  info.bitrate  # average bitrate
  info.to_h     # { "artist" => "artist", "title" => "title", etc... }
end
```

## FEATURES/PROBLEMS:

* beta write support for mp3 and ogg tags (other to be written)
* support for MusicBrainz tags
* AudioInfo::Album class included, which gives an unified way to manage an album in a given directory.

## Dependencies

* [ruby-mp3info](https://github.com/moumar/ruby-mp3info)
* [ruby-ogginfo](https://github.com/moumar/ruby-ogginfo)
* [MP4Info](https://github.com/arbarlow/ruby-mp4info)
* [flacinfo-rb](https://github.com/DarrenKirby/flacinfo-rb)
* [wmainfo-rb](https://github.com/moumar/wmainfo-rb)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/moumar/ruby-audioinfo. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/moumar/ruby-audioinfo/blob/master/CODE_OF_CONDUCT.md).

## License

GPL-3.0

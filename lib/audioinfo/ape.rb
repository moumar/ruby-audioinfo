# frozen_string_literal: true

require 'apetag'

module AudioInfo
  class Ape < AudioFile
    def parse(filename)
      @info = ApeTag.new(filename)

      tags = @info.fields.each_with_object({}) do |(k, v), hash|
        hash[k.downcase] = v ? v.first : nil
      end

      default_fill_musicbrainz_fields(tags)
      default_tag_fill(tags)

      @date = tags['year']
      @tracknum = tags['track'].to_i
    rescue ApeTagError => e
      raise AudioInfoError, e.to_s, e.backtrace
    end

    def close
      return unless @needs_commit

      ape = ApeTag.new(@path)
      ape.update do |fields|
        fields['Artist'] = @artist
        fields['Album'] = @album
        fields['Title'] = @title
        fields['Track'] = @tracknum.to_s
      end

      @needs_commit
    end
  end
end

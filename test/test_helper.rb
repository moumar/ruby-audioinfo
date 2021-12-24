# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter '/test/'
end

if ENV['CI']
  require 'codecov'

  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'audioinfo'

require 'minitest/autorun'
require 'minitest/rg'

SUPPORT_DIR = File.expand_path('support', File.dirname(__FILE__))

DEFAULT_INFO = {
  'artist'   => 'Martin Spitznagel & Bryan Wright',
  'album'    => 'Star Wars: Cantina Band in Ragtime',
  'title'    => 'Star Wars: Cantina Band in Ragtime',
  'tracknum' => 1,
  'date'     => '2011-03-29',
  'length'   => 3,
  'bitrate'  => 25
}.freeze

MUSICBRAINZ_INFO = {
  'albumtype'     => 'single',
  'albumid'       => 'c357ac93-8896-4486-9630-05ae04c43345',
  'artistid'      => '57c051a1-41db-4764-bfab-ecac5cb3a144',
  'albumartistid' => '57c051a1-41db-4764-bfab-ecac5cb3a144',
  'trackid'       => '608be633-8a2b-4b90-b745-e38cae815c20'
}.freeze

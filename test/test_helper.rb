# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter '/test/'
end

if ENV['CI']
  require 'codecov'
  if Gem::Version.new(Codecov::VERSION) > Gem::Version.new('0.2.15')
    raise 'A new version of Codecov has been released, does it support Ruby3?'
  end

  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'audioinfo'

require 'minitest/autorun'
require 'minitest/rg'

SUPPORT_DIR = File.expand_path('support', File.dirname(__FILE__))

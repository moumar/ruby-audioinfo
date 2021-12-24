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

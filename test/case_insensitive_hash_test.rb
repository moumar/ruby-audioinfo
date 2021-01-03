# frozen_string_literal: true

require_relative 'test_helper'

class CaseInsensitiveHashTest < MiniTest::Test
  def setup
    @h = AudioInfo::CaseInsensitiveHash.new
  end

  def test_string_access
    @h['foo'] = 'bar'
    assert_equal 'bar', @h['foo']
  end

  def test_symbol_access
    @h[:foo] = 'bar'
    assert_equal 'bar', @h[:foo]
  end

  def test_case_insensitive_access
    @h['FOO'] = 'bar'
    assert_equal 'bar', @h['foo']
  end

  def test_copy_constructor
    h = AudioInfo::CaseInsensitiveHash.new({ 'FOO' => 'bar' })
    assert_equal 'bar', h['foo']
  end
end

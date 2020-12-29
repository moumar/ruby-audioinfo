# frozen_string_literal: true

require "audioinfo"
require "minitest/autorun"

class TestCaseInsensitiveHash < MiniTest::Unit::TestCase
  def test_string_access
    h = CaseInsensitiveHash.new
    h["foo"] = "bar"
    assert_equal "bar", h["foo"]
  end

  def test_symbol_access
    h = CaseInsensitiveHash.new
    h[:foo] = "bar"
    assert_equal "bar", h[:foo]
  end

  def test_case_insensitive_access
    h = CaseInsensitiveHash.new
    h["FOO"] = "bar"
    assert_equal "bar", h["foo"]
  end

  def test_copy_constructor
    h = CaseInsensitiveHash.new({ "FOO" => "bar" })
    assert_equal "bar", h["foo"]
  end
end

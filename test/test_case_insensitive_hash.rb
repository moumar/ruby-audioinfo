require "audioinfo"
require "minitest/autorun"

class TestCaseInsenitiveHash < MiniTest::Unit::TestCase

  def test_string_access
    h = CaseInsenitiveHash.new
    h["foo"] = "bar"
    assert_equal "bar", h["foo"]
  end

  def test_symbol_access
    h = CaseInsenitiveHash.new
    h[:foo] = "bar"
    assert_equal "bar", h[:foo]
  end

  def test_case_insensitive_access
    h = CaseInsenitiveHash.new
    h["FOO"] = "bar"
    assert_equal "bar", h["foo"]
  end

  def test_copy_constructor
    h = CaseInsenitiveHash.new({"FOO" => "bar"})
    assert_equal "bar", h["foo"]
  end
end

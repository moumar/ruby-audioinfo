class CaseInsenitiveHash < Hash
  def initialize(hash = {})
    super
    hash.each do |key, value|
      self[key.downcase] = value
    end
  end
  
  def [](key)
    super(key.downcase)
  end

  def []=(key, value)
    super(key.downcase, value)
  end
end

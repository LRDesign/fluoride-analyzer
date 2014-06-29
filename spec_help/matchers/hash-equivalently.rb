module HashEquivalenceMatchers

  class HashEquivalently

    def initialize(object)
      @object = object
    end

    def matches?(target)
      @target = target

      (@object == @target) &&
      (@target == @object) &&
      (@object.hash == @target.hash)
    end

    def failure_message_for_should
      errors = []
      errors << "Expected object == target but didn't" unless @object == @target
      errors << "Expected target == object but didn't" unless @target == @object
      errors << "Expected target#hash == object#hash but didn't " unless @target.hash == @object.hash
      "#{@object.inspect} and #{@target.inspect} should have been Hash-equivaent, but weren't.  Errors: \n" + errors.join("\n")
    end
    alias :failure_message :failure_message_for_should

    def failure_message_for_should_not
      "Expected #{@object.inspect} and #{@target.inspect} to hash differently, but all conditions matched."
    end
    alias :failure_message_when_negated :failure_message_for_should_not

  end

  def hash_equivalently_to(expected)
    HashEquivalently.new(expected)
  end

end



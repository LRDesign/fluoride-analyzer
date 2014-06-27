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
      errors << "Expected #{@object.inspect} == #{@target.inspect}" unless @object == @target
      errors << "Expected #{@target.inspect} == #{@object.inspect}" unless @target == @object
      errors << "Expected #{@target.inspect} and #{@object.inspect} to have equal #hash" unless @target.hash == @object.hash
      "Objects should have been Hash-equivaent, but weren't.  Errors: " + errors.join("\n")
    end

    def failure_message_for_should_not
      "Expected #{@object.inspect} and #{@target.inspect} to hash differently, but all conditions matched."
    end
  end

  def hash_equivalently_to(expected)
    HashEquivalently.new(expected)
  end

end



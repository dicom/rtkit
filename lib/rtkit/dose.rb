module RTKIT

  # NB! The Dose class is as of yet just a concept, and not in actual use
  # by RTKIT. It will probably be put to use in a future version.
  #
  # Contains data and methods related to a single Dose value.
  # The Dose value may be an average, median, max/min, etc derived
  # from a collection of Dose values as given in a DoseDistribution.
  #
  # === Relations
  #
  # * A Dose (value) belongs to the DoseDistribution from which it was created.
  # * The Dose class can be considered a subclass of Float (although strictly
  #    speaking it is rather a Float delegated class.
  #
  require 'delegate'
  class Dose < DelegateClass(Float)

    # The DoseDistribution that the single Dose value is derived from.
    attr_reader :distribution
    # The Dose value.
    attr_reader :value

    # Creates a new Dose instance.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- Float. A dose value.
    # * <tt>distribution</tt> -- The DoseDistribution which this single Dose value belongs to.
    #
    def initialize(value, distribution)
      raise ArgumentError, "Invalid argument 'distribution'. Expected DoseDistribution, got #{distribution.class}." unless distribution.is_a?(DoseDistribution)
      super(value.to_f)
      @value = value
      @distribution = distribution
    end

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_dose)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Returns self.
    #
    def to_dose
      self
    end


    private

    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@value, @distribution]
    end

  end
end
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
  #    speaking it is actually a Float delegated class.
  #
  class Dose < DelegateClass(Float)

    # The DoseDistribution that the single Dose value is derived from.
    attr_reader :distribution
    # The Dose value.
    attr_reader :value

    # Creates a new Dose instance.
    #
    # @param [#to_f] value the dose value
    # @param [DoseDistribution] distribution the dose distribution which this single dose value originates from
    #
    def initialize(value, distribution)
      raise ArgumentError, "Invalid argument 'distribution'. Expected DoseDistribution, got #{distribution.class}." unless distribution.is_a?(DoseDistribution)
      super(value.to_f)
      @value = value.to_f
      @distribution = distribution
    end

    # Checks for equality.
    #
    # Other and self are considered equivalent if they are
    # of compatible types and their attributes are equivalent.
    #
    # @param other an object to be compared with self.
    # @return [Boolean] true if self and other are considered equivalent
    #
    def ==(other)
      if other.respond_to?(:to_dose)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Computes a hash code for this object.
    #
    # @note Two objects with the same attributes will have the same hash code.
    #
    # @return [Fixnum] the object's hash code
    #
    def hash
      state.hash
    end

    # Returns self.
    #
    # @return [Dose] self
    #
    def to_dose
      self
    end


    private

    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@value, @distribution]
    end

  end
end
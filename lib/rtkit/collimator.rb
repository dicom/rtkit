module RTKIT

  # Contains DICOM data and methods related to a RT Beam Limiting Device
  # item, defined in a Beam.
  #
  # === Relations
  #
  # * A Beam has many Collimators.
  #
  class Collimator

    # The Beam that the CollimatorSetup is defined for.
    attr_reader :beam
    # Collimator boundaries (for multi leaf collimators only: the number of boundaries equals the number of leaves + 1).
    attr_reader :boundaries
    # The number of Leaf/Jaw (Collimator) Pairs.
    attr_reader :num_pairs
    # Collimator type.
    attr_reader :type

    # Creates a new Collimator instance from the RT Beam Limiting Device item
    # of the RTPlan file.
    #
    # @param [DICOM::Item] coll_item a DICOM item from which to create the Collimator
    # @param [Beam] beam the Beam instance which the Collimator shall be associated with
    # @return [Collimator] the created Collimator instance
    #
    def self.create_from_item(coll_item, beam)
      raise ArgumentError, "Invalid argument 'coll_item'. Expected DICOM::Item, got #{coll_item.class}." unless coll_item.is_a?(DICOM::Item)
      raise ArgumentError, "Invalid argument 'beam'. Expected Beam, got #{beam.class}." unless beam.is_a?(Beam)
      options = Hash.new
      # Values from the Beam Limiting Device Type Item:
      type = coll_item.value(COLL_TYPE)
      num_pairs = coll_item.value(NR_COLLIMATORS)
      boundaries = coll_item.value(COLL_BOUNDARIES)
      # Create the Collimator instance:
      c = self.new(type, num_pairs, beam, :boundaries => boundaries)
      return c
    end

    # Creates a new Collimator instance.
    #
    # @param [String] type the RT beam limiting device type
    # @param [Integer] num_pairs the number of leaf/jaw pairs
    # @param [Beam] beam the beam instance which this collimator belongs to
    # @param [Hash] options the options to use for creating the Collimator
    # @option options [Array<String>, NilClass, #to_s] :boundaries the leaf position boundaries (300A,00BE) (defaults to nil)
    #
    def initialize(type, num_pairs, beam, options={})
      raise ArgumentError, "Invalid argument 'beam'. Expected Beam, got #{beam.class}." unless beam.is_a?(Beam)
      # Set values:
      self.type = type
      self.num_pairs = num_pairs
      self.boundaries = options[:boundaries]
      # Set references:
      @beam = beam
      # Register ourselves with the Beam:
      @beam.add_collimator(self)
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
      if other.respond_to?(:to_collimator)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Sets new leaf position boundaries  (an array of coordinates).
    #
    # @param [Array<String>, NilClass, #to_s] value the leaf position boundaries (300A,00BE)
    #
    def boundaries=(value)
      if !value
        @boundaries = nil
      elsif value.is_a?(Array)
        @boundaries = value
      else
        # Split the string & convert to float:
        @boundaries = value.to_s.split("\\").collect {|str| str.to_f}
      end
    end

    # Computes a hash code for this object.
    #
    # @note Two objects with the same attributes will have the same hash code.
    #
    # @return [Fixnum] the object's hash code
    #
    def hash
      state.hash
    end

    # Sets a new number of leaf/jaw pairs.
    #
    # @param [#to_i] value the number of leaf/jaw pairs (300A,00BC)
    #
    def num_pairs=(value)
      raise ArgumentError, "Argument 'value' must be defined (got #{value.class})." unless value
      @num_pairs = value.to_i
    end

    # Returns self.
    #
    # @return [Collimator] self
    #
    def to_collimator
      self
    end

    # Creates a Beam Limiting Device Sequence Item from the attributes of the
    # Collimator.
    #
    # @return [DICOM::Item] the created DICOM item
    #
    def to_item
      item = DICOM::Item.new
      item.add(DICOM::Element.new(ROI_COLOR, @color))
      s = DICOM::Sequence.new(CONTOUR_SQ)
      item.add(s)
      item.add(DICOM::Element.new(REF_ROI_NUMBER, @number.to_s))
      # Add Contour items to the Contour Sequence (one or several items per Slice):
      @slices.each do |slice|
        slice.contours.each do |contour|
          s.add_item(contour.to_item)
        end
      end
      return item
    end

    # Sets a new RT beam limiting device type.
    #
    # @param [#to_s] value the RT beam limiting device type (300A,00B8)
    #
    def type=(value)
      raise ArgumentError, "Argument 'value' must be defined (got #{value.class})." unless value
      @type = value.to_s
    end


    private


    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@boundaries, @num_pairs, @type]
    end

  end
end
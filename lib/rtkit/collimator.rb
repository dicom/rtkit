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

    # Creates a new Collimator instance from the RT Beam Limiting Device item of the RTPlan file.
    # Returns the Collimator instance.
    #
    # === Parameters
    #
    # * <tt>coll_item</tt> -- The patient setup item from the DObject of a RTPlan file.
    # * <tt>beam</tt> -- The Beam instance that this Collimator belongs to.
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
    # === Parameters
    #
    # * <tt>type</tt> -- String. The RT Beam Limiting Device Type.
    # * <tt>num_pairs</tt> -- Integer. The Number of Leaf/Jaw Pairs.
    # * <tt>beam</tt> -- The Beam instance that this Collimator belongs to.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:boundaries</tt> -- Array/String. The Leaf Position Boundaries (300A,00BE). Defaults to nil.
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

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_collimator)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Creates and returns a Beam Limiting Device Sequence Item
    # from the attributes of the Collimator.
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

    # Sets new Leaf Position Boundaries  (an array of positions).
    #
    # === Parameters
    #
    # * <tt>value</tt> -- Array/String. The Leaf Position Boundaries (300A,00BE).
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

    # Sets a new RT Beam Limiting Device Type.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- Integer. The Number of Leaf/Jaw Pairs (300A,00BC).
    #
    def num_pairs=(value)
      raise ArgumentError, "Argument 'value' must be defined (got #{value.class})." unless value
      @num_pairs = value.to_i
    end

    # Returns self.
    #
    def to_collimator
      self
    end

    # Sets a new RT Beam Limiting Device Type.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- String. The RT Beam Limiting Device Type (300A,00B8).
    #
    def type=(value)
      raise ArgumentError, "Argument 'value' must be defined (got #{value.class})." unless value
      @type = value.to_s
    end


    private


    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@boundaries, @num_pairs, @type]
    end

  end
end
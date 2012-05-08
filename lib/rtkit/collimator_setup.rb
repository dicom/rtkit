module RTKIT

  # Contains DICOM data and methods related to a RT Beam Limiting Device
  # Position item, defined in a ControlPoint.
  #
  # === Relations
  #
  # * A ControlPoint has many CollimatorSetups.
  #
  class CollimatorSetup

    # The ControlPoint that the Collimator is defined for.
    attr_reader :control_point
    # Collimator pairs of positions.
    attr_reader :positions
    # Collimator type.
    attr_reader :type

    # Creates a new CollimatorSetup instance from the RT Beam Limiting Device Position item of the RTPlan file.
    # Returns the CollimatorSetup instance.
    #
    # === Parameters
    #
    # * <tt>coll_item</tt> -- The RT Beam Limiting Device Position item from the DObject of a RTPlan file.
    # * <tt>control_point</tt> -- The ControlPoint instance that this CollimatorSetup belongs to.
    #
    def self.create_from_item(coll_item, control_point)
      raise ArgumentError, "Invalid argument 'coll_item'. Expected DICOM::Item, got #{coll_item.class}." unless coll_item.is_a?(DICOM::Item)
      raise ArgumentError, "Invalid argument 'control_point'. Expected ControlPoint, got #{control_point.class}." unless control_point.is_a?(ControlPoint)
      options = Hash.new
      # Values from the Beam Limiting Device Position Item:
      type = coll_item.value(COLL_TYPE)
      positions = coll_item.value(COLL_POS)
      #positions = coll_item.value(COLL_POS).split("\\").collect {|str| str.to_f}
      # Regroup the positions values so they appear in pairs:
      #positions = positions.each_slice(2).collect{|i| i}.transpose
      # Create the Collimator instance:
      c = self.new(type, positions, control_point)
      return c
    end

    # Creates a new CollimatorSetup instance.
    #
    # === Parameters
    #
    # * <tt>type</tt> -- String. The RT Beam Limiting Device Type.
    # * <tt>positions</tt> -- Array. The collimator positions, organised in pairs of two values.
    # * <tt>control_point</tt> -- The ControlPoint instance that this CollimatorSetup belongs to.
    #
    def initialize(type, positions, control_point)
      raise ArgumentError, "Invalid argument 'control_point'. Expected ControlPoint, got #{control_point.class}." unless control_point.is_a?(ControlPoint)
      # Set values:
      self.type = type
      self.positions = positions
      # Set references:
      @control_point = control_point
      # Register ourselves with the ControlPoint:
      @control_point.add_collimator(self)
    end

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_collimator_setup)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Sets new Leaf/Jaw Positions (an array with pairs of positions).
    #
    # === Parameters
    #
    # * <tt>value</tt> -- Array. The Leaf/Jaw positions (300A,011C).
    #
    def positions=(value)
      raise ArgumentError, "Argument 'value' must be defined (got #{value.class})." unless value
      if value.is_a?(Array)
        @positions = value
      else
        # Split the string, convert to float, and regroup the positions so they appear in pairs:
        positions = value.to_s.split("\\").collect {|str| str.to_f}
        if positions.length == 2
          @positions = [positions]
        else
          @positions = positions.each_slice(2).collect{|i| i}.transpose
        end
      end
    end

    # Returns self.
    #
    def to_collimator_setup
      self
    end

    # Creates and returns a Beam Limiting Device Position Sequence Item
    # from the attributes of the CollimatorSetup.
    #
    def to_item
      item = DICOM::Item.new
      item.add(DICOM::Element.new(COLL_TYPE, @type))
      item.add(DICOM::Element.new(COLL_POS, positions_string))
      return item
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


    # Returns the position values converted to a '\' separated string with values
    # appearing in the order as specified by the dicom standard.
    #
    def positions_string
      @positions.transpose.join("\\")
    end

    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@positions, @type]
    end

  end
end
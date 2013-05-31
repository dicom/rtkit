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

    # Creates a new CollimatorSetup instance from the RT Beam Limiting Device
    # Position item of the RTPlan file.
    #
    # @param [DICOM::Item] coll_item a DICOM item from which to create the CollimatorSetup
    # @param [ControlPoint] control_point the ControlPoint instance which the CollimatorSetup shall be associated with
    # @return [CollimatorSetup] the created CollimatorSetup instance
    #
    def self.create_from_item(coll_item, control_point)
      raise ArgumentError, "Invalid argument 'coll_item'. Expected DICOM::Item, got #{coll_item.class}." unless coll_item.is_a?(DICOM::Item)
      raise ArgumentError, "Invalid argument 'control_point'. Expected ControlPoint, got #{control_point.class}." unless control_point.is_a?(ControlPoint)
      options = Hash.new
      # Values from the Beam Limiting Device Position Item:
      type = coll_item.value(COLL_TYPE)
      positions = coll_item.value(COLL_POS)
      # Create the Collimator instance:
      c = self.new(type, positions, control_point)
      return c
    end

    # Creates a new CollimatorSetup instance.
    #
    # @param [String] type the RT beam limiting device type
    # @param [Array<String>, #to_s] positions the collimator positions, organised in pairs of values
    # @param [ControlPoint] control_point the control point instance which this collimator setup belongs to
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

    # Checks for equality.
    #
    # Other and self are considered equivalent if they are
    # of compatible types and their attributes are equivalent.
    #
    # @param other an object to be compared with self.
    # @return [Boolean] true if self and other are considered equivalent
    #
    def ==(other)
      if other.respond_to?(:to_collimator_setup)
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

    # Sets new leaf/jaw positions (an array with pairs of coordinates).
    #
    # @param [Array<String>, #to_s] value the leaf/jaw positions (300A,011C)
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
    # @return [CollimatorSetup] self
    #
    def to_collimator_setup
      self
    end

    # Creates a Beam Limiting Device Position Sequence Item
    # from the attributes of the CollimatorSetup.
    #
    # @return [DICOM::Item] the created DICOM item
    #
    def to_item
      item = DICOM::Item.new
      item.add(DICOM::Element.new(COLL_TYPE, @type))
      item.add(DICOM::Element.new(COLL_POS, positions_string))
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


    # Gives the position values converted to a '\' separated string with values
    # appearing in the order as specified by the dicom standard.
    #
    # @return [String] the positions joined by a '\'
    #
    def positions_string
      @positions.transpose.join("\\")
    end

    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@positions, @type]
    end

  end
end
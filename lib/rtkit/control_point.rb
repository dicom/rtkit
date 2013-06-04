module RTKIT

  # Contains DICOM data and methods related to a ControlPoint.
  #
  # The first control point in a given beam defines the intial setup, and contains
  # all applicable parameters. The rest of the control points contains the parameters
  # which change at any control point.
  #
  # === Relations
  #
  # * A Beam has many ControlPoints.
  # * A ControlPoint has many Collimators.
  #
  class ControlPoint


    # The Beam that the ControlPoint is defined in.
    attr_reader :beam
    # Collimator (beam limiting device) angle (float).
    attr_reader :collimator_angle
    # Collimator (beam limiting device) rotation direction (string).
    attr_reader :collimator_direction
    # An array containing the ControlPoint's collimators.
    attr_reader :collimators
    # Cumulative meterset weight (float).
    attr_reader :cum_meterset
    # Nominal beam energy (float).
    attr_reader :energy
    # Gantry angle (float).
    attr_reader :gantry_angle
    # Gantry rotation direction (string).
    attr_reader :gantry_direction
    # Control point index (integer).
    attr_reader :index
    # Isosenter position (a coordinate triplet of positions x, y, z).
    attr_reader :iso
    # Pedestal angle (float).
    attr_reader :pedestal_angle
    # Pedestal rotation direction (string).
    attr_reader :pedestal_direction
    # Source to surface distance (float).
    attr_reader :ssd
    # Table top angle (float).
    attr_reader :table_top_angle
    # Table top rotation direction (string).
    attr_reader :table_top_direction
    # Table top lateral position (float).
    attr_reader :table_top_lateral
    # Table top longitudinal position (float).
    attr_reader :table_top_longitudinal
    # Table top vertical position (float).
    attr_reader :table_top_vertical

    # Creates a new control point instance from the Control Point Sequence Item
    # of the RTPlan file.
    #
    # @param [DICOM::Item] cp_item a DICOM item from which to create the ControlPoint
    # @param [Beam] beam the Beam instance which the ControlPoint shall be associated with
    # @return [ControlPoint] the created ControlPoint instance
    #
    def self.create_from_item(cp_item, beam)
      raise ArgumentError, "Invalid argument 'cp_item'. Expected DICOM::Item, got #{cp_item.class}." unless cp_item.is_a?(DICOM::Item)
      raise ArgumentError, "Invalid argument 'beam'. Expected Beam, got #{beam.class}." unless beam.is_a?(Beam)
      # Values from the Structure Set ROI Sequence Item:
      index = cp_item.value(CONTROL_POINT_INDEX)
      cum_meterset = cp_item.value(CUM_METERSET_WEIGHT)
      # Create the Beam instance:
      cp = self.new(index, cum_meterset, beam)
      # Set optional values:
      cp.collimator_angle = cp_item.value(COLL_ANGLE)
      cp.collimator_direction = cp_item.value(COLL_DIRECTION)
      cp.energy = cp_item.value(BEAM_ENERGY)
      cp.gantry_angle = cp_item.value(GANTRY_ANGLE)
      cp.gantry_direction = cp_item.value(GANTRY_DIRECTION)
      cp.iso = cp_item.value(ISO_POS)
      cp.pedestal_angle = cp_item.value(PEDESTAL_ANGLE)
      cp.pedestal_direction = cp_item.value(PEDESTAL_DIRECTION)
      cp.ssd = cp_item.value(SSD).to_f if cp_item.exists?(SSD)
      cp.table_top_angle = cp_item.value(TABLE_TOP_ANGLE)
      cp.table_top_direction = cp_item.value(TABLE_TOP_DIRECTION)
      cp.table_top_lateral = cp_item.value(TABLE_TOP_LATERAL)
      cp.table_top_vertical = cp_item.value(TABLE_TOP_VERTICAL)
      cp.table_top_longitudinal = cp_item.value(TABLE_TOP_LONGITUDINAL)
      # Iterate the beam limiting device position items and create Collimator instances:
      if cp_item.exists?(COLL_POS_SQ)
        cp_item[COLL_POS_SQ].each do |coll_item|
          CollimatorSetup.create_from_item(coll_item, cp)
        end
      end
      return cp
    end

    # Creates a new ControlPoint instance.
    #
    # @param [#to_i] index the control point index
    # @param [#to_f] cum_meterset the control point's cumulative meterset weight
    # @param [Beam] beam the Beam instance which the ControlPoint shall be associated with
    #
    def initialize(index, cum_meterset, beam)
      raise ArgumentError, "Invalid argument 'beam'. Expected Beam, got #{beam.class}." unless beam.is_a?(Beam)
      # Set values:
      @collimators = Array.new
      @associated_collimators = Hash.new
      self.index = index
      self.cum_meterset = cum_meterset
      # Set references:
      @beam = beam
      # Register ourselves with the Beam:
      @beam.add_control_point(self)
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
      if other.respond_to?(:to_control_point)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds a CollimatorSetup instance to this ControlPoint.
    #
    # @param [CollimatorSetup] coll a collimator setup instance to be associated with this control point
    #
    def add_collimator(coll)
      raise ArgumentError, "Invalid argument 'coll'. Expected CollimatorSetup, got #{coll.class}." unless coll.is_a?(CollimatorSetup)
      @collimators << coll unless @associated_collimators[coll.type]
      @associated_collimators[coll.type] = coll
    end

    # Gives the CollimatorSetup instance mathcing the specified type (RT Beam
    # Limiting Device Type).
    #
    # @overload collimator(type)
    #   @param [String] type collimator device type
    #   @return [CollimatorSetup, NilClass] the matched collimator setup (or nil if no collimator setup is matched)
    # @overload collimator
    #   @return [CollimatorSetup, NilClass] the first collimator setup of this instance (or nil if no child collimator setups exists)
    #
    def collimator(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        return @associated_collimators[args.first && args.first.to_s]
      else
        # No argument used, therefore we return the first CollimatorSetup instance:
        return @collimators.first
      end
    end

    # Sets a new beam limiting device angle.
    #
    # @param [NilClass, #to_f] value the beam limiting device angle (300A,0120)
    #
    def collimator_angle=(value)
      @collimator_angle = value && value.to_f
    end

    # Sets a new beam limiting device rotation direction.
    #
    # @param [NilClass, #to_s] value the beam limiting device rotation direction (300A,0121)
    #
    def collimator_direction=(value)
      @collimator_direction = value && value.to_s
    end

    # Sets a new cumulative meterset weight.
    #
    # @param [#to_f] value the cumulative meterset weight (300A,0134)
    # @raise [ArgumentError] if the value is undefined
    #
    def cum_meterset=(value)
      raise ArgumentError, "Argument 'value' must be defined (got #{value.class})." unless value
      @cum_meterset = value && value.to_f
    end

    # Sets a new nominal beam energy.
    #
    # @param [NilClass, #to_f] value the nominal beam energy (300A,0114)
    #
    def energy=(value)
      @energy = value && value.to_f
    end

    # Sets a new gantry angle.
    #
    # @param [NilClass, #to_f] value the gantry angle (300A,011E).
    #
    def gantry_angle=(value)
      @gantry_angle = value && value.to_f
    end

    # Sets a new gantry rotation direction.
    #
    # @param [NilClass, #to_s] value the gantry rotation direction (300A,011F)
    #
    def gantry_direction=(value)
      @gantry_direction = value && value.to_s
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

    # Sets a new control point index.
    #
    # @param [#to_i] value the control point index (300A,0112)
    # @raise [ArgumentError] if the value is undefined
    #
    def index=(value)
      raise ArgumentError, "Argument 'value' must be defined (got #{value.class})." unless value
      @index = value.to_i
    end

    # Sets a new isosenter position (a coordinate triplet of positions x, y, z).
    #
    # @param [NilClass, String, Coordinate] value the isocenter position (300A,0112)
    #
    def iso=(value)
      @iso = value && value.to_coordinate
    end

    # Sets a new patient support angle.
    #
    # @param [NilClass, #to_f] value the patient support angle (300A,0122)
    #
    def pedestal_angle=(value)
      @pedestal_angle = value && value.to_f
    end

    # Sets a new patient support rotation direction.
    #
    # @param [NilClass, #to_s] value the patient support rotation direction (300A,0123)
    #
    def pedestal_direction=(value)
      @pedestal_direction = value && value.to_s
    end

    # Sets a new source to surface distance.
    #
    # @param [NilClass, #to_f] value the source to surface distance (300A,012C)
    #
    def ssd=(value)
      @ssd = value && value.to_f
    end

    # Sets a new table top eccentric angle.
    #
    # @param [NilClass, #to_f] value the table top eccentric angle (300A,0125)
    #
    def table_top_angle=(value)
      @table_top_angle = value && value.to_f
    end

    # Sets a new table top eccentric rotation direction.
    #
    # @param [NilClass, #to_s] value the table top eccentric rotation direction (300A,0126)
    #
    def table_top_direction=(value)
      @table_top_direction = value && value.to_s
    end

    # Sets a new table top lateral position.
    #
    # @param [NilClass, #to_f] value the table top lateral position (300A,0125)
    #
    def table_top_lateral=(value)
      @table_top_lateral = value && value.to_f
    end

    # Sets a new table top longitudinal position.
    #
    # @param [NilClass, #to_f] value the table top longitudinal position (300A,0125)
    #
    def table_top_longitudinal=(value)
      @table_top_longitudinal = value && value.to_f
    end

    # Sets a new table top vertical position.
    #
    # @param [NilClass, #to_f] value the table top vertical position (300A,0125)
    #
    def table_top_vertical=(value)
      @table_top_vertical = value && value.to_f
    end

    # Returns self.
    #
    # @return [ControlPoint] self
    #
    def to_control_point
      self
    end

    # Creates a Control Point Sequence Item from the attributes of the ControlPoint.
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


    private


    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@collimators, @collimator_angle, @collimator_direction, @cum_meterset, @energy,
        @gantry_angle, @gantry_direction, @index, @iso, @pedestal_angle, @pedestal_direction,
        @ssd, @table_top_angle, @table_top_direction, @table_top_lateral,
        @table_top_longitudinal, @table_top_vertical
       ]
    end


  end

end
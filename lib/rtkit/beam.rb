module RTKIT

  # Contains DICOM data and methods related to a Beam, defined in a Plan.
  #
  # === Relations
  #
  # * A Plan has many Beams.
  # * A Beam has many ControlPoints.
  #
  class Beam

    # An array containing the beam's ControlPoints.
    attr_reader :control_points
    # Treatment delivery type.
    attr_reader :delivery_type
    # Beam description.
    attr_reader :description
    # Treatment machine name.
    attr_reader :machine
    # Beam meterset.
    attr_reader :meterset
    # Beam Name.
    attr_reader :name
    # Beam Number (Integer).
    attr_reader :number
    # The Plan that the Beam is defined in.
    attr_reader :plan
    # Radiation type.
    attr_reader :rad_type
    # Source-axis distance.
    attr_reader :sad
    # Beam type.
    attr_reader :type
    # Primary dosimeter unit.
    attr_reader :unit

    # Creates a new beam instance from the beam item of the RTPlan file,
    # which contains the information related to a particular beam.
    # This method also creates and connects any child structures as indicated
    # in this item (e.g. ControlPoint instances).
    #
    # @param [DICOM::Item] beam_item the Beam's Item from the Beam Sequence in the DObject of a RTPlan file
    # @param [Float] meterset the Beam's meterset (e.g. monitor units) value
    # @param [Plan] plan the Plan instance which this Beam belongs to
    # @return [Beam] the created Beam instance
    #
    def self.create_from_item(beam_item, meterset, plan)
      raise ArgumentError, "Invalid argument 'beam_item'. Expected DICOM::Item, got #{beam_item.class}." unless beam_item.is_a?(DICOM::Item)
      raise ArgumentError, "Invalid argument 'meterset'. Expected Float, got #{meterset.class}." unless meterset.is_a?(Float)
      raise ArgumentError, "Invalid argument 'plan'. Expected Plan, got #{plan.class}." unless plan.is_a?(Plan)
      options = Hash.new
      # Values from the Structure Set ROI Sequence Item:
      name = beam_item.value(BEAM_NAME) || ''
      number = beam_item.value(BEAM_NUMBER).to_i
      machine = beam_item.value(MACHINE_NAME) || ''
      options[:type] = beam_item.value(BEAM_TYPE)
      options[:delivery_type] = beam_item.value(DELIVERY_TYPE)
      options[:description] = beam_item.value(BEAM_DESCR)
      options[:rad_type] = beam_item.value(RAD_TYPE)
      options[:sad] = beam_item.value(SAD).to_f
      options[:unit] = beam_item.value(DOSIMETER_UNIT)
      # Create the Beam instance:
      beam = self.new(name, number, machine, meterset, plan, options)
      # Iterate the RT Beam Limiting Device items and create Collimator instances:
      if beam_item.exists?(COLL_SQ)
        beam_item[COLL_SQ].each do |coll_item|
          Collimator.create_from_item(coll_item, beam)
        end
      end
      # Iterate the control point items and create ControlPoint instances:
      beam_item[CONTROL_POINT_SQ].each do |cp_item|
        ControlPoint.create_from_item(cp_item, beam)
      end
      return beam
    end

    # Creates a new Beam instance.
    #
    # @param [String] name the beam name
    # @param [Integer] number the beam number
    # @param [String] machine the name of the treatment machine
    # @param [Float] meterset the Beam's meterset (e.g. monitor units) value
    # @param [Plan] plan the Plan instance which this Beam belongs to
    # @param [Hash] options the options to use for creating the Beam
    # @option options [Boolean] :type beam type (defaults to 'STATIC')
    # @option options [Boolean] :delivery_type treatment delivery type (defaults to 'TREATMENT')
    # @option options [Boolean] :description beam description (defaults to the value of the name attribute)
    # @option options [Boolean] :rad_type radiation type (defaults to 'PHOTON')
    # @option options [Boolean] :sad source-axis distance (defaults to 1000.0)
    # @option options [Boolean] :unit the primary dosimeter unit (defaults to 'MU')
    #
    def initialize(name, number, machine, meterset, plan, options={})
      raise ArgumentError, "Invalid argument 'plan'. Expected Plan, got #{plan.class}." unless plan.is_a?(Plan)
      @control_points = Array.new
      @collimators = Array.new
      @associated_control_points = Hash.new
      @associated_collimators = Hash.new
      # Set values:
      self.name = name
      self.number = number
      self.machine = machine
      self.meterset = meterset
      # Set options/defaults:
      self.type = options[:type] || 'STATIC'
      self.delivery_type = options[:delivery_type] || 'TREATMENT'
      self.description = options[:description] || @name
      self.rad_type = options[:rad_type] || 'PHOTON'
      self.sad = options[:sad] ? options[:sad] : 1000.0
      self.unit = options[:unit] || 'MU'
      # Set references:
      @plan = plan
      # Register ourselves with the Plan:
      @plan.add_beam(self)
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
      if other.respond_to?(:to_beam)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds a Collimator instance to this Beam.
    #
    # @param [Collimator] coll a collimator instance to be associated with this beam
    #
    def add_collimator(coll)
      raise ArgumentError, "Invalid argument 'coll'. Expected Collimator, got #{coll.class}." unless coll.is_a?(Collimator)
      @collimators << coll unless @associated_collimators[coll.type]
      @associated_collimators[coll.type] = coll
    end

    # Adds a ControlPoint instance to this Beam.
    #
    # @param [ControlPoint] cp a control point instance to be associated with this beam
    #
    def add_control_point(cp)
      raise ArgumentError, "Invalid argument 'cp'. Expected ControlPoint, got #{cp.class}." unless cp.is_a?(ControlPoint)
      @control_points << cp unless @associated_control_points[cp]
      @associated_control_points[cp] = true
    end

    # Creates a Beam Sequence Item from the attributes of the Beam instance.
    #
    # @return [DICOM::Item] a beam sequence item
    #
    def beam_item
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

    # Gives the Collimator instance mathcing the specified type.
    #
    # @overload collimator(type)
    #   @param [String] type collimator device type
    #   @return [Collimator, NilClass] the matched collimator (or nil if no collimator is matched)
    # @overload collimator
    #   @return [Collimator, NilClass] the first collimator of this instance (or nil if no child collimators exists)
    #
    def collimator(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        return @associated_collimators[args.first && args.first.to_s]
      else
        # No argument used, therefore we return the first instance:
        return @collimators.first
      end
    end

    # Gives the ControlPoint instance mathcing the specified index.
    #
    # @overload control_point(index)
    #   @param [String] index the control_point index
    #   @return [ControlPoint, NilClass] the matched control_point (or nil if no control_point is matched)
    # @overload control_point
    #   @return [ControlPoint, NilClass] the first control_point of this instance (or nil if no child control points exists)
    #
    def control_point(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        raise ArgumentError, "Invalid argument 'index'. Expected Integer (or nil), got #{args.first.class}." unless [Integer, NilClass].include?(args.first.class)
        return @associated_control_points[args.first]
      else
        # No argument used, therefore we return the first instance:
        return @control_points.first
      end
    end

    # Computes a digitally reconstructed radiograph (DRR), using the geometry
    # and settings of this beam, applied to the referenced (CT) image series.
    #
    # @note For now this is only supported for an image series
    #   having a patient orientation of HFS (head first supine).
    #
    # @param [RTImage] series an RT image series which the DRR is assigned to
    # @param [Hash] options optional parameters to use for DRR creation
    # @option options [Integer] :columns number of columns in the DRR image (defaults to 512)
    # @option options [Integer] :rows number of rows in the DRR image (defaults to 512)
    # @option options [Float] :delta_col distance (in mm) between columns in the DRR image (defaults to 1.0)
    # @option options [Float] :delta_row distance (in mm) between rows in the DRR image (defaults to 1.0)
    # @option options [Float] :sid source isocenter distance for the beam/image setup (defaults to 1000.0)
    # @option options [Float] :sdd source detector distance for the beam/image setup (defaults to 1600.0)
    # @raise if the beam instance doesn't have at least one associated control point
    # @return [ProjectionImage] the digitally reconstructed radiograph
    #
    def create_drr(series=nil, options={})
      raise ArgumentError, "Invalid argument 'series'." if series && !series.is_a?(RTImage)
      raise "This Beam instance has no associated control points. Unable to provide enough information to create a DRR." unless @control_points.length > 0
      # Get the necessary information from the first associated control point:
      gantry_angle = @control_points.first.gantry_angle
      isocenter = @control_points.first.iso
      # Set default values to undefined options:
      columns = options[:columns] || 512
      rows = options[:rows] || 512
      delta_col = options[:delta_col] || 1.0
      delta_row = options[:delta_row] || 1.0
      sdd = options[:sdd] || 1600.0
      sid = options[:sid] || 1000.0
      # Create an RT Image series if not given:
      series = RTImage.new(RTKIT.series_uid, @plan) unless series
      # Create a voxel space from the associated image series:
      vs = @plan.struct.image_series.first.to_voxel_space
      # Create a DRR pixel space:
      ps = PixelSpace.setup(columns, rows, delta_col, delta_row, gantry_angle, sdd, isocenter)
      # Create a beam geometric setup:
      bg = BeamGeometry.setup(gantry_angle, sid, isocenter, vs)
      # Create the DRR image data:
      bg.create_drr(ps)
      # Create the DRR DICOM projection image instance:
      drr = ProjectionImage.new(RTKIT.sop_uid, series, :beam => self)
      drr.columns = columns
      drr.rows = rows
      drr.row_spacing = ps.delta_row
      drr.col_spacing = ps.delta_col
      # Transfer data from the pixel space to the projection image:
      drr.narray = NArray.new(NArray::SINT, columns, rows)
      drr.narray[] = ps
      drr.set_positions
      # Return the DRR (DICOM image) instance:
      drr
    end

    # Sets a new treatment delivery type for this Beam.
    #
    # @param [String] value the treatment delivery type
    #
    def delivery_type=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      @delivery_type = value
    end

    # Sets a new description for this Beam.
    #
    # @param [String] value the beam description
    #
    def description=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      @description = value
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

    # Sets a new machine for this Beam.
    #
    # @param [String] value the machine of the beam
    #
    def machine=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      @machine = value
    end

    # Sets a new meterset for this Beam.
    #
    # @param [Float] value the beam meterset
    #
    def meterset=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected Float, got #{value.class}." unless value.is_a?(Float)
      @meterset = value
    end

    # Sets a new name for this Beam.
    #
    # @param [String] value the beam name
    #
    def name=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      @name = value
    end

    # Sets a new number for this Beam.
    #
    # @param [Integer] value the beam number
    #
    def number=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected Integer, got #{value.class}." unless value.is_a?(Integer)
      @number = value
    end

    # Sets a new radiation type for this Beam.
    #
    # @param [String] value the radiation type
    #
    def rad_type=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      @rad_type = value
    end

    # Creates a Referenced Beam Sequence Item from the attributes of the Beam instance.
    #
    # @return [DICOM::Item] a referenced beam sequence item
    #
    def ref_beam_item
      item = DICOM::Item.new
      item.add(DICOM::Element.new(OBS_NUMBER, @number.to_s))
      item.add(DICOM::Element.new(REF_ROI_NUMBER, @number.to_s))
      item.add(DICOM::Element.new(ROI_TYPE, @type))
      item.add(DICOM::Element.new(ROI_INTERPRETER, @interpreter))
      return item
    end

    # Sets a new source-axis distance for this Beam.
    #
    # @param [Float] value the source-axis distance
    #
    def sad=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected Float, got #{value.class}." unless value.is_a?(Float)
      @sad = value
    end

    # Returns self.
    #
    # @return [Beam] self
    #
    def to_beam
      self
    end

    # Sets a new beam type for this Beam.
    #
    # @param [String] value the beam type
    #
    def type=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      @type = value
    end

    # Sets a new primary dosimeter unit for this Beam.
    #
    # @param [String] value the primary dosimeter unit
    #
    def unit=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      @unit = value
    end


    private


    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@delivery_type, @description, @machine, @meterset, @name, @number, @rad_type, @sad, @type, @unit, @control_points]
    end

  end
end
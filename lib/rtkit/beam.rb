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

    # Creates a new beam instance from the beam item of the RTPlan file
    # which contains the information related to a particular beam.
    # This method also creates and connects any child structures as indicated in the items (e.g. ControlPoints).
    # Returns the Beam instance.
    #
    # === Parameters
    #
    # * <tt>beam_item</tt> -- The Beam's Item from the Beam Sequence in the DObject of a RTPlan file.
    # * <tt>meterset</tt> -- The Beam's meterset (e.g. monitor units) value.
    # * <tt>plan</tt> -- The Plan instance that this Beam belongs to.
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
    # === Parameters
    #
    # * <tt>name</tt> -- String. The Beam name.
    # * <tt>number</tt> -- Integer. The Beam number.
    # * <tt>machine</tt> -- The name of the treatment machine.
    # * <tt>meterset</tt> -- The Beam's meterset (e.g. monitor units) value.
    # * <tt>plan</tt> -- The Plan instance that this Beam belongs to.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:type</tt> -- String. Beam type. Defaults to 'STATIC'.
    # * <tt>:delivery_type</tt> -- String. Treatment delivery type. Defaults to 'TREATMENT'.
    # * <tt>:description</tt> -- String. Beam description. Defaults to the 'name' attribute.
    # * <tt>:rad_type</tt> -- String. Radiation type. Defaults to 'PHOTON'.
    # * <tt>:sad</tt> -- Float. Source-axis distance. Defaults to 1000.0.
    # * <tt>:unit</tt> -- String. The primary dosimeter unit. Defaults to 'MU'.
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

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_beam)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds a Collimator instance to this Beam.
    #
    def add_collimator(coll)
      raise ArgumentError, "Invalid argument 'coll'. Expected Collimator, got #{coll.class}." unless coll.is_a?(Collimator)
      @collimators << coll unless @associated_collimators[coll.type]
      @associated_collimators[coll.type] = coll
    end

    # Adds a ControlPoint instance to this Beam.
    #
    def add_control_point(cp)
      raise ArgumentError, "Invalid argument 'cp'. Expected ControlPoint, got #{cp.class}." unless cp.is_a?(ControlPoint)
      @control_points << cp unless @associated_control_points[cp]
      @associated_control_points[cp] = true
    end

    # Creates and returns a Beam Sequence Item from the attributes of the Beam.
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

    # Returns the Collimator instance mathcing the specified type (if an argument is used).
    # If a specified type doesn't match, nil is returned.
    # If no argument is passed, the first Collimator instance associated with the Beam is returned.
    #
    # === Parameters
    #
    # * <tt>type</tt> -- Integer. The Collimator's type.
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

    # Returns the ControlPoint instance mathcing the specified index (if an argument is used).
    # If a specified index doesn't match, nil is returned.
    # If no argument is passed, the first ControlPoint instance associated with the Beam is returned.
    #
    # === Parameters
    #
    # * <tt>index</tt> -- Integer. The ControlPoint's index.
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

    # Sets a new treatment delivery type for this Beam.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- String. The treatment delivery type.
    #
    def delivery_type=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      @delivery_type = value
    end

    # Sets a new description for this Beam.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- String. The beam description.
    #
    def description=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      @description = value
    end

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Sets a new machine for this Beam.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- String. The machine of the beam.
    #
    def machine=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      @machine = value
    end

    # Sets a new meterset for this Beam.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- Float. The beam meterset.
    #
    def meterset=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected Float, got #{value.class}." unless value.is_a?(Float)
      @meterset = value
    end

    # Sets a new name for this Beam.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- String. The beam name.
    #
    def name=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      @name = value
    end

    # Sets a new number for this Beam.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- Integer. The beam number.
    #
    def number=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected Integer, got #{value.class}." unless value.is_a?(Integer)
      @number = value
    end

    # Sets a new radiation type for this Beam.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- String. The radiation type.
    #
    def rad_type=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      @rad_type = value
    end

    # Creates and returns a Referenced Beam Sequence Item from the attributes of the Beam.
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
    # === Parameters
    #
    # * <tt>value</tt> -- Float. The source-axis distance.
    #
    def sad=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected Float, got #{value.class}." unless value.is_a?(Float)
      @sad = value
    end

    # Returns self.
    #
    def to_beam
      self
    end

    # Sets a new beam type for this Beam.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- String. The beam type.
    #
    def type=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      @type = value
    end

    # Sets a new primary dosimeter unit for this Beam.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- String. The primary dosimeter unit.
    #
    def unit=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      @unit = value
    end


    private


    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@delivery_type, @description, @machine, @meterset, @name, @number, @rad_type, @sad, @type, @unit, @control_points]
    end

  end
end
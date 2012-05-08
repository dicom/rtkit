module RTKIT

  # Contains DICOM data and methods related to a patient Setup item, defined in a Plan.
  #
  # === Relations
  #
  # * A Plan has a Setup.
  #
  class Setup

    # Patient setup number (Integer).
    attr_reader :number
    # Table top lateral setup displacement (Float).
    attr_reader :offset_lateral
    # Table top longitudinal setup displacement (Float).
    attr_reader :offset_longitudinal
    # Table top vertical setup displacement (Float).
    attr_reader :offset_vertical
    # The Plan that the Setup is defined for.
    attr_reader :plan
    # Patient position (orientation).
    attr_reader :position
    # Setup technique.
    attr_reader :technique

    # Creates a new Setup instance from the patient setup item of the RTPlan file.
    # Returns the Setup instance.
    #
    # === Parameters
    #
    # * <tt>setup_item</tt> -- The patient setup item from the DObject of a RTPlan file.
    # * <tt>plan</tt> -- The Plan instance that this Setup belongs to.
    #
    def self.create_from_item(setup_item, plan)
      raise ArgumentError, "Invalid argument 'setup_item'. Expected DICOM::Item, got #{setup_item.class}." unless setup_item.is_a?(DICOM::Item)
      raise ArgumentError, "Invalid argument 'plan'. Expected Plan, got #{plan.class}." unless plan.is_a?(Plan)
      options = Hash.new
      # Values from the Patient Setup Item:
      position = setup_item.value(PATIENT_POSITION) || ''
      number = setup_item.value(PATIENT_SETUP_NUMBER).to_i
      options[:technique] = setup_item.value(SETUP_TECHNIQUE)
      options[:offset_vertical] = setup_item.value(OFFSET_VERTICAL).to_f
      options[:offset_longitudinal] = setup_item.value(OFFSET_LONG).to_f
      options[:offset_lateral] = setup_item.value(OFFSET_LATERAL).to_f
      # Create the Setup instance:
      s = self.new(position, number, plan, options)
      return s
    end

    # Creates a new Setup instance.
    #
    # === Parameters
    #
    # * <tt>position</tt> -- String. The patient position (orientation).
    # * <tt>number</tt> -- Integer. The Setup number.
    # * <tt>plan</tt> -- The Plan instance that this Beam belongs to.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:technique</tt> -- String. Setup technique.
    # * <tt>:offset_vertical</tt> -- Float. Table top vertical setup displacement.
    # * <tt>:offset_longitudinal</tt> -- Float. Table top longitudinal setup displacement.
    # * <tt>:offset_lateral</tt> -- Float. Table top lateral setup displacement.
    #
    def initialize(position, number, plan, options={})
      raise ArgumentError, "Invalid argument 'plan'. Expected Plan, got #{plan.class}." unless plan.is_a?(Plan)
      # Set values:
      self.position = position
      self.number = number
      # Set options:
      self.technique = options[:technique] if options[:technique]
      self.offset_vertical = options[:offset_vertical] if options[:offset_vertical]
      self.offset_longitudinal = options[:offset_longitudinal] if options[:offset_longitudinal]
      self.offset_lateral = options[:offset_lateral] if options[:offset_lateral]
      # Set references:
      @plan = plan
      # Register ourselves with the Plan:
      @plan.add_setup(self)
    end

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_setup)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Sets a new patient setup number.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- Float. The patient setup number.
    #
    def number=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected Integer, got #{value.class}." unless value.is_a?(Integer)
      @number = value
    end

    # Sets a new table top lateral setup displacement.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- Float. The table top lateral setup displacement.
    #
    def offset_lateral=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected Float, got #{value.class}." unless value.is_a?(Float)
      @offset_lateral = value
    end

    # Sets a new table top longitudinal setup displacement.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- Float. The table top longitudinal setup displacement.
    #
    def offset_longitudinal=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected Float, got #{value.class}." unless value.is_a?(Float)
      @offset_longitudinal = value
    end

    # Sets a new table top vertical setup displacement.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- Float. The table top vertical setup displacement.
    #
    def offset_vertical=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected Float, got #{value.class}." unless value.is_a?(Float)
      @offset_vertical = value
    end

    # Sets a new patient position.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- String. The patient position.
    #
    def position=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      @position = value
    end

    # Sets a new setup technique.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- String. The setup technique.
    #
    def technique=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      @technique = value
    end

    # Creates and returns a Patient Setup Sequence Item from the attributes of the Setup.
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

    # Returns self.
    #
    def to_setup
      self
    end


    private


    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@number, @offset_lateral, @offset_longitudinal, @offset_vertical, @position, @technique]
    end

  end
end
module RTKIT

  # Contains DICOM data and methods related to a patient Setup item, defined in
  # a Plan.
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
    #
    # @param [DICOM::Item] setup_item the DICOM patient setup item from which to create the Setup
    # @param [Plan] plan the Plan instance which the Setup shall be associated with
    # @return [Setup] the created Setup instance
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
    # @param [String] position the patient position (orientation)
    # @param [Integer] number the setup number
    # @param [Plan] plan the Plan instance which the Setup is associated with
    # @param [Hash] options the options to use for creating the Setup
    # @option options [Float] :offset_lateral table top lateral setup displacement
    # @option options [Float] :offset_longitudinal table top longitudinal setup displacement
    # @option options [Float] :offset_vertical table top vertical setup displacement
    # @option options [String] :technique setup technique
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

    # Checks for equality.
    #
    # Other and self are considered equivalent if they are
    # of compatible types and their attributes are equivalent.
    #
    # @param other an object to be compared with self.
    # @return [Boolean] true if self and other are considered equivalent
    #
    def ==(other)
      if other.respond_to?(:to_setup)
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

    # Sets a new patient setup number.
    #
    # @param [Integer] value the patient setup number (300A,0182)
    #
    def number=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected Integer, got #{value.class}." unless value.is_a?(Integer)
      @number = value
    end

    # Sets a new table top lateral setup displacement.
    #
    # @param [Float] value the table top lateral setup displacement (300A,01D6)
    #
    def offset_lateral=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected Float, got #{value.class}." unless value.is_a?(Float)
      @offset_lateral = value
    end

    # Sets a new table top longitudinal setup displacement.
    #
    # @param [Float] value the table top longitudinal setup displacement (300A,01D4)
    #
    def offset_longitudinal=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected Float, got #{value.class}." unless value.is_a?(Float)
      @offset_longitudinal = value
    end

    # Sets a new table top vertical setup displacement.
    #
    # @param [Float] value the table top vertical setup displacement (300A,01D2)
    #
    def offset_vertical=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected Float, got #{value.class}." unless value.is_a?(Float)
      @offset_vertical = value
    end

    # Sets a new patient position.
    #
    # @param [String] value the patient position (0018,5100)
    #
    def position=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      @position = value
    end

    # Sets a new setup technique.
    #
    # @param [String] value the setup technique (300A,01B0)
    #
    def technique=(value)
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      @technique = value
    end

    # Creates an RTPLAN Patient Setup Sequence Item from the attributes of the
    # Setup instance.
    #
    # @return [DICOM::Item] an RTPLAN patient setup sequence sequence item
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
    # @return [Setup] self
    #
    def to_setup
      self
    end


    private


    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@number, @offset_lateral, @offset_longitudinal, @offset_vertical, @position, @technique]
    end

  end
end
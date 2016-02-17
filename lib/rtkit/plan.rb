module RTKIT

  # The Plan class contains methods that are specific for this modality (RTPLAN).
  #
  # === Inheritance
  #
  # * Plan inherits all methods and attributes from the Series class.
  #
  class Plan < Series

    # An array of radiotherapy beams belonging to this Plan.
    attr_reader :beams
    # The DObject instance of this Plan.
    attr_reader :dcm
    # The RT Plan Label.
    attr_accessor :label
    # The RT Plan Name.
    attr_accessor :name
    # The RT Plan Description.
    attr_accessor :plan_description
    #  An array of RTDose instances associated with this Plan.
    attr_reader :rt_doses
    #  An array of RTImage (series) instances associated with this Plan.
    attr_reader :rt_images
    # The referenced patient Setup instance.
    attr_reader :setup
    # The SOP Instance UID.
    attr_reader :sop_uid
    # The StructureSet that this Plan belongs to.
    attr_reader :struct

    # Creates a new Plan instance by loading the relevant information from the
    # specified DICOM object. The SOP Instance UID string value is used to
    # uniquely identify a Plan instance.
    #
    # @param [DICOM::DObject] dcm an RTPLAN DICOM object from which to create the Plan
    # @param [Study] study the Study instance which the (RT) Plan shall be associated with
    # @return [Plan] the created Plan instance
    #
    def self.load(dcm, study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'study'. Expected Study, got #{study.class}." unless study.is_a?(Study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject with modality 'RTPLAN', got #{dcm.value(MODALITY)}." unless dcm.value(MODALITY) == 'RTPLAN'
      # Required attributes:
      sop_uid = dcm.value(SOP_UID)
      # Optional attributes:
      class_uid = dcm.value(SOP_CLASS)
      date = dcm.value(SERIES_DATE)
      time = dcm.value(SERIES_TIME)
      description = dcm.value(SERIES_DESCR)
      series_uid = dcm.value(SERIES_UID)
      label = dcm.value(RT_PLAN_LABEL)
      name = dcm.value(RT_PLAN_NAME)
      plan_description = dcm.value(RT_PLAN_DESCR)
      # Get the corresponding StructureSet:
      struct = self.structure_set(dcm, study)
      # Create the Plan instance:
      plan = self.new(sop_uid, struct, :class_uid => class_uid, :date => date, :time => time, :description => description, :series_uid => series_uid, :label => label, :name => name, :plan_description => plan_description)
      plan.add(dcm)
      return plan
    end

    # Identifies the StructureSet that the Plan object belongs to. If the
    # referenced instances (StructureSet, ImageSeries & Frame) does not exist,
    # they are created by this method.
    #
    # @param [DICOM::DObject] dcm an RTPLAN DICOM object
    # @param [Study] study the Study instance which the (RT) Plan shall be associated with
    # @return [StructureSet] the structure set that the plan instance is to be associated with
    #
    def self.structure_set(dcm, study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'study'. Expected Study, got #{study.class}." unless study.is_a?(Study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject with modality 'RTPLAN', got #{dcm.value(MODALITY)}." unless dcm.value(MODALITY) == 'RTPLAN'
      # Extract the Frame of Reference UID:
      begin
        frame_of_ref = dcm.value(FRAME_OF_REF)
      rescue
        frame_of_ref = nil
      end
      # Extract referenced Structure Set SOP Instance UID:
      begin
        ref_struct_uid = dcm[REF_STRUCT_SQ][0].value(REF_SOP_UID)
      rescue
        ref_struct_uid = nil
      end
      # Create the Frame if it doesn't exist:
      f = study.patient.dataset.frame(frame_of_ref)
      f = Frame.new(frame_of_ref, study.patient) unless f
      # Create the StructureSet & ImageSeries if the StructureSet doesn't exist:
      struct = study.fseries(ref_struct_uid)
      unless struct
        # Create ImageSeries (assuming modality CT):
        is = ImageSeries.new(RTKIT.series_uid, 'CT', f, study)
        study.add_series(is)
        # Create StructureSet:
        struct = StructureSet.new(ref_struct_uid, is)
        study.add_series(struct)
      end
      return struct
    end

    # Creates a new Plan instance.
    #
    # @param [String] sop_uid the SOP Instance UID string
    # @param [StructureSet] struct the StructureSet instance which this Plan is associated with
    # @param [Hash] options the options to use for creating the plan
    # @option options [String] :date the series date (DICOM tag '0008,0021')
    # @option options [String] :description the series description (DICOM tag '0008,103E')
    # @option options [String] :series_uid the series instance UID (DICOM tag '0020,000E')
    # @option options [String] :time the series time (DICOM tag '0008,0031')
    #
    def initialize(sop_uid, struct, options={})
      raise ArgumentError, "Invalid argument 'sop_uid'. Expected String, got #{sop_uid.class}." unless sop_uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'struct'. Expected StructureSet, got #{struct.class}." unless struct.is_a?(StructureSet)
      # Pass attributes to Series initialization:
      options[:class_uid] = '1.2.840.10008.5.1.4.1.1.481.5' # RT Plan Storage
      # Get a randomized Series UID unless it has been defined in the options hash:
      series_uid = options[:series_uid] || RTKIT.series_uid
      super(series_uid, 'RTPLAN', struct.study, options)
      @sop_uid = sop_uid
      @struct = struct
      @label = options[:label]
      @name = options[:name]
      @plan_description = options[:plan_description]
      # Default attributes:
      @beams = Array.new
      @rt_doses = Array.new
      @rt_images = Array.new
      @associated_rt_doses = Hash.new
      # Register ourselves with the StructureSet:
      @struct.add_plan(self)
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
      if other.respond_to?(:to_plan)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Registers a DICOM Object to the Plan, and processes it
    # to create (and reference) the beams contained in the object.
    #
    # @param [DICOM::DObject] dcm an RTPLAN DICOM object
    #
    def add(dcm)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      @dcm = dcm
      #load_patient_setup
      load_beams
    end

    # Adds a Beam to this Plan.
    #
    # @param [Beam] beam a beam instance to be associated with this plan
    #
    def add_beam(beam)
      raise ArgumentError, "Invalid argument 'beam'. Expected Beam, got #{beam.class}." unless beam.is_a?(Beam)
      @beams << beam unless @beams.include?(beam)
    end

    # Adds a RTDose series to this Plan.
    #
    # @param [RTDose] rt_dose an RTDose instance to be associated with this plan
    #
    def add_rt_dose(rt_dose)
      raise ArgumentError, "Invalid argument 'rt_dose'. Expected RTDose, got #{rt_dose.class}." unless rt_dose.is_a?(RTDose)
      @rt_doses << rt_dose unless @associated_rt_doses[rt_dose.uid]
      @associated_rt_doses[rt_dose.uid] = rt_dose
    end

    # Adds a RTImage Series to this Plan.
    #
    # @param [RTImage] rt_image an RTImage instance to be associated with this plan
    #
    def add_rt_image(rt_image)
      raise ArgumentError, "Invalid argument 'rt_image'. Expected RTImage, got #{rt_image.class}." unless rt_image.is_a?(RTImage)
      @rt_images << rt_image unless @rt_images.include?(rt_image)
    end

    # Sets the Setup reference for this Plan.
    #
    # @param [Setup] setup the patient setup instance to be associated with this plan
    #
    def add_setup(setup)
      raise ArgumentError, "Invalid argument 'setup'. Expected Setup, got #{setup.class}." unless setup.is_a?(Setup)
      @setup = setup
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

    # Gives the RTDose instance mathcing the specified UID.
    #
    # @overload rt_dose(uid)
    #   @param [String] uid RTDose series instance UID
    #   @return [RTDose, NilClass] the matched RTDose (or nil if no RTDose is matched)
    # @overload rt_dose
    #   @return [RTDose, NilClass] the first RTDose of this instance (or nil if no child RTDose instances exists)
    #
    def rt_dose(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        raise ArgumentError, "Expected String (or nil), got #{args.first.class}." unless [String, NilClass].include?(args.first.class)
        return @associated_rt_doses[args.first]
      else
        # No argument used, therefore we return the first RTDose instance:
        return @rt_doses.first
      end
    end

    # Returns self.
    #
    # @return [Plan] self
    #
    def to_plan
      self
    end


    private


=begin
    # Registers this Plan instance with the StructureSet(s) that it references.
    #
    def connect_to_struct
      # Find out which Structure Set is referenced:
      @dcm[REF_STRUCT_SQ].each do |struct_item|
        ref_sop_uid = struct_item.value(REF_SOP_UID)
        matched_struct = @study.associated_instance_uids[ref_sop_uid]
        if matched_struct
          # The referenced series exists in our dataset. Proceed with setting up the references:
          matched_struct.add_plan(self)
          @structs << matched_struct
          @stuct = matched_struct unless @struct
        end
      end
    end
=end

    # Loads the Beam Items contained in the RTPlan and creates Beam instances.
    #
    # @note This method currently only supports setting up conventional
    #   external beam RTPlans. For other varieties, such as e.g. brachy plans,
    #   no child structures (e.g. beams) are created.
    #
    def load_beams
      # Top allow brachy plans to load without crashing, only proceed
      # if this seems to be an external beam plan object:
      if @dcm[BEAM_SQ]
        # Load the patient position.
        # NB! (FIXME) We assume that there is only one patient setup sequence item!
        Setup.create_from_item(@dcm[PATIENT_SETUP_SQ][0], self)
        # Load the information in a nested hash:
        item_group = Hash.new
        # NB! (FIXME) We assume there is only one fraction group!
        @dcm[FRACTION_GROUP_SQ][0][REF_BEAM_SQ].each do |fg_item|
          item_group[fg_item.value(REF_BEAM_NUMBER)] = {:meterset => fg_item.value(BEAM_METERSET).to_f}
        end
        @dcm[BEAM_SQ].each do |beam_item|
          item_group[beam_item.value(BEAM_NUMBER)][:beam] = beam_item
        end
        # Create a Beam instance for each set of items:
        item_group.each_value do |beam_items|
          Beam.create_from_item(beam_items[:beam], beam_items[:meterset], self)
        end
      end
    end

    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@beams, @rt_doses, @rt_images, @setup, @sop_uid]
    end

  end
end
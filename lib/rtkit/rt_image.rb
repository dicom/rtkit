module RTKIT

  # The RTImage class contains methods that are specific for this modality (RTIMAGE).
  #
  # === Inheritance
  #
  # * RTImage inherits all methods and attributes from the Series class.
  #
  class RTImage < Series

    # An array of Plan Verification Images associated with this RTImage Series.
    attr_reader :images
    # The Plan which this RTImage Series belongs to.
    attr_reader :plan

    # Creates a new RTImage (series) instance by loading the relevant information from the specified DICOM object.
    # The Series Instance UID string value is used to uniquely identify a RTImage (series) instance.
    #
    # === Parameters
    #
    # * <tt>dcm</tt> -- An instance of a DICOM object (DICOM::DObject) with modality 'RTIMAGE'.
    # * <tt>study</tt> -- The Study instance that this RTImage belongs to.
    #
    def self.load(dcm, study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'study'. Expected Study, got #{study.class}." unless study.is_a?(Study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject with modality 'RTIMAGE', got #{dcm.value(MODALITY)}." unless dcm.value(MODALITY) == 'RTIMAGE'
      # Required attributes:
      series_uid = dcm.value(SERIES_UID)
      # Optional attributes:
      class_uid = dcm.value(SOP_CLASS)
      date = dcm.value(SERIES_DATE)
      time = dcm.value(SERIES_TIME)
      description = dcm.value(SERIES_DESCR)
      series_uid = dcm.value(SERIES_UID)
      # Get the corresponding Plan:
      plan = self.plan(dcm, study)
      # Create the RTImage instance:
      rtimage = self.new(series_uid, plan, :class_uid => class_uid, :date => date, :time => time, :description => description)
      rtimage.add(dcm)
      return rtimage
    end

    # Identifies the Plan that the RTImage object belongs to.
    # If the referenced instances (Plan, StructureSet, ImageSeries & Frame) does not exist, they are created by this method.
    #
    def self.plan(dcm, study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'study'. Expected Study, got #{study.class}." unless study.is_a?(Study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject with modality 'RTIMAGE', got #{dcm.value(MODALITY)}." unless dcm.value(MODALITY) == 'RTIMAGE'
      # Extract the Frame of Reference UID:
      begin
        frame_of_ref = dcm.value(FRAME_OF_REF)
      rescue
        frame_of_ref = nil
      end
      # Extract referenced Plan SOP Instance UID:
      begin
        ref_plan_uid = dcm[REF_PLAN_SQ][0].value(REF_SOP_UID)
      rescue
        ref_plan_uid = nil
      end
      # Create the Frame if it doesn't exist:
      f = study.patient.dataset.frame(frame_of_ref)
      f = Frame.new(frame_of_ref, study.patient) unless f
      # Create the Plan, StructureSet & ImageSeries if the referenced Plan doesn't exist:
      plan = study.fseries(ref_plan_uid)
      unless plan
        # Create ImageSeries (assuming modality CT):
        is = ImageSeries.new(RTKIT.series_uid, 'CT', f, study)
        study.add_series(is)
        # Create StructureSet:
        struct = StructureSet.new(RTKIT.sop_uid, is)
        study.add_series(struct)
        # Create Plan:
        plan = Plan.new(ref_plan_uid, struct)
        study.add_series(plan)
      end
      return plan
    end

    # Creates a new RTImage instance.
    #
    # === Parameters
    #
    # * <tt>series_uid</tt> -- The Series Instance UID string.
    # * <tt>plan</tt> -- The Plan that this RTImage series belongs to.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:date</tt> -- String. The Series Date (DICOM tag '0008,0021').
    # * <tt>:time</tt> -- String. The Series Time (DICOM tag '0008,0031').
    # * <tt>:description</tt> -- String. The Series Description (DICOM tag '0008,103E').
    # * <tt>:series_uid</tt> -- String. The Series Instance UID (DICOM tag '0020,000E').
    #
    def initialize(series_uid, plan, options={})
      raise ArgumentError, "Invalid argument 'series_uid'. Expected String, got #{series_uid.class}." unless series_uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'plan'. Expected Plan, got #{plan.class}." unless plan.is_a?(Plan)
      # Pass attributes to Series initialization:
      options[:class_uid] = '1.2.840.10008.5.1.4.1.1.481.1' # RT Image Storage
      super(series_uid, 'RTIMAGE', plan.struct.study, options)
      @plan = plan
      # Default attributes:
      @images = Array.new
      @associated_images = Hash.new
      # Register ourselves with the Plan:
      @plan.add_rt_image(self)
    end

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_rt_image)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Registers a DICOM Object to the RTImage series, and processes it
    # to create (and reference) an (RT) Image instance linked to this RTImage series.
    #
    def add(dcm)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      Image.load(dcm, self)
      #load_patient_setup
      #load_fields
    end

    # Adds an Image to this RTImage series.
    #
    def add_image(image)
      raise ArgumentError, "Invalid argument 'image'. Expected Image, got #{image.class}." unless image.is_a?(Image)
      @images << image unless @associated_images[image.uid]
      @associated_images[image.uid] = image
    end

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Returns self.
    #
    def to_rt_image
      self
    end


    private


=begin
    # Registers this RTImage series instance with the Plan that it references.
    #
    def connect_to_plan(dcm)
      # Find out which Plan is referenced:
      dcm[REF_PLAN_SQ].each do |plan_item|
        ref_sop_uid = plan_item.value(REF_SOP_UID)
        matched_plan = @study.associated_instance_uids[ref_sop_uid]
        if matched_plan
          # The referenced series exists in our dataset. Proceed with setting up the references:
          matched_plan.add_rtimage(self)
          @plan = matched_plan
        end
      end
    end
=end

    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@series_uid, @images]
    end

  end
end
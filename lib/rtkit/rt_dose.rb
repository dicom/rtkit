module RTKIT

  # The RTDose class contains methods that are specific for this modality
  # (RTDOSE).
  #
  # === Inheritance
  #
  # * RTDose inherits all methods and attributes from the Series class.
  #
  class RTDose < Series

    # The Plan which this RTDose series belongs to.
    attr_reader :plan
    # An array of dose Volume instances associated with this RTDose series.
    attr_accessor :volumes

    # Creates a new RTDose instance by loading the relevant information from
    # the specified DICOM object. The Series Instance UID string value is used
    # to uniquely identify a RTDose instance.
    #
    # @param [DICOM::DObject] dcm an RTDOSE DICOM object from which to create the RTDose object
    # @param [Study] study the Study instance which the RTDose object shall be associated with
    # @return [RTDose] the created RTDose instance
    #
    def self.load(dcm, study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'study'. Expected Study, got #{study.class}." unless study.is_a?(Study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject with modality 'RTDOSE', got #{dcm.value(MODALITY)}." unless dcm.value(MODALITY) == 'RTDOSE'
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
      # Create the RTDose instance:
      dose = self.new(series_uid, plan, :class_uid => class_uid, :date => date, :time => time, :description => description)
      dose.add(dcm)
      return dose
    end

    # Identifies the Plan that the RTDose object belongs to. If the referenced
    # instances (Plan, StructureSet, ImageSeries & Frame) does not exist, they
    # are created by this method.
    #
    # @param [DICOM::DObject] dcm an RTDOSE DICOM object
    # @param [Study] study the Study instance which the RTDose instance shall be associated with
    # @return [Plan] the (RT) Plan that the RTDose instance is to be associated with
    #
    def self.plan(dcm, study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'study'. Expected Study, got #{study.class}." unless study.is_a?(Study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject with modality 'RTDOSE', got #{dcm.value(MODALITY)}." unless dcm.value(MODALITY) == 'RTDOSE'
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

    # Creates a new RTDose instance.
    #
    # @param [String] series_uid the series instance UID string
    # @param [Plan] plan the (RT) Plan instance which this RTDose instance is associated with
    # @param [Hash] options the options to use for creating the RTDose
    # @option options [String] :date the series date (DICOM tag '0008,0021')
    # @option options [String] :description the series description (DICOM tag '0008,103E')
    # @option options [String] :time the series time (DICOM tag '0008,0031')
    #
    def initialize(series_uid, plan, options={})
      raise ArgumentError, "Invalid argument 'series_uid'. Expected String, got #{series_uid.class}." unless series_uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'plan'. Expected Plan, got #{plan.class}." unless plan.is_a?(Plan)
      # Pass attributes to Series initialization:
      options[:class_uid] = '1.2.840.10008.5.1.4.1.1.481.2' # RT Dose Storage
      super(series_uid, 'RTDOSE', plan.study, options)
      @plan = plan
      # Default attributes:
      @volumes = Array.new
      @associated_volumes = Hash.new
      # Register ourselves with the Plan:
      @plan.add_rt_dose(self)
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
      if other.respond_to?(:to_rt_dose)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Registers a DICOM Object to the RTDose series, and processes it to create
    # (and reference) a DoseVolume instance linked to this RTDose series.
    #
    # @param [DICOM::DObject] dcm an RTDOSE DICOM object
    #
    def add(dcm)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      DoseVolume.load(dcm, self) if proper_dose_volume?(dcm)
    end

    # Adds a DoseVolume instance to this RTDose series.
    #
    # @param [DoseVolume] volume a dose volume instance to be associated with this RTDose
    #
    def add_volume(volume)
      raise ArgumentError, "Invalid argument 'volume'. Expected DoseVolume, got #{volume.class}." unless volume.is_a?(DoseVolume)
      @volumes << volume unless @associated_volumes[volume.uid]
      @associated_volumes[volume.uid] = volume
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

    # Creates a DoseVolume which is the sum of the individual beam dose volumes
    # of this instance. If a summed dose volume is already present it returns
    # this one.
    #
    # In some cases, we have individual DoseVolume instances corresponding to
    # the dose for a single beam, whereas the sum DoseVolume shall correspond
    # to the summed dose of the entire treatment plan.
    #
    # @return [DoseVolume] the dose volume corresponding to the summed plan dose
    #
    def sum
      if @sum
        # If the sum volume has already been created, return it instead of recreating:
        return @sum
      else
        if @volumes.length > 0
          nr_frames = @volumes.first.images.length
          # Create the sum DoseVolume instance:
          sop_uid = @volumes.first.sop_uid + ".1"
          @sum = DoseVolume.new(sop_uid, @volumes.first.frame, @volumes.first.dose_series, :sum => true)
          # Sum the dose of the various DoseVolumes:
          dose_sum = NArray.int(nr_frames, @volumes.first.images.first.columns, @volumes.first.images.first.rows)
          @volumes.each { |volume| dose_sum += volume.dose_arr }
          # Convert dose float array to integer pixel values of a suitable range,
          # along with a corresponding scaling factor:
          sum_scaling_coeff = dose_sum.max / 65000.0
          if sum_scaling_coeff == 0.0
            pixel_values = NArray.int(nr_frames, @volumes.first.images.first.columns, @volumes.first.images.first.rows)
          else
            pixel_values = dose_sum * (1 / sum_scaling_coeff)
          end
          # Set the scaling coeffecient:
          @sum.scaling = sum_scaling_coeff
          # Collect the rest of the image information needed to create new dose images:
          sop_uids = RTKIT.sop_uids(nr_frames)
          slice_positions = @volumes.first.images.collect {|img| img.pos_slice}
          columns = @volumes.first.images.first.columns
          rows = @volumes.first.images.first.rows
          pos_x = @volumes.first.images.first.pos_x
          pos_y = @volumes.first.images.first.pos_y
          col_spacing = @volumes.first.images.first.col_spacing
          row_spacing = @volumes.first.images.first.row_spacing
          cosines = @volumes.first.images.first.cosines
          # Create dose images for our sum dose volume:
          nr_frames.times do |i|
            img = SliceImage.new(sop_uids[i], slice_positions[i], @sum)
            # Fill in image information:
            img.columns = columns
            img.rows = rows
            img.pos_x = pos_x
            img.pos_y = pos_y
            img.col_spacing = col_spacing
            img.row_spacing = row_spacing
            img.cosines = cosines
            # Fill in the pixel frame data:
            img.narray = pixel_values[i, true, true]
          end
          return @sum
        end
      end
    end

    # Returns self.
    #
    # @return [RTDose] self
    #
    def to_rt_dose
      self
    end

    # Gives the DoseVolume instance mathcing the specified UID.
    #
    # @overload volume(uid)
    #   @param [String] uid SOP instance UID
    #   @return [DoseVolume, NilClass] the matched dose volume (or nil if no dose volume is matched)
    # @overload volume
    #   @return [DoseVolume, NilClass] the first dose volume of this instance (or nil if no child volumes exists)
    #
    def volume(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        raise ArgumentError, "Expected String (or nil), got #{args.first.class}." unless [String, NilClass].include?(args.first.class)
        return @associated_volumes[args.first]
      else
        # No argument used, therefore we return the first Volume instance:
        return @volumes.first
      end
    end


    private


    # Checks whether the given DICOM RTDose file is a proper dose volume. From
    # experience, some treatment planning systems (e.g. Oncentra), will output
    # one dose volume per plan beam + one 'empty' dose volume that does not
    # actually contain any dose information. This particular non-dose file
    # should be ignored when loading dose volumes.
    #
    # @param [DICOM::DObject] dcm a DICOM object of modality RTDose
    # @return [Boolean] true if the dose volume appears to be 'proper'
    #
    def proper_dose_volume?(dcm)
      # Some observed characterstics about these files:
      # -The value of the Dose Grid Scaling tag is 1.0
      # -The values of the Dose Value tags in the RT Dose ROI Sequence items are 0.0
      # -The Pixel Data array doesn't contain any non-zero values
      # -The Pixel Data array may be small (1x1 element per slice)
      dcm.value('3004,000E').to_f.round(4) == 1.0000 ? false : true
    end

    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@series_uid, @volumes]
    end

  end

end
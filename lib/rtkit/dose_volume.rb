module RTKIT

  # Contains the DICOM data and methods related to a pixel dose volume.
  #
  # === Inheritance
  #
  # * DoseVolume inherits all methods and attributes from the Series class.
  #
  class DoseVolume < Series

    include ImageParent

    # The DObject instance of this dose Volume.
    attr_reader :dcm
    # The DoseSeries that this dose Volume belongs to.
    attr_reader :dose_series
    # The Frame (of Reference) which this DoseVolume belongs to.
    attr_accessor :frame
    #  An array of dose pixel Image instances (frames) associated with this dose Volume.
    attr_reader :images
    # The Dose Grid Scaling factor (float).
    attr_reader :scaling
    # The SOP Instance UID.
    attr_reader :sop_uid

    # Creates a new Volume instance by loading image information from the specified DICOM object.
    # The volume object's SOP Instance UID string value is used to uniquely identify a volume.
    #
    # === Parameters
    #
    # * <tt>dcm</tt> -- An instance of a DICOM object (DObject).
    # * <tt>series</tt> -- The Series instance that this Volume belongs to.
    #
    def self.load(dcm, series)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'series'. Expected Series, got #{series.class}." unless series.is_a?(Series)
      raise ArgumentError, "Invalid argument 'dcm'. Expected an image related modality, got #{dcm.value(MODALITY)}." unless IMAGE_MODALITIES.include?(dcm.value(MODALITY))
      sop_uid = dcm.value(SOP_UID)
      # Check if a Frame with the given UID already exists, and if not, create one:
      frame = series.study.patient.dataset.frame(dcm.value(FRAME_OF_REF)) || frame = series.study.patient.create_frame(dcm.value(FRAME_OF_REF), dcm.value(POS_REF_INDICATOR))
      # Create the RTDose instance:
      volume = self.new(sop_uid, frame, series)
      volume.add(dcm)
      return volume
    end

    # Creates a new Volume instance. The SOP Instance UID tag value is used to uniquely identify a volume.
    #
    # === Parameters
    #
    # * <tt>sop_uid</tt> -- The SOP Instance UID string.
    # * <tt>frame</tt> -- The Frame instance that this DoseVolume belongs to.
    # * <tt>series</tt> -- The Series instance that this Image belongs to.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:sum</tt> -- Boolean. If true, the DoseVolume will not be added as a (beam) volume to the parent RTDose.
    #
    def initialize(sop_uid, frame, series, options={})
      raise ArgumentError, "Invalid argument 'sop_uid'. Expected String, got #{sop_uid.class}." unless sop_uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'frame'. Expected Frame, got #{frame.class}." unless frame.is_a?(Frame)
      raise ArgumentError, "Invalid argument 'series'. Expected Series, got #{series.class}." unless series.is_a?(Series)
      raise ArgumentError, "Invalid argument 'series'. Expected Series to have an image related modality, got #{series.modality}." unless IMAGE_MODALITIES.include?(series.modality)
      # Pass attributes to Series initialization:
      super(series.uid, 'RTDOSE', series.study)
      # Key attributes:
      @sop_uid = sop_uid
      @frame = frame
      @dose_series = series
      # Default attributes:
      @images = Array.new
      @associated_images = Hash.new
      @image_positions = Hash.new
      # Register ourselves with the DoseSeries:
      @dose_series.add_volume(self) unless options[:sum]
      # Register ourselves with the study & frame:
      #@study.add_series(self)
      @frame.add_series(self)
    end

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_dose_volume)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Registers a DICOM Object to the dose Volume, and processes it
    # to create (and reference) a (dose) Image instance (frame) linked to this dose Volume.
    #
    def add(dcm)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      @dcm = dcm
      self.scaling = dcm.value(DOSE_GRID_SCALING)
      pixels = dcm.narray
      rows = dcm.value(ROWS)
      cols = dcm.value(COLUMNS)
      image_position = dcm.value(IMAGE_POSITION).split("\\")
      pos_x = image_position[0].to_f
      pos_y = image_position[1].to_f
      frame_origin = image_position[2].to_f
      cosines = dcm.value(IMAGE_ORIENTATION).split("\\").collect {|val| val.to_f} if dcm.value(IMAGE_ORIENTATION)
      spacing = dcm.value(SPACING).split("\\")
      col_spacing = spacing[1].to_f
      row_spacing = spacing[0].to_f
      nr_frames = dcm.value(NR_FRAMES).to_i
      frame_offsets = dcm.value(GRID_FRAME_OFFSETS).split("\\").collect {|value| value.to_f}
      sop_uids = RTKIT.sop_uids(nr_frames)
      # Iterate each frame and create dose images:
      nr_frames.times do |i|
        # Create an Image instance (using an arbitrary UID, as individual dose frames don't really have UIDs in DICOM):
        img = Image.new(sop_uids[i], self)
        # Fill in image information:
        img.columns = cols
        img.rows = rows
        img.pos_x = pos_x
        img.pos_y = pos_y
        img.pos_slice = frame_origin + frame_offsets[i]
        img.col_spacing = col_spacing
        img.row_spacing = row_spacing
        img.cosines = cosines
        # Fill in the pixel frame data:
        img.narray = pixels[i, true, true]
      end
    end

    # Adds an Image to this Volume.
    #
    def add_image(image)
      raise ArgumentError, "Invalid argument 'image'. Expected Image, got #{image.class}." unless image.is_a?(Image)
      @images << image unless @associated_images[image.uid]
      @associated_images[image.uid] = image
      @image_positions[image.pos_slice] = image
    end

    # Creates a binary volume object consisting of a series of binary
    # (dose thresholded) images, extracted from this dose volume.
    # Returns a BinVolume instance with binary image references equal to
    # the number of dose images defined for this DoseVolume.
    #
    # === Notes
    #
    # * Even though listed as optional parameters, at least one of the :min and :max
    #   options must be specified in order to construct a valid binary volume.
    #
    # === Parameters
    #
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:min</tt> -- Float. The lower dose threshold for dose elements to be included in the resulting dose bin volume.
    # * <tt>:max</tt> -- Float. The upper dose threshold for dose elements to be included in the resulting dose bin volume.
    # * <tt>:volume</tt> -- By default the BinVolume is created against the images of this DoseVolume. Optionally, an ImageSeries used by the ROI's of this Study can be specified.
    #
    def bin_volume(options={})
      raise ArgumentError, "Need at least one dose limit parameter. Neither :min nor :max was specified." unless options[:min] or options[:max]
      volume = options[:volume] || self
      return BinVolume.from_dose(self, options[:min], options[:max], volume)
    end

    # Returns the dose distribution for a specified ROI (or entire volume)
    # and a specified beam (or all beams).
    #
    # === Parameters
    #
    # * <tt>roi</tt> -- A specific ROI for which to evalute the dose in (if omitted, the entire volume is evaluted).
    #
    def distribution(roi=nil)
      raise ArgumentError, "Invalid argument 'roi'. Expected ROI, got #{roi.class}." if roi && !roi.is_a?(ROI)
      raise ArgumentError, "Invalid argument 'roi'. The specified ROI does not have the same StructureSet parent as this DoseVolume." if roi && roi.struct != @dose_series.plan.struct
      if roi
        # Extract a binary volume from the ROI, based on this DoseVolume:
        bin_vol = roi.bin_volume(self)
      else
        # Create a binary volume which marks the entire dose volume:
        bin_vol = BinVolume.from_volume(self)
      end
      # Create a DoseDistribution from the BinVolume:
      dose_distribution = DoseDistribution.create(bin_vol)
    end

    # Returns the 3D dose pixel NArray retrieved from the #narray method,
    # multiplied with the scaling coefficient, which in effect yields
    # a 3D dose array.
    #
    def dose_arr
      # Convert integer array to float array and multiply:
      return narray.to_type(4) * @scaling
    end

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Returns the Image instance mathcing the specified SOP Instance UID (if an argument is used).
    # If a specified UID doesn't match, nil is returned.
    # If no argument is passed, the first Image instance associated with the Volume is returned.
    #
    # === Parameters
    #
    # * <tt>uid_or_pos</tt> -- String/Float. The value of the SOP Instance UID element or the image position.
    #
    def image(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        if args.first.is_a?(Float)
          # Presumably an image position:
          return @image_positions[args.first]
        else
          # Presumably a uid string:
          return @associated_images[args.first && args.first.to_s]
        end
      else
        # No argument used, therefore we return the first Image instance:
        return @images.first
      end
    end

    # Builds a 3D dose pixel NArray from the dose images
    # belonging to this DoseVolume. The array has shape [frames, columns, rows]
    # and contains pixel values. To convert to dose values, the array must be
    # multiplied with the scaling attribute.
    #
    def narray
      if @images.length > 0
        narr = NArray.int(@images.length, @images.first.columns, @images.first.rows)
        @images.each_index do |i|
          narr[i, true, true] = @images[i].narray
        end
        return narr
      end
    end

    # Sets a new dose grid scaling.
    #
    # === Parameters
    #
    # * <tt>value</tt> -- Float. The dose grid scaling (3004,000E).
    #
    def scaling=(value)
      @scaling = value && value.to_f
    end

    # Returns self.
    #
    def to_dose_volume
      self
    end

=begin
    # Updates the position that is registered for the image for this series.
    #
    def update_image_position(image, new_pos)
      raise ArgumentError, "Invalid argument 'image'. Expected Image, got #{image.class}." unless image.is_a?(Image)
      # Remove old position key:
      @image_positions.delete(image.pos)
      # Add the new position:
      @image_positions[new_pos] = image
    end
=end


    private


    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@images, @scaling, @sop_uid]
    end

  end
end
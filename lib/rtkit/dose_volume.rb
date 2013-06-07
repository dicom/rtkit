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

    # Creates a new Volume instance by loading image information from the
    # specified DICOM object. The volume object's SOP Instance UID string
    # value is used to uniquely identify a volume.
    #
    # @param [DICOM::DObject] dcm an RTDOSE DICOM object from which to create the DoseVolume
    # @param [Series] series the Series instance (typically RTDose) which the DoseVolume shall be associated with
    # @return [DoseVolume] the created DoseVolume instance
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

    # Creates a new Volume instance. The SOP Instance UID tag value is used to
    # uniquely identify a volume.
    #
    # @param [String] sop_uid the SOP Instance UID string
    # @param [String] frame the Frame instance which this DoseVolume is associated with
    # @param [Series] series the Series instance which this DoseVolume is associated with
    # @param [Hash] options the options to use for creating the dose volume
    # @option options [Boolean] :sum if true, the DoseVolume will not be added as a (beam) volume to the parent RTDose
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

    # Checks for equality.
    #
    # Other and self are considered equivalent if they are
    # of compatible types and their attributes are equivalent.
    #
    # @param other an object to be compared with self.
    # @return [Boolean] true if self and other are considered equivalent
    #
    def ==(other)
      if other.respond_to?(:to_dose_volume)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Registers a DICOM object to the dose volume, and processes it to create
    # (and reference) a (dose) image instance (frame) linked to this dose volume.
    #
    # @param [DICOM::DObject] dcm an RTDOSE DICOM object
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
        img = SliceImage.new(sop_uids[i], frame_origin + frame_offsets[i], self)
        # Fill in image information:
        img.columns = cols
        img.rows = rows
        img.pos_x = pos_x
        img.pos_y = pos_y
        img.col_spacing = col_spacing
        img.row_spacing = row_spacing
        img.cosines = cosines
        # Fill in the pixel frame data:
        img.narray = pixels[i, true, true]
      end
    end

    # Adds an Image to this Volume.
    #
    # @param [Image] image an image instance to be associated with this dose volume
    #
    def add_image(image)
      raise ArgumentError, "Invalid argument 'image'. Expected Image, got #{image.class}." unless image.is_a?(Image)
      @images << image unless @associated_images[image.uid]
      @associated_images[image.uid] = image
      @image_positions[image.pos_slice.round(2)] = image
    end

    # Creates a binary volume object consisting of a series of binary
    # (dose thresholded) images, extracted from this dose volume.
    #
    # @note Even though listed as optional parameters, at least one of the :min
    #   and :max options must be specified in order to construct a valid binary volume.
    #
    # @param [Hash] options the options to use for creating the binary volume
    # @option options [Float] :min the lower dose threshold for dose elements to be included in the resulting dose bin volume
    # @option options [Float] :max the upper dose threshold for dose elements to be included in the resulting dose bin volume
    # @option options [Float] :volume by default the BinVolume is created against the images of this DoseVolume, however, by setting this option, an ImageSeries used by the ROIs of this Study can be specified
    # @return [BinVolume] a binary volume with binary image references equal to the number of dose images defined for this DoseVolume
    #
    def bin_volume(options={})
      raise ArgumentError, "Need at least one dose limit parameter. Neither :min nor :max was specified." unless options[:min] or options[:max]
      volume = options[:volume] || self
      return BinVolume.from_dose(self, options[:min], options[:max], volume)
    end

    # Extracts the dose distribution for a specified ROI (or entire volume)
    # and a specified beam (or all beams).
    #
    # @param [ROI] roi a specific ROI for which to evalute the dose in (if omitted, the entire volume is evaluted)
    # @return [DoseDistribution] the dose distribution for the selected region of interest
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

    # Gives the 3D dose pixel NArray retrieved from the #narray method,
    # multiplied with the scaling coefficient, which in effect yields a 3D dose
    # array.
    #
    # @return [NArray<Float>] a 3D dose array
    #
    def dose_arr
      # Convert integer array to float array and multiply:
      return narray.to_type(4) * @scaling
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

    # Gives the Image instance mathcing the specified UID or image position.
    #
    # @overload image(pos)
    #   @param [Float] pos image slice position
    #   @return [Image, NilClass] the matched image (or nil if no image is matched)
    # @overload image(uid)
    #   @param [String] uid image UID
    #   @return [Image, NilClass] the matched image (or nil if no image is matched)
    # @overload image
    #   @return [Image, NilClass] the first image of this instance (or nil if no child images exists)
    #
    def image(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        if args.first.is_a?(Float)
          # Presumably an image position:
          return image_by_slice_pos(args.first)
        else
          # Presumably a uid string:
          return @associated_images[args.first && args.first.to_s]
        end
      else
        # No argument used, therefore we return the first Image instance:
        return @images.first
      end
    end

    # Builds a 3D dose pixel NArray from the dose images belonging to this
    # DoseVolume. The array has shape [frames, columns, rows] and contains
    # pixel values. To convert to dose values, the array must be multiplied
    # with the scaling attribute.
    #
    # @return [NArray<Float>] a 3D numerical array
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
    # @param [NilClass, #to_f] value the dose grid scaling (3004,000E)
    #
    def scaling=(value)
      @scaling = value && value.to_f
    end

    # Returns self.
    #
    # @return [DoseVolume] self
    #
    def to_dose_volume
      self
    end

=begin
    # Updates the position that is registered for the image for this series.
    #
    # @param [Image] image an image instance to update
    # @param [Float] new_pos the new slice position for the given image
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


    # Returns an image instance matched by the given slice position.
    #
    # @param [Float] pos image slice position
    # @return [Image, NilClass] the matched image (or nil if no image is matched)
    #
    def image_by_slice_pos(pos)
      # Step 1: Try for an (exact) match:
      image = @image_positions[pos.round(2)]
      # Step 2: If no match, try to search for a close match:
      # (A close match is defined as the given slice position being within 1/3 of the
      # slice distance from an existing image instance in the series)
      if !image && @images.length > 1
        proximity = @images.collect{|img| (img.pos_slice - pos).abs}
        if proximity.min < slice_spacing / 3.0
          index = proximity.index(proximity.min)
          image = @images[index]
        end
      end
      return image
    end

    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@images, @scaling, @sop_uid]
    end

  end
end
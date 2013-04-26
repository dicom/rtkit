module RTKIT

  # Contains the DICOM data and methods related to a projection image (e.g. a DRR RTImage, EPID or CR image).
  #
  # === Inheritance
  #
  # * As the ProjectionImage class inherits from the Image class, all Image methods are available to instances of ProjectionImage.
  #
  class ProjectionImage < Image

    # The Beam instance which this projection image is related to.
    attr_reader :beam

    # Creates a new ProjectionImage instance by loading image information from the
    # specified DICOM object. The image object's SOP Instance UID string
    # value is used to uniquely identify an image.
    #
    # @param [DObject] dcm  an instance of a DICOM object
    # @param [Series] series the series instance that this projection image belongs to
    # @return [ProjectionImage] the created ProjectionImage instance
    # @raise [ArgumentError] if the given dicom object doesn't have a projection image type modality
    #
    def self.load(dcm, series)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'series'. Expected Series, got #{series.class}." unless series.is_a?(Series)
      raise ArgumentError, "Invalid argument 'dcm'. Expected an projection image type modality, got #{dcm.value(MODALITY)}." unless PROJECTION_MODALITIES.include?(dcm.value(MODALITY))
      sop_uid = dcm.value(SOP_UID)
      image = self.new(sop_uid, series)
      image.load_pixel_data(dcm)
      return image
    end

    # Creates a new ProjectionImage instance. The SOP Instance UID tag value is
    # used to uniquely identify an image.
    #
    # @param [String] sop_uid the SOP Instance UID of this image
    # @param [Series] series the series instance that this projection image belongs to
    # @param [Hash] options optional parameters to use for ProjectionImage creation
    # @option options [Beam] :beam the beam that this projection image is related to
    # @raise [ArgumentError] if the referenced series doesn't have a slice image type modality
    #
    def initialize(sop_uid, series, options={})
      raise ArgumentError, "Invalid argument 'sop_uid'. Expected String, got #{sop_uid.class}." unless sop_uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'series'. Expected Series, got #{series.class}." unless series.is_a?(Series)
      raise ArgumentError, "Invalid argument 'series'. Expected Series to have a projection image type modality, got #{series.modality}." unless PROJECTION_MODALITIES.include?(series.modality)
      # Key attributes:
      @uid = sop_uid
      @series = series
      # Optional attributes:
      self.beam = options[:beam]
      # Register ourselves with the ImageSeries:
      @series.add_image(self)
    end

    # Sets the beam attribute.
    #
    def beam=(b)
      @beam = b && b.to_beam
    end

    # Transfers the pixel data, as well as the related image properties and the
    # DObject instance itself, to the image instance.
    #
    # @param [DObject] dcm  an instance of a DICOM object
    # @raise [ArgumentError] if the given dicom object doesn't have a projection image type modality
    #
    def load_pixel_data(dcm)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'dcm'. Expected a projection image type modality, got #{dcm.value(MODALITY)}." unless PROJECTION_MODALITIES.include?(dcm.value(MODALITY))
      # Set attributes common for all image modalities, i.e. CT, MR, RTDOSE & RTIMAGE:
      @dcm = dcm
      @narray = dcm.narray
      @date = dcm.value(IMAGE_DATE)
      @time = dcm.value(IMAGE_TIME)
      @columns = dcm.value(COLUMNS)
      @rows = dcm.value(ROWS)
      # Some difference in where we pick our values depending on if we have an
      # RTIMAGE or another type (e.g. CR):
      if @series.modality == 'RTIMAGE'
        image_position = dcm.value(RT_IMAGE_POSITION).split("\\")
        raise "Invalid DICOM image: 2 basckslash-separated values expected for RT Image Position (Patient), got: #{image_position}" unless image_position.length == 2
        @pos_x = image_position[0].to_f
        @pos_y = image_position[1].to_f
        spacing = dcm.value(IMAGE_PLANE_SPACING).split("\\")
        raise "Invalid DICOM image: 2 basckslash-separated values expected for Image Plane Pixel Spacing, got: #{spacing}" unless spacing.length == 2
        @col_spacing = spacing[1].to_f
        @row_spacing = spacing[0].to_f
      else
        image_position = dcm.value(IMAGE_POSITION).split("\\")
        raise "Invalid DICOM image: 3 basckslash-separated values expected for Image Position (Patient), got: #{image_position}" unless image_position.length == 3
        @pos_x = image_position[0].to_f
        @pos_y = image_position[1].to_f
        spacing = dcm.value(SPACING).split("\\")
        raise "Invalid DICOM image: 2 basckslash-separated values expected for Pixel Spacing, got: #{spacing}" unless spacing.length == 2
        @col_spacing = spacing[1].to_f
        @row_spacing = spacing[0].to_f
      end
    end

    # Converts the Image instance to a DICOM object.
    #
    # @note This method uses the original DObject instance, updating it with
    # attributes from the image instance.
    # @return [DObject] a DICOM object
    #
    def to_dcm
      # Use the original DICOM object as a starting point,
      # and update all image related parameters:
      @dcm ||= dicom_scaffold
      @dcm.add_element(IMAGE_DATE, @date || RTKIT.date_str)
      @dcm.add_element(IMAGE_TIME, @time|| RTKIT.time_str)
      @dcm.add_element(SOP_UID, @uid)
      @dcm.add_element(COLUMNS, @columns)
      @dcm.add_element(ROWS, @rows)
      if @series.modality == 'RTIMAGE'
        @dcm.add_element(RT_IMAGE_POSITION, [@pos_x, @pos_y].join("\\"))
        @dcm.add_element(IMAGE_PLANE_SPACING, [@row_spacing, @col_spacing].join("\\"))
      else
        @dcm.add_element(IMAGE_POSITION, [@pos_x, @pos_y].join("\\"))
        @dcm.add_element(SPACING, [@row_spacing, @col_spacing].join("\\"))
      end
      # Write pixel data:
      @dcm.pixels = @narray
      return @dcm
    end

    # Returns self.
    #
    # @return [ProjectionImage] self
    #
    def to_projection_image
      self
    end

    # Sets the pos_x and pos_y attributes based on the image instance attributes.
    #
    def set_positions
      raise "Missing one or more image attributes (Both image dimensions and spacing must be defined)." unless @columns && @rows && @row_spacing && @col_spacing
      if @columns.odd?
        @pos_x = (-@col_spacing * (@columns - 1) / 2).round(2)
      else
        @pos_x = (-@col_spacing * (@columns / 2 - 0.5)).round(2)
      end
      if @rows.odd?
        @pos_y = (@row_spacing * (@rows - 1) / 2).round(2)
      else
        @pos_y = (@row_spacing * (@rows / 2 - 0.5)).round(2)
      end
    end


    private


    # Creates a new DICOM object with a set of basic attributes needed
    # for a valid DICOM file of modality RTIMAGE.
    #
    def dicom_scaffold
      dcm = DICOM::DObject.new
      # Group 0008:
      dcm.add_element(SPECIFIC_CHARACTER_SET, 'ISO_IR 100')
      dcm.add_element(IMAGE_TYPE, 'DERIVED\SECONDARY\DRR')
      dcm.add_element(ACCESSION_NUMBER, '')
      dcm.add_element(MODALITY, 'RTIMAGE')
      dcm.add_element(CONVERSION_TYPE, 'SYN') # or WSD?
      dcm.add_element(MANUFACTURER, 'RTKIT')
      dcm.add_element(TIMEZONE_OFFSET_FROM_UTC, Time.now.strftime('%z'))
      dcm.add_element(MANUFACTURERS_MODEL_NAME, "RTKIT_#{VERSION}")
      # Group 0018:
      dcm.add_element(SOFTWARE_VERSION, "RTKIT_#{VERSION}")
      dcm.add_element(PATIENT_POSITION, @beam.plan.setup ? @beam.plan.setup.position : 'HFS')
      # Group 0020:
      # FIXME: We're missing Instance Number (0020,0013) at the moment.
      # Group 0028:
      dcm.add_element(SAMPLES_PER_PIXEL, '1')
      dcm.add_element(PHOTOMETRIC_INTERPRETATION, 'MONOCHROME2')
      dcm.add_element(BITS_ALLOCATED, 16)
      dcm.add_element(BITS_STORED, 16)
      dcm.add_element(HIGH_BIT, 15)
      dcm.add_element(PIXEL_REPRESENTATION, 0)
      dcm.add_element(WINDOW_CENTER, '2048')
      dcm.add_element(WINDOW_WIDTH, '4096')
      # Group 3002:
      dcm.add_element(RT_IMAGE_LABEL, @beam.description)
      dcm.add_element(RT_IMAGE_NAME, @beam.name)
      dcm.add_element(RT_IMAGE_DESCRIPTION, @beam.plan.name)
      # Note: If support for image plane type 'NON_NORMAL' is added at some
      # point, the RT Image Orientation tag (3002,0010) has to be added as well.
      dcm.add_element(RT_IMAGE_PLANE, 'NORMAL')
      dcm.add_element(X_RAY_IMAGE_RECEPTOR_TRANSLATION, '')
      dcm.add_element(X_RAY_IMAGE_RECEPTOR_ANGLE, '')
      dcm.add_element(RADIATION_MACHINE_NAME, @beam.machine)
      dcm.add_element(RADIATION_MACHINE_SAD, @beam.sad)
      dcm.add_element(RADIATION_MACHINE_SSD, @beam.sad)
      dcm.add_element(RT_IMAGE_SID, @beam.sad)
      # FIXME: Add Exposure sequence as well (with Jaw and MLC position information)
      # Group 300A:
      dcm.add_element(DOSIMETER_UNIT, @beam.unit)
      dcm.add_element(GANTRY_ANGLE, @beam.control_points[0].gantry_angle)
      dcm.add_element(COLL_ANGLE, @beam.control_points[0].collimator_angle)
      dcm.add_element(PEDESTAL_ANGLE, @beam.control_points[0].pedestal_angle)
      dcm.add_element(TABLE_TOP_ANGLE, @beam.control_points[0].table_top_angle)
      dcm.add_element(ISO_POS, @beam.control_points[0].iso.to_s)
      dcm.add_element(GANTRY_PITCH_ANGLE, '0.0')
      # Group 300C:
      s = dcm.add_sequence(REF_PLAN_SQ)
      i = s.add_item
      i.add_element(REF_SOP_CLASS_UID, @beam.plan.class_uid)
      i.add_element(REF_SOP_UID, @beam.plan.sop_uid)
      dcm.add_element(REF_BEAM_NUMBER, @beam.number)
      # Higher level tags (patient, study, frame, series):
      # (Groups 0008, 0010 & 0020)
      @series.add_attributes_to_dcm(dcm)
      dcm
    end


    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
      [@col_spacing, @columns, @date, @narray.to_a, @pos_x, @pos_y,
        @row_spacing, @rows, @time, @uid
      ]
    end

  end
end
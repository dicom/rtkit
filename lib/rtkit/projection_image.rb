module RTKIT

  # Contains the DICOM data and methods related to a projection image (e.g. a
  # DRR RTImage, EPID or CR image).
  #
  # === Inheritance
  #
  # * As the ProjectionImage class inherits from the Image class, all Image
  # methods are available to instances of ProjectionImage.
  #
  class ProjectionImage < Image

    # The Beam instance which this projection image is related to.
    attr_reader :beam

    # Creates a new ProjectionImage instance by loading image information from
    # the specified DICOM object. The image object's SOP Instance UID string
    # value is used to uniquely identify an image.
    #
    # @param [DICOM::DObject] dcm  an instance of a DICOM object
    # @param [Series] series the series instance that this projection image belongs to
    # @return [ProjectionImage] the created ProjectionImage instance
    # @raise [ArgumentError] if the given DICOM object doesn't have a projection image type modality
    #
    def self.load(dcm, series)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'series'. Expected Series, got #{series.class}." unless series.is_a?(Series)
      raise ArgumentError, "Invalid argument 'dcm'. Expected modality 'RTIMAGE', got #{dcm.value(MODALITY)}." unless dcm.value(MODALITY) == 'RTIMAGE'
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
      raise ArgumentError, "Invalid argument 'series'. Expected Series to have modality 'RTIMAGE', got #{series.modality}." unless series.modality == 'RTIMAGE'
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
    # @param [NilClass, #to_beam] value the associated Beam instance of the projection image
    #
    def beam=(value)
      @beam = value && value.to_beam
    end

    # Transfers the pixel data, as well as the related image properties and the
    # DObject instance itself, to the image instance.
    #
    # @param [DICOM::DObject] dcm  an instance of a DICOM object
    # @raise [ArgumentError] if the given dicom object doesn't have a projection image type modality
    #
    def load_pixel_data(dcm)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'dcm'. Expected modality 'RTIMAGE', got #{dcm.value(MODALITY)}." unless dcm.value(MODALITY) == 'RTIMAGE'
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
    # @note This method uses the original DObject instance if present, updating
    #   it with attributes from the image instance.
    # @return [DICOM::DObject] a DICOM object
    #
    def to_dcm
      # Setup general dicom image attributes:
      create_projection_image_dicom_scaffold
      update_dicom_image
      # Add/update tags that are specific for the projection image type:
      @dcm.add_element(RT_IMAGE_POSITION, [@pos_x, @pos_y].join("\\"))
      @dcm.add_element(IMAGE_PLANE_SPACING, [@row_spacing, @col_spacing].join("\\"))
      @dcm
    end

    # Returns self.
    #
    # @return [ProjectionImage] self
    #
    def to_projection_image
      self
    end

    # Sets the pos_x and pos_y attributes based on the image instance
    # attributes.
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
    def create_projection_image_dicom_scaffold
      # Some tags are created/updated only if no DICOM object already exists:
      unless @dcm
        # Setup general image attributes:
        create_general_dicom_image_scaffold
        # Group 3002:
        @dcm.add_element(RT_IMAGE_LABEL, @beam.description)
        @dcm.add_element(RT_IMAGE_NAME, @beam.name)
        @dcm.add_element(RT_IMAGE_DESCRIPTION, @beam.plan.name)
        # Note: If support for image plane type 'NON_NORMAL' is added at some
        # point, the RT Image Orientation tag (3002,0010) has to be added as well.
        @dcm.add_element(RT_IMAGE_PLANE, 'NORMAL')
        @dcm.add_element(X_RAY_IMAGE_RECEPTOR_TRANSLATION, '')
        @dcm.add_element(X_RAY_IMAGE_RECEPTOR_ANGLE, '')
        @dcm.add_element(RADIATION_MACHINE_NAME, @beam.machine)
        @dcm.add_element(RADIATION_MACHINE_SAD, @beam.sad)
        @dcm.add_element(RADIATION_MACHINE_SSD, @beam.sad)
        @dcm.add_element(RT_IMAGE_SID, @beam.sad)
        # FIXME: Add Exposure sequence as well (with Jaw and MLC position information)
        # Group 300A:
        @dcm.add_element(DOSIMETER_UNIT, @beam.unit)
        @dcm.add_element(GANTRY_ANGLE, @beam.control_points[0].gantry_angle)
        @dcm.add_element(COLL_ANGLE, @beam.control_points[0].collimator_angle)
        @dcm.add_element(PEDESTAL_ANGLE, @beam.control_points[0].pedestal_angle)
        @dcm.add_element(TABLE_TOP_ANGLE, @beam.control_points[0].table_top_angle)
        @dcm.add_element(ISO_POS, @beam.control_points[0].iso.to_s)
        @dcm.add_element(GANTRY_PITCH_ANGLE, '0.0')
        # Group 300C:
        s = @dcm.add_sequence(REF_PLAN_SQ)
        i = s.add_item
        i.add_element(REF_SOP_CLASS_UID, @beam.plan.class_uid)
        i.add_element(REF_SOP_UID, @beam.plan.sop_uid)
        @dcm.add_element(REF_BEAM_NUMBER, @beam.number)
      end
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
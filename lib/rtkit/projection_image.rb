module RTKIT

  # Contains the DICOM data and methods related to a projection image (e.g. a DRR RTImage, EPID or CR image).
  #
  # === Inheritance
  #
  # * As the ProjectionImage class inherits from the Image class, all Image methods are available to instances of ProjectionImage.
  #
  class ProjectionImage < Image

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
    # @raise [ArgumentError] if the referenced series doesn't have a slice image type modality
    #
    def initialize(sop_uid, series)
      raise ArgumentError, "Invalid argument 'sop_uid'. Expected String, got #{sop_uid.class}." unless sop_uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'series'. Expected Series, got #{series.class}." unless series.is_a?(Series)
      raise ArgumentError, "Invalid argument 'series'. Expected Series to have a projection image type modality, got #{series.modality}." unless PROJECTION_MODALITIES.include?(series.modality)
      # Key attributes:
      @uid = sop_uid
      @series = series
      # Register ourselves with the ImageSeries:
      @series.add_image(self)
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
      @dcm.add(DICOM::Element.new(IMAGE_DATE, @date))
      @dcm.add(DICOM::Element.new(IMAGE_TIME, @time))
      @dcm.add(DICOM::Element.new(SOP_UID, @uid))
      @dcm.add(DICOM::Element.new(COLUMNS, @columns))
      @dcm.add(DICOM::Element.new(ROWS, @rows))
      if @series.modality == 'RTIMAGE'
        @dcm.add(DICOM::Element.new(RT_IMAGE_POSITION, [@pos_x, @pos_y].join("\\")))
        @dcm.add(DICOM::Element.new(IMAGE_PLANE_SPACING, [@row_spacing, @col_spacing].join("\\")))
      else
        @dcm.add(DICOM::Element.new(IMAGE_POSITION, [@pos_x, @pos_y].join("\\")))
        @dcm.add(DICOM::Element.new(SPACING, [@row_spacing, @col_spacing].join("\\")))
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


    private


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
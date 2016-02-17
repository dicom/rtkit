module RTKIT

  # Contains the DICOM data and methods related to a slice image (plane image).
  #
  # === Inheritance
  #
  # * As the SliceImage class inherits from the Image class, all Image methods
  # are available to instances of SliceImage.
  #
  class SliceImage < Image

    # The values of the Image Orientation (Patient) element.
    attr_reader :cosines
    # The physical position (in millimeters) of the image slice.
    attr_reader :pos_slice

    # Creates a new SliceImage instance by loading image information from the
    # specified DICOM object. The image object's SOP Instance UID string
    # value is used to uniquely identify an image.
    #
    # @param [DICOM::DObject] dcm  an instance of a DICOM object
    # @param [Series] series the series instance that this image slice belongs to
    # @return [SliceImage] the created SliceImage instance
    # @raise [ArgumentError] if the given DICOM object doesn't have a slice image type modality
    #
    def self.load(dcm, series)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'series'. Expected Series, got #{series.class}." unless series.is_a?(Series)
      raise ArgumentError, "Invalid argument 'dcm'. Expected an slice image type modality, got #{dcm.value(MODALITY)}." unless SLICE_MODALITIES.include?(dcm.value(MODALITY))
      # A couple of DICOM attributes are needed for SliceImage initialization:
      sop_uid = dcm.value(SOP_UID)
      image_position = dcm.value(IMAGE_POSITION).split("\\")
      pos_slice = image_position[2].to_f
      image = self.new(sop_uid, pos_slice, series)
      image.load_pixel_data(dcm)
      return image
    end

    # Creates a new SliceImage instance. The SOP Instance UID tag value is
    # used to uniquely identify an image.
    #
    # @param [String] sop_uid the SOP Instance UID value
    # @param [String] pos_slice the slice position of this image
    # @param [Series] series the Series instance which this SliceImage is associated with
    # @raise [ArgumentError] if the referenced series doesn't have a slice image type modality
    #
    def initialize(sop_uid, pos_slice, series)
      raise ArgumentError, "Invalid argument 'sop_uid'. Expected String, got #{sop_uid.class}." unless sop_uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'series'. Expected Series, got #{series.class}." unless series.is_a?(Series)
      raise ArgumentError, "Invalid argument 'series'. Expected Series to have a slice image type modality, got #{series.modality}." unless SLICE_MODALITIES.include?(series.modality)
      # Key attributes:
      @uid = sop_uid
      @pos_slice = pos_slice
      @series = series
      # Register ourselves with the ImageSeries:
      @series.add_image(self)
    end

    # Creates a filled, binary NArray image ('segmented' image) based on the
    # provided contour coordinates.
    #
    # @param [Array, NArray] coords_x the contour's x coordinates
    # @param [Array, NArray] coords_y the contour's y coordinates
    # @param [Array, NArray] coords_z the contour's z coordinates
    # @return [BinImage] a filled, binary image
    # @raise [ArgumentError] if any of the coordinate arrays have less than 3 elements
    #
    def binary_image(coords_x, coords_y, coords_z)
      # FIXME: Should we test whether the coordinates go outside the bounds of this image, and
      # give a descriptive warning/error instead of letting the code crash with a more cryptic error?!
      raise ArgumentError, "Invalid argument 'coords_x'. Expected at least 3 elements, got #{coords_x.length}" unless coords_x.length >= 3
      raise ArgumentError, "Invalid argument 'coords_y'. Expected at least 3 elements, got #{coords_y.length}" unless coords_y.length >= 3
      raise ArgumentError, "Invalid argument 'coords_z'. Expected at least 3 elements, got #{coords_z.length}" unless coords_z.length >= 3
      # Values that will be used for image geometry:
      empty_value = 0
      line_value = 1
      fill_value = 2
      # Convert physical coordinates to image indices:
      column_indices, row_indices = coordinates_to_indices(NArray.to_na(coords_x), NArray.to_na(coords_y), NArray.to_na(coords_z))
      # Create an empty array and fill in the gathered points:
      empty_array = NArray.byte(@columns, @rows)
      delineated_array = draw_lines(column_indices.to_a, row_indices.to_a, empty_array, line_value)
      # Establish starting point indices for the coming flood fill algorithm:
      # (Using a rather simple approach by finding the average column and row index among the selection of indices)
      start_col = column_indices.mean
      start_row = row_indices.mean
      # Perform a flood fill to enable us to extract all pixels contained in a specific ROI:
      filled_array = flood_fill(start_col, start_row, delineated_array, fill_value)
      # Extract the indices of 'ROI pixels':
      if filled_array[0,0] != fill_value
        # ROI has been filled as expected. Extract indices of value line_value and fill_value:
        filled_array[(filled_array.eq line_value).where] = fill_value
        indices = (filled_array.eq fill_value).where
      else
        # An inversion has occured. The entire image except our ROI has been filled. Extract indices of value line_value and empty_value:
        filled_array[(filled_array.eq line_value).where] = empty_value
        indices = (filled_array.eq empty_value).where
      end
      # Create binary image:
      bin_image = NArray.byte(@columns, @rows)
      bin_image[indices] = 1
      return bin_image
    end

    # Sets the cosines attribute.
    #
    # @param [NilClass, Array<#to_f>] values the 6 direction cosines of the first row and first column of the image
    #
    def cosines=(values)
      #raise ArgumentError, "Invalid argument 'values'. Expected 6 elements, got #{values.length}" unless values.length == 6
      @cosines = values && values.to_a.collect! {|val| val.to_f}
    end

    # Transfers the pixel data, as well as the related image properties and the
    # DICOM object itself to the image instance.
    #
    # @param [DICOM::DObject] dcm  an instance of a DICOM object
    # @raise [ArgumentError] if the given dicom object doesn't have a slice image type modality
    #
    def load_pixel_data(dcm)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'dcm'. Expected an image related modality, got #{dcm.value(MODALITY)}." unless SLICE_MODALITIES.include?(dcm.value(MODALITY))
      # Set attributes common for all image modalities, i.e. CT, MR, RTDOSE & RTIMAGE:
      @dcm = dcm
      @narray = dcm.narray
      @date = dcm.value(IMAGE_DATE)
      @time = dcm.value(IMAGE_TIME)
      @columns = dcm.value(COLUMNS)
      @rows = dcm.value(ROWS)
      # Some difference in where we pick our values depending on if we have an RTIMAGE or another type:
      image_position = dcm.value(IMAGE_POSITION).split("\\")
      raise "Invalid DICOM image: 3 basckslash-separated values expected for Image Position (Patient), got: #{image_position}" unless image_position.length == 3
      @pos_x = image_position[0].to_f
      @pos_y = image_position[1].to_f
      spacing = dcm.value(SPACING).split("\\")
      raise "Invalid DICOM image: 2 basckslash-separated values expected for Pixel Spacing, got: #{spacing}" unless spacing.length == 2
      @col_spacing = spacing[1].to_f
      @row_spacing = spacing[0].to_f
      raise "Invalid DICOM image: Direction cosines missing (DICOM tag '#{IMAGE_ORIENTATION}')." unless dcm.exists?(IMAGE_ORIENTATION)
      @cosines = dcm.value(IMAGE_ORIENTATION).split("\\").collect {|val| val.to_f} if dcm.value(IMAGE_ORIENTATION)
      raise "Invalid DICOM image: 6 values expected for direction cosines (DICOM tag '#{IMAGE_ORIENTATION}'), got #{@cosines.length}." unless @cosines.length == 6
    end

    # Sets the pos_slice attribute.
    #
    # @param [NilClass, #to_f] value the slice position of the image
    #
    def pos_slice=(value)
      @series.update_image_position(self, value)
      @pos_slice = value && value.to_f
    end

    # Sets a new pixel value to the given collection of pixels.
    #
    # @note As of yet the image class does not handle presentation values, so
    #   the input value has to be 'raw' values.
    # @param [Array] indices the indices of the pixels to be replaced
    # @param [#to_i] value the pixel replacement value
    #
    def set_pixels(indices, value)
      @narray[indices] = value.to_i
    end

    # Converts the Image instance to a DICOM object.
    #
    # @note This method uses the image's original DICOM object (if present),
    #   and updates it with attributes from the image instance.
    # @return [DICOM::DObject] the processed DICOM object
    #
    def to_dcm
      # Setup general dicom image attributes:
      create_slice_image_dicom_scaffold
      update_dicom_image
      # Add/update tags that are specific for the slice image type:
      @dcm.add_element(IMAGE_POSITION, [@pos_x, @pos_y, @pos_slice].join("\\"))
      @dcm.add_element(SPACING, [@row_spacing, @col_spacing].join("\\"))
      @dcm.add_element(IMAGE_ORIENTATION, [@cosines].join("\\"))
      @dcm
    end

    # Returns self.
    #
    # @return [SliceImage] self
    #
    def to_slice_image
      self
    end


    private


    # Creates a new DICOM object with a set of basic attributes needed
    # for a valid DICOM file of slice type image modality.
    #
    def create_slice_image_dicom_scaffold
      # Some tags are created/updated only if no DICOM object already exists:
      unless @dcm
        # Setup general image attributes:
        create_general_dicom_image_scaffold
        # Group 0018:
        #@dcm.add_element(PATIENT_POSITION, 'HFS')
      end
    end

    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
      [@col_spacing, @columns, @cosines, @date, @narray.to_a, @pos_x, @pos_y,
        @pos_slice, @row_spacing, @rows, @time, @uid
      ]
    end

  end
end
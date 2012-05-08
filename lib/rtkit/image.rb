module RTKIT

  # Contains the DICOM data and methods related to an image.
  #
  # === Inheritance
  #
  # * As the Image class inherits from the PixelData class, all PixelData methods are available to instances of Image.
  #
  class Image < PixelData

    # The physical distance (in millimeters) between columns in the pixel data (i.e. horisontal spacing).
    attr_reader :col_spacing
    # The number of columns in the pixel data.
    attr_reader :columns
    # The values of the Image Orientation (Patient) element.
    attr_reader :cosines
    # The Instance Creation Date.
    attr_reader :date
    # The DICOM object of this Image instance.
    attr_reader :dcm
    # The 2d NArray holding the pixel data of this Image instance.
    attr_reader :narray
    # The physical position (in millimeters) of the image slice.
    attr_reader :pos_slice
    # The physical position (in millimeters) of the first (left) column in the pixel data.
    attr_reader :pos_x
    # The physical position (in millimeters) of the first (top) row in the pixel data.
    attr_reader :pos_y
    # The physical distance (in millimeters) between rows in the pixel data (i.e. vertical spacing).
    attr_reader :row_spacing
    # The number of rows in the pixel data.
    attr_reader :rows
    # The Image's Series (volume) reference.
    attr_reader :series
    # The Instance Creation Time.
    attr_reader :time
    # The SOP Instance UID.
    attr_reader :uid

    # Creates a new Image instance by loading image information from the specified DICOM object.
    # The Image object's SOP Instance UID string value is used to uniquely identify an image.
    #
    # === Parameters
    #
    # * <tt>dcm</tt> -- An instance of a DICOM object (DObject).
    # * <tt>series</tt> -- The Series instance that this Image belongs to.
    #
    def self.load(dcm, series)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'series'. Expected Series, got #{series.class}." unless series.is_a?(Series)
      raise ArgumentError, "Invalid argument 'dcm'. Expected an image related modality, got #{dcm.value(MODALITY)}." unless IMAGE_MODALITIES.include?(dcm.value(MODALITY))
      sop_uid = dcm.value(SOP_UID)
      image = self.new(sop_uid, series)
      image.load_pixel_data(dcm)
      return image
    end

    # Creates a new Image instance. The SOP Instance UID tag value is used to uniquely identify an image.
    #
    # === Parameters
    #
    # * <tt>sop_uid</tt> -- The SOP Instance UID string.
    # * <tt>series</tt> -- The Series instance that this Image belongs to.
    #
    def initialize(sop_uid, series)
      raise ArgumentError, "Invalid argument 'sop_uid'. Expected String, got #{sop_uid.class}." unless sop_uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'series'. Expected Series, got #{series.class}." unless series.is_a?(Series)
      raise ArgumentError, "Invalid argument 'series'. Expected Series to have an image related modality, got #{series.modality}." unless IMAGE_MODALITIES.include?(series.modality)
      # Key attributes:
      @uid = sop_uid
      @series = series
      # Register ourselves with the ImageSeries:
      @series.add_image(self)
    end

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_image)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Creates and returns a filled, binary NArray image (a 'segmented' image) based on the provided contour coordinates.
    #
    # === Parameters
    #
    # * <tt>coords_x</tt> -- An Array/NArray of a contour's X coordinates. Must have at least 3 elements.
    # * <tt>coords_y</tt> -- An Array/NArray of a contour's Y coordinates. Must have at least 3 elements.
    # * <tt>coords_z</tt> -- An Array/NArray of a contour's Z coordinates. Must have at least 3 elements.
    #
    def binary_image(coords_x, coords_y, coords_z)
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

    # Sets the col_spacing attribute.
    #
    def col_spacing=(space)
      @col_spacing = space && space.to_f
    end

    # Sets the columns attribute.
    #
    def columns=(cols)
      #raise ArgumentError, "Invalid argument 'cols'. Expected a positive integer, got #{cols}" unless cols > 0
      @columns = cols && cols.to_i
    end

    # Sets the cosines attribute.
    #
    def cosines=(cos)
      #raise ArgumentError, "Invalid argument 'cos'. Expected 6 elements, got #{cos.length}" unless cos.length == 6
      @cosines = cos && cos.to_a.collect! {|val| val.to_f}
    end

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Transfers the pixel data, as well as the related image properties and the DObject instance itself,
    # to the Image instance.
    #
    # === Parameters
    #
    # * <tt>dcm</tt> -- A DICOM object containing image data that will be applied to the Image instance.
    #
    def load_pixel_data(dcm)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'dcm'. Expected an image related modality, got #{dcm.value(MODALITY)}." unless IMAGE_MODALITIES.include?(dcm.value(MODALITY))
      # Set attributes common for all image modalities, i.e. CT, MR, RTDOSE & RTIMAGE:
      @dcm = dcm
      @narray = dcm.narray
      @date = dcm.value(IMAGE_DATE)
      @time = dcm.value(IMAGE_TIME)
      @uid = dcm.value(SOP_UID)
      @columns = dcm.value(COLUMNS)
      @rows = dcm.value(ROWS)
      # Some difference in where we pick our values depending on if we have an RTIMAGE or another type:
      if @series.modality == 'RTIMAGE'
        image_position = dcm.value(RT_IMAGE_POSITION).split("\\")
        raise "Invalid DICOM image: 2 basckslash-separated values expected for RT Image Position (Patient), got: #{image_position}" unless image_position.length == 2
        @pos_x = image_position[0].to_f
        @pos_y = image_position[1].to_f
        @pos_slice = nil
        spacing = dcm.value(IMAGE_PLANE_SPACING).split("\\")
        raise "Invalid DICOM image: 2 basckslash-separated values expected for Image Plane Pixel Spacing, got: #{spacing}" unless spacing.length == 2
        @col_spacing = spacing[1].to_f
        @row_spacing = spacing[0].to_f
      else
        image_position = dcm.value(IMAGE_POSITION).split("\\")
        raise "Invalid DICOM image: 3 basckslash-separated values expected for Image Position (Patient), got: #{image_position}" unless image_position.length == 3
        @pos_x = image_position[0].to_f
        @pos_y = image_position[1].to_f
        self.pos_slice = image_position[2].to_f
        spacing = dcm.value(SPACING).split("\\")
        raise "Invalid DICOM image: 2 basckslash-separated values expected for Pixel Spacing, got: #{spacing}" unless spacing.length == 2
        @col_spacing = spacing[1].to_f
        @row_spacing = spacing[0].to_f
        raise "Invalid DICOM image: Direction cosines missing (DICOM tag '#{IMAGE_ORIENTATION}')." unless dcm.exists?(IMAGE_ORIENTATION)
        @cosines = dcm.value(IMAGE_ORIENTATION).split("\\").collect {|val| val.to_f} if dcm.value(IMAGE_ORIENTATION)
        raise "Invalid DICOM image: 6 values expected for direction cosines (DICOM tag '#{IMAGE_ORIENTATION}'), got #{@cosines.length}." unless @cosines.length == 6
      end
    end

    # Sets the pixels attribute (as well as the columns
    # and rows attributes - derived from the pixel array - not ATM!!!).
    #
    def narray=(narr)
      raise ArgumentError, "Invalid argument 'narray'. Expected NArray, got #{narr.class}" unless narr.is_a?(NArray)
      raise ArgumentError, "Invalid argument 'narray'. Expected two-dimensional NArray matching @columns & @rows [#{@columns}, #{@rows}], got #{narr.shape}" unless narr.shape == [@columns, @rows]
      @narray = narr
    end

    # Calculates the area of a single pixel of this image.
    # Returns a float value, in units of millimeters squared.
    #
    def pixel_area
      return @row_spacing * @col_spacing
    end

    # Extracts pixel values from the image based on the given indices.
    #
    def pixel_values(selection)
      raise ArgumentError, "Invalid argument 'selection'. Expected Selection, got #{selection.class}" unless selection.is_a?(Selection)
      return @narray[selection.indices]
    end

    # Sets the pos_slice attribute.
    #
    def pos_slice=(pos)
      @series.update_image_position(self, pos)
      @pos_slice = pos && pos.to_f
    end

    # Sets the pos_x attribute.
    #
    def pos_x=(pos)
      @pos_x = pos && pos.to_f
    end

    # Sets the pos_y attribute.
    #
    def pos_y=(pos)
      @pos_y = pos && pos.to_f
    end

    # Sets the row_spacing attribute.
    #
    def row_spacing=(space)
      @row_spacing = space && space.to_f
    end

    # Sets the rows attribute.
    #
    def rows=(rows)
      #raise ArgumentError, "Invalid argument 'rows'. Expected a positive integer, got #{rows}" unless rows.to_i > 0
      @rows = rows && rows.to_i
    end

    # Sets the resolution of the image. This modifies the pixel data
    # (in the specified way) and the column/row attributes as well.
    # The image will either be expanded or cropped depending on whether
    # the specified resolution is bigger or smaller than the existing one.
    #
    # === Parameters
    #
    # * <tt>columns</tt> -- Integer. The number of columns applied to the cropped/expanded image.
    # * <tt>rows</tt> -- Integer. The number of rows applied to the cropped/expanded image.
    #
    # === Options
    #
    # * <tt>:hor</tt> -- Symbol. The side (in the horisontal image direction) to apply the crop/border (:left, :right or :even (default)).
    # * <tt>:ver</tt> -- Symbol. The side (in the vertical image direction) to apply the crop/border (:bottom, :top or :even (default)).
    #
    def set_resolution(columns, rows, options={})
      options[:hor] = :even unless options[:hor]
      options[:ver] = :even unless options[:ver]
      old_cols = @narray.shape[0]
      old_rows = @narray.shape[1]
      if @narray
        # Modify the width only if changed:
        if columns != old_cols
          self.columns = columns.to_i
          old_arr = @narray.dup
          @narray = NArray.int(@columns, @rows)
          if @columns > old_cols
            # New array is larger:
            case options[:hor]
            when :left then @narray[(@columns-old_cols)..(@columns-1), true] = old_arr
            when :right then @narray[0..(old_cols-1), true] = old_arr
            when :even then @narray[((@columns-old_cols)/2+(@columns-old_cols).remainder(2))..(@columns-1-(@columns-old_cols)/2), true] = old_arr
            end
          else
            # New array is smaller:
            case options[:hor]
            when :left then @narray = old_arr[(old_cols-@columns)..(old_cols-1), true]
            when :right then @narray = old_arr[0..(@columns-1), true]
            when :even then @narray = old_arr[((old_cols-@columns)/2+(old_cols-@columns).remainder(2))..(old_cols-1-(old_cols-@columns)/2), true]
            end
          end
        end
        # Modify the height only if changed:
        if rows != old_rows
          self.rows = rows.to_i
          old_arr = @narray.dup
          @narray = NArray.int(@columns, @rows)
          if @rows > old_rows
            # New array is larger:
            case options[:ver]
            when :top then @narray[true, (@rows-old_rows)..(@rows-1)] = old_arr
            when :bottom then @narray[true, 0..(old_rows-1)] = old_arr
            when :even then @narray[true, ((@rows-old_rows)/2+(@rows-old_rows).remainder(2))..(@rows-1-(@rows-old_rows)/2)] = old_arr
            end
          else
            # New array is smaller:
            case options[:ver]
            when :top then @narray = old_arr[true, (old_rows-@rows)..(old_rows-1)]
            when :bottom then @narray = old_arr[true, 0..(@rows-1)]
            when :even then @narray = old_arr[true, ((old_rows-@rows)/2+(old_rows-@rows).remainder(2))..(old_rows-1-(old_rows-@rows)/2)]
            end
          end
        end
      end
    end

    # Dumps the Image instance to a DObject.
    # This overwrites the dcm instance attribute.
    # Returns the DObject instance.
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
        @dcm.add(DICOM::Element.new(IMAGE_POSITION, [@pos_x, @pos_y, @pos_slice].join("\\")))
        @dcm.add(DICOM::Element.new(SPACING, [@row_spacing, @col_spacing].join("\\")))
        @dcm.add(DICOM::Element.new(IMAGE_ORIENTATION, [@cosines].join("\\")))
      end
      # Write pixel data:
      @dcm.pixels = @narray
      return @dcm
    end

    # Returns self.
    #
    def to_image
      self
    end

    # Writes the Image to a DICOM file given by the specified file string.
    #
    def write(file_name)
      to_dcm
      @dcm.write(file_name)
    end


    private


    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@col_spacing, @columns, @cosines, @date, @narray.to_a, @pos_x, @pos_y,
        @pos_slice, @row_spacing, @rows, @time, @uid
       ]
    end

  end
end
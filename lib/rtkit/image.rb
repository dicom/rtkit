module RTKIT

  # A collection of methods and attributes for handling 2D pixel data.
  #
  class Image

    # The physical distance (in millimeters) between columns in the pixel data (i.e. horisontal spacing).
    attr_reader :col_spacing
    # The number of columns in the pixel data.
    attr_reader :columns
    # The Instance Creation Date.
    attr_reader :date
    # The DICOM object of this Image instance.
    attr_reader :dcm
    # The 2d NArray holding the pixel data of this Image instance.
    attr_reader :narray
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

    # Creates a new Image instance by loading image information from the
    # specified DICOM object. The image object's SOP Instance UID string
    # value is used to uniquely identify an image.
    #
    # @param [DICOM::DObject] dcm  an instance of a DICOM object
    # @param [Series] series the series instance that this image belongs to
    # @return [Image] the created Image instance
    # @raise [ArgumentError] if the given DICOM object doesn't have modality 'CR'
    #
    def self.load(dcm, series)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'series'. Expected Series, got #{series.class}." unless series.is_a?(Series)
      raise ArgumentError, "Invalid argument 'dcm'. Expected an image of modality 'CR', got #{dcm.value(MODALITY)}." unless dcm.value(MODALITY) == 'CR'
      # A couple of DICOM attributes are needed for SliceImage initialization:
      sop_uid = dcm.value(SOP_UID)
      image = self.new(sop_uid, series)
      image.load_pixel_data(dcm)
      return image
    end

    # Creates a new Image instance. The SOP Instance UID tag value is
    # used to uniquely identify an image.
    #
    # @param [String] sop_uid the SOP Instance UID value
    # @param [Series] series the Series instance which this Image is associated with
    # @raise [ArgumentError] if the referenced series doesn't have modality 'CR'
    #
    def initialize(sop_uid, series)
      raise ArgumentError, "Invalid argument 'sop_uid'. Expected String, got #{sop_uid.class}." unless sop_uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'series'. Expected Series, got #{series.class}." unless series.is_a?(Series)
      raise ArgumentError, "Invalid argument 'series'. Expected Series to have modality 'CR', got #{series.modality}." unless series.modality == 'CR'
      # Key attributes:
      @uid = sop_uid
      @series = series
      # Register ourselves with the Series:
      @series.add_image(self)
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
      if other.respond_to?(:to_image)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Sets the col_spacing attribute.
    #
    # @param [NilClass, #to_f] value the distance between column centers (0028,0030)
    #
    def col_spacing=(value)
      @col_spacing = value && value.to_f
    end

    # Sets the columns attribute.
    #
    # @param [NilClass, #to_i] value the number of columns in the image (0028,0011)
    #
    def columns=(value)
      #raise ArgumentError, "Invalid argument 'value'. Expected a positive integer, got #{value}" unless value > 0
      @columns = value && value.to_i
    end

    # Converts from two NArrays of image X & Y indices to physical coordinates
    # X, Y & Z (in mm). The X, Y & Z coordinates are returned in three NArrays
    # of equal size as the input index NArrays. The image coordinates are
    # calculated using the direction cosines of the Image Orientation (Patient)
    # element (0020,0037).
    #
    # @see For details about Image orientation, refer to the DICOM standard: PS 3.3 C.7.6.2.1.1
    # @param [NArray] column_indices a numerical array (vector) of pixel column indices
    # @param [NArray] row_indices a numerical array (vector) of pixel row indices
    # @raise if one of the several image attributes necessary for coordinate calculation is invalid or missing
    # @return [Array<NArray>] x, y, & z coordinate numerical array vectors
    #
    def coordinates_from_indices(column_indices, row_indices)
      raise ArgumentError, "Invalid argument 'column_indices'. Expected NArray, got #{column_indices.class}." unless column_indices.is_a?(NArray)
      raise ArgumentError, "Invalid argument 'row_indices'. Expected NArray, got #{row_indices.class}." unless row_indices.is_a?(NArray)
      raise ArgumentError, "Invalid arguments. Expected NArrays of equal length, got #{column_indices.length} and #{row_indices.length}." unless column_indices.length == row_indices.length
      raise "Invalid attribute 'cosines'. Expected a 6 element Array, got #{cosines.class} #{cosines.length if cosines.is_a?(Array)}." unless cosines.is_a?(Array) && cosines.length == 6
      raise "Invalid attribute 'pos_x'. Expected Float, got #{pos_x.class}." unless pos_x.is_a?(Float)
      raise "Invalid attribute 'pos_y'. Expected Float, got #{pos_y.class}." unless pos_y.is_a?(Float)
      raise "Invalid attribute 'pos_slice'. Expected Float, got #{pos_slice.class}." unless pos_slice.is_a?(Float)
      raise "Invalid attribute 'col_spacing'. Expected Float, got #{col_spacing.class}." unless col_spacing.is_a?(Float)
      raise "Invalid attribute 'row_spacing'. Expected Float, got #{row_spacing.class}." unless row_spacing.is_a?(Float)
      # Convert indices integers to floats:
      column_indices = column_indices.to_f
      row_indices = row_indices.to_f
      # Calculate the coordinates by multiplying indices with the direction cosines and applying the image offset:
      x = pos_x + (column_indices * col_spacing * cosines[0]) + (row_indices * row_spacing * cosines[3])
      y = pos_y + (column_indices * col_spacing * cosines[1]) + (row_indices * row_spacing * cosines[4])
      z = pos_slice + (column_indices * col_spacing * cosines[2]) + (row_indices * row_spacing * cosines[5])
      return x, y, z
    end

    # Converts from three (float) NArrays of X, Y & Z physical coordinates
    # (in mm) to image column and row indices. The column and row indices are
    # returned in two NArrays of equal size as the input coordinate NArrays.
    # The pixel indices are calculated using the direction cosines of the Image
    # Orientation (Patient) element (0020,0037).
    #
    # @see For details about Image orientation, refer to the DICOM standard: PS 3.3 C.7.6.2.1.1
    # @param [NArray] x a numerical array (vector) of pixel coordinates
    # @param [NArray] y a numerical array (vector) of pixel coordinates
    # @param [NArray] z a numerical array (vector) of pixel coordinates
    # @raise if one of the several image attributes necessary for index calculation is invalid or missing
    # @return [Array<NArray>] column & row index numerical array vectors
    #
    def coordinates_to_indices(x, y, z)
      raise ArgumentError, "Invalid argument 'x'. Expected NArray, got #{x.class}." unless x.is_a?(NArray)
      raise ArgumentError, "Invalid argument 'y'. Expected NArray, got #{y.class}." unless y.is_a?(NArray)
      raise ArgumentError, "Invalid argument 'z'. Expected NArray, got #{z.class}." unless z.is_a?(NArray)
      raise ArgumentError, "Invalid arguments. Expected NArrays of equal length, got #{x.length}, #{y.length} and #{z.length}." unless [x.length, y.length, z.length].uniq.length == 1
      raise "Invalid attribute 'cosines'. Expected a 6 element Array, got #{cosines.class} #{cosines.length if cosines.is_a?(Array)}." unless cosines.is_a?(Array) && cosines.length == 6
      raise "Invalid attribute 'pos_x'. Expected Float, got #{pos_x.class}." unless pos_x.is_a?(Float)
      raise "Invalid attribute 'pos_y'. Expected Float, got #{pos_y.class}." unless pos_y.is_a?(Float)
      raise "Invalid attribute 'pos_slice'. Expected Float, got #{pos_slice.class}." unless pos_slice.is_a?(Float)
      raise "Invalid attribute 'col_spacing'. Expected Float, got #{col_spacing.class}." unless col_spacing.is_a?(Float)
      raise "Invalid attribute 'row_spacing'. Expected Float, got #{row_spacing.class}." unless row_spacing.is_a?(Float)
      # Calculate the indices by multiplying coordinates with the direction cosines and applying the image offset:
      column_indices = ((x-pos_x)/col_spacing*cosines[0] + (y-pos_y)/col_spacing*cosines[1] + (z-pos_slice)/col_spacing*cosines[2]).round
      row_indices = ((x-pos_x)/row_spacing*cosines[3] + (y-pos_y)/row_spacing*cosines[4] + (z-pos_slice)/row_spacing*cosines[5]).round
      return column_indices, row_indices
    end

    # Fills the provided pixel array with lines of a specified value, based on
    # two vectors of column and row indices.
    #
    # @param [Array] column_indices an array (vector) of pixel column indices
    # @param [Array] row_indices an array (vector) of pixel row indices
    # @param [NArray] image a two-dimensional numerical pixel array
    # @param [Integer] value the value used for marking pixel lines
    # @raise if there are any discrepancies among the provided image parameters
    # @return [NArray] a pixel array marked with lines
    #
    def draw_lines(column_indices, row_indices, image, value)
      raise ArgumentError, "Invalid argument 'column_indices'. Expected Array, got #{column_indices.class}." unless column_indices.is_a?(Array)
      raise ArgumentError, "Invalid argument 'row_indices'. Expected Array, got #{row_indices.class}." unless row_indices.is_a?(Array)
      raise ArgumentError, "Invalid arguments. Expected Arrays of equal length, got #{column_indices.length}, #{row_indices.length}." unless column_indices.length == row_indices.length
      raise ArgumentError, "Invalid argument 'image'. Expected NArray, got #{image.class}." unless image.is_a?(NArray)
      raise ArgumentError, "Invalid number of dimensions for argument 'image'. Expected 2, got #{image.shape.length}." unless image.shape.length == 2
      raise ArgumentError, "Invalid argument 'value'. Expected Integer, got #{value.class}." unless value.is_a?(Integer)
      column_indices.each_index do |i|
        image = draw_line(column_indices[i-1], column_indices[i], row_indices[i-1], row_indices[i], image, value)
      end
      return image
    end

    # Extracts pixels based on cartesian coordinate arrays.
    #
    # @note No interpolation is performed in the case of a given coordinate
    #   being located between pixel indices. In these cases a basic nearest
    #   neighbour algorithm is used.
    #
    # @param [NArray] x_coords a numerical array (vector) of pixel x coordinates
    # @param [NArray] y_coords a numerical array (vector) of pixel y coordinates
    # @param [NArray] z_coords a numerical array (vector) of pixel z coordinates
    # @return [Array] the matched pixel values
    #
    def extract_pixels(x_coords, y_coords, z_coords)
      # FIXME: This method (along with some other methods in this class, doesn't
      # actually work for a pure Image instance. This should probably be
      # refactored (mix-in module instead more appropriate?)
      # Get image indices (nearest neighbour):
      column_indices, row_indices = coordinates_to_indices(x_coords, y_coords, z_coords)
      # Convert from vector indices to array indices:
      indices = indices_specific_to_general(column_indices, row_indices)
      # Use the determined image indices to extract corresponding pixel values:
      return @narray[indices].to_a.flatten
    end

    # Replaces all pixels of a specific value that are contained by pixels of
    # a different value.
    #
    # Uses an iterative, queue based flood fill algorithm. It seems that a
    # recursive method is not suited for Ruby, due to its limited stack space
    # (which is known to be a problem in general for scripting languages).
    #
    # @param [Integer] col the starting column index
    # @param [Integer] row the starting row index
    # @param [NArray] image a two-dimensional numerical pixel array
    # @param [Integer] fill_value the value used for marking pixels
    # @return [NArray] a marked pixel array
    #
    def flood_fill(col, row, image, fill_value)
      # If the given starting point is out of bounds, put it at the array boundary:
      col = col > image.shape[0] ? -1 : col
      row = row > image.shape[1] ? -1 : row
      existing_value = image[col, row]
      queue = Array.new
      queue.push([col, row])
      until queue.empty?
        col, row = queue.shift
        if image[col, row] == existing_value
          west_col, west_row = ff_find_border(col, row, existing_value, :west, image)
          east_col, east_row = ff_find_border(col, row, existing_value, :east, image)
          # Fill the line between the two border pixels (i.e. not touching the border pixels):
          image[west_col..east_col, row] = fill_value
          q = west_col
          while q <= east_col
            [:north, :south].each do |direction|
              same_col, next_row = ff_neighbour(q, row, direction)
              begin
                queue.push([q, next_row]) if image[q, next_row] == existing_value
              rescue
                # Out of bounds. Do nothing.
              end
            end
            q, same_row = ff_neighbour(q, row, :east)
          end
        end
      end
      return image
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

    # Converts general image indices to specific column and row indices based
    # on the geometry of the image (the number of columns).
    #
    # @param [NArray, Array] indices general pixel array indices
    # @param [Integer] columns the number of columns in the image array
    # @return [Array<NArray, Array>] column & row indices
    #
    def indices_general_to_specific(indices, columns=@columns)
      if indices.is_a?(Array)
        row_indices = indices.collect {|i| i / columns}
        column_indices = [indices, row_indices].transpose.collect{|i| i[0] - i[1] * columns}
      else
        # Assume Fixnum or NArray:
        row_indices = indices / columns # Values are automatically rounded down.
        column_indices = indices - row_indices * columns
      end
      return column_indices, row_indices
    end

    # Converts specific x and y indices to general image indices based on the
    # the geometry of the image (the number of columns).
    #
    # @param [NArray, Array] column_indices specific pixel array column indices
    # @param [NArray, Array] row_indices specific pixel array row indices
    # @param [Integer] n_cols the number of columns in the reference image
    # @return [NArray, Array] general pixel array indices
    #
    def indices_specific_to_general(column_indices, row_indices, columns=@columns)
      if column_indices.is_a?(Array)
        indices = Array.new
        column_indices.each_index {|i| indices << column_indices[i] + row_indices[i] * columns}
        return indices
      else
        # Assume Fixnum or NArray:
        return column_indices + row_indices * columns
      end
    end

    # Inserts foreign pixel values to the pixel data of this image instance.
    #
    # @param [NArray, Array] indices general pixel array indices
    # @param [NArray, Array] values pixel values to be inserted
    #
    def insert_pixels(indices, values)
      @narray[indices] = values
    end

    # Transfers the pixel data, as well as the related image properties and the
    # DICOM object itself to the image instance.
    #
    # @param [DICOM::DObject] dcm  an instance of a DICOM object
    # @raise [ArgumentError] if the given dicom object doesn't have modality 'CR'
    #
    def load_pixel_data(dcm)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'dcm'. Expected modality 'CR', got #{dcm.value(MODALITY)}." unless dcm.value(MODALITY) == 'CR'
      # Set attributes common for all image modalities, i.e. CT, MR, RTDOSE & RTIMAGE:
      @dcm = dcm
      @narray = dcm.narray
      @date = dcm.value(IMAGE_DATE)
      @time = dcm.value(IMAGE_TIME)
      @columns = dcm.value(COLUMNS)
      @rows = dcm.value(ROWS)
      spacing = dcm.value(SPACING).split("\\")
      raise "Invalid DICOM image: 2 basckslash-separated values expected for Pixel Spacing, got: #{spacing}" unless spacing.length == 2
      @col_spacing = spacing[1].to_f
      @row_spacing = spacing[0].to_f
    end

    # Sets the pixel data ('narray' attribute).
    #
    # @note The provided pixel array's dimensions must correspond with the
    #   column and row attributes of the image instance.
    #
    # @param [NArray] narr a two-dimensional numerical pixel array
    # @raise [ArgumentError] if the dimensions of the given array doesn't match the properties of the image instance
    #
    def narray=(narr)
      raise ArgumentError, "Invalid argument 'narray'. Expected NArray, got #{narr.class}" unless narr.is_a?(NArray)
      raise ArgumentError, "Invalid argument 'narray'. Expected two-dimensional NArray matching @columns & @rows [#{@columns}, #{@rows}], got #{narr.shape}" unless narr.shape == [@columns, @rows]
      @narray = narr
    end

    # Calculates the area of a single pixel of this image.
    #
    # @return [Float] the calculated pixel area (in units of square millimeters)
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

    # A convenience method for printing image information.
    #
    # @deprecated NB! This has been used only for debugging, and will soon be removed.
    # @param [NArray] narr a numerical array
    #
    def print_img(narr=@narray)
      puts "Image dimensions: #{@columns}*#{@rows}"
      narr.shape[0].times do |i|
        puts narr[true, i].to_a.to_s
      end
    end

    # Sets the pos_x attribute.
    #
    # @param [NilClass, #to_f] value the image position (patient) x coordinate (0020,0032)
    #
    def pos_x=(value)
      @pos_x = value && value.to_f
    end

    # Sets the pos_y attribute.
    #
    # @param [NilClass, #to_f] value the image position (patient) y coordinate (0020,0032)
    #
    def pos_y=(value)
      @pos_y = value && value.to_f
    end

    # Sets the row_spacing attribute.
    #
    # @param [NilClass, #to_f] value the distance between row centers (0028,0030)
    #
    def row_spacing=(value)
      @row_spacing = value && value.to_f
    end

    # Sets the rows attribute.
    #
    # @param [NilClass, #to_i] value the number of rows in the image (0028,0010)
    #
    def rows=(value)
      #raise ArgumentError, "Invalid argument 'rows'. Expected a positive integer, got #{rows}" unless rows.to_i > 0
      @rows = value && value.to_i
    end

    # Sets the resolution of the image. This modifies both the pixel data
    # (in the specified way) as well as the column & row attributes. The image
    # will either be expanded or cropped depending on whether the specified
    # resolution is bigger or smaller than the existing one.
    #
    # @param [Integer] columns the number of columns in the resized image
    # @param [Integer] rows the number of rows in the resized image
    # @param [Hash] options the options to use for changing the image resolution
    # @option options [Float] :hor the side (in the horisontal image direction) at which to apply the crop/border operation (:left, :right or :even (default))
    # @option options [Float] :ver the side (in the vertical image direction) at which to apply the crop/border operation (:bottom, :top or :even (default))
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

    # Converts the Image instance to a DICOM object.
    #
    # @note This method uses the image's original DICOM object (if present),
    #   and updates it with attributes from the image instance.
    # @return [DICOM::DObject] the processed DICOM object
    #
    def to_dcm
      # Setup the general attributes that are common for all image types:
      create_general_dicom_image_scaffold
      update_dicom_image
      # Add/update tags that are not common for all image types:
      @dcm.add_element(SPACING, [@row_spacing, @col_spacing].join("\\"))
      @dcm
    end

    # Returns self.
    #
    # @return [DoseVolume] self
    #
    def to_image
      self
    end


    private


    # Creates a new DICOM object with a set of basic attributes needed
    # for a valid DICOM image file.
    #
    def create_general_dicom_image_scaffold
      # Some tags are created/updated only if no DICOM object already exists:
      unless @dcm
        @dcm = DICOM::DObject.new
        # Group 0008:
        @dcm.add_element(SPECIFIC_CHARACTER_SET, 'ISO_IR 100')
        @dcm.add_element(IMAGE_TYPE, 'DERIVED\SECONDARY\DRR')
        @dcm.add_element(ACCESSION_NUMBER, '')
        @dcm.add_element(MODALITY, @series.modality)
        @dcm.add_element(CONVERSION_TYPE, 'SYN') # or WSD?
        @dcm.add_element(MANUFACTURER, 'RTKIT')
        @dcm.add_element(TIMEZONE_OFFSET_FROM_UTC, Time.now.strftime('%z'))
        @dcm.add_element(MANUFACTURERS_MODEL_NAME, "RTKIT_#{VERSION}")
        # Group 0018:
        @dcm.add_element(SOFTWARE_VERSION, "RTKIT_#{VERSION}")
        # Group 0020:
        # FIXME: We're missing Instance Number (0020,0013) at the moment.
        # Group 0028:
        @dcm.add_element(SAMPLES_PER_PIXEL, '1')
        @dcm.add_element(PHOTOMETRIC_INTERPRETATION, 'MONOCHROME2')
        @dcm.add_element(BITS_ALLOCATED, 16)
        @dcm.add_element(BITS_STORED, 16)
        @dcm.add_element(HIGH_BIT, 15)
        @dcm.add_element(PIXEL_REPRESENTATION, 0)
        @dcm.add_element(WINDOW_CENTER, '2048')
        @dcm.add_element(WINDOW_WIDTH, '4096')
      end
    end

    # Draws a single line in the (NArray) image matrix based on a start- and
    # an end-point. The method uses an iterative Bresenham Line Algorithm.
    # Returns the processed image array.
    #
    # @param [Array] x0 the column index of the starting point
    # @param [Array] x1 the column index of the end point
    # @param [Array] y0 the row index of the starting point
    # @param [Array] y1 the row index of the end point
    # @param [NArray] image a two-dimensional numerical pixel array
    # @param [Integer] value the value used for marking the pixel line
    # @return [NArray] a pixel array marked with the single line
    #
    def draw_line(x0, x1, y0, y1, image, value)
      steep = ((y1-y0).abs) > ((x1-x0).abs)
      if steep
        x0,y0 = y0,x0
        x1,y1 = y1,x1
      end
      if x0 > x1
        x0,x1 = x1,x0
        y0,y1 = y1,y0
      end
      deltax = x1-x0
      deltay = (y1-y0).abs
      error = (deltax / 2).to_i
      y = y0
      ystep = nil
      if y0 < y1
        ystep = 1
      else
        ystep = -1
      end
      for x in x0..x1
        if steep
          begin
            image[y,x] = value # (switching variables)
          rescue
            # Our line has gone outside the image. Do nothing for now, but the proper thing to do would be to at least return some status boolean indicating that this has occured.
          end
        else
          begin
            image[x,y] = value
          rescue
            # Our line has gone outside the image.
          end
        end
        error -= deltay
        if error < 0
          y += ystep
          error += deltax
        end
      end
      return image
    end

    # Searches left and right to find the 'border' in a row of pixels in the
    # image array. This private method is used by the flood_fill() method.
    #
    # @param [Integer] col the column index of the origin
    # @param [Integer] row the row index of the origin
    # @param [Integer] existing_value the value of the pixels we want to find a border for (i.e. we are searching for the occurance of a value other than this particular one)
    # @param [Symbol] direction the direction of travel (:east, :west, :north, :south)
    # @param [NArray] image a two-dimensional numerical pixel array
    # @return [Array<Integer>] column and row pixel indices
    #
    def ff_find_border(col, row, existing_value, direction, image)
      next_col, next_row = ff_neighbour(col, row, direction)
      begin
        while image[next_col, next_row] == existing_value
          col, row = next_col, next_row
          next_col, next_row = ff_neighbour(col, row, direction)
        end
      rescue
        # Out of bounds. Do nothing.
      end
      col = 0 if col < 1
      row = 0 if row < 1
      return col, row
    end

    # Gives the neighbour column and row indices based on a specified origin
    # point and a direction of travel. This private method is used by
    # flood_fill() and its dependency; ff_find_border()
    # :east => to the right when looking at an array image printout on the screen
    #
    # @param [Integer] col the column index of the origin
    # @param [Integer] row the row index of the origin
    # @param [Symbol] direction the direction of travel (:east, :west, :north, :south)
    # @return [Array<Integer>] column and row pixel indices
    #
    def ff_neighbour(col, row, direction)
      case direction
        when :north then return col, row-1
        when :south then return col, row+1
        when :east  then return col+1, row
        when :west  then return col-1, row
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

    # Creates a new DICOM object with a set of basic attributes needed
    # for a valid DICOM file of slice type image modality.
    #
    def update_dicom_image
      # General image attributes:
      @dcm.add_element(IMAGE_DATE, @date)
      @dcm.add_element(IMAGE_TIME, @time)
      @dcm.add_element(SOP_UID, @uid)
      @dcm.add_element(COLUMNS, @columns)
      @dcm.add_element(ROWS, @rows)
      # Pixel data:
      @dcm.pixels = @narray
      # Higher level tags (patient, study, frame, series):
      # (Groups 0008, 0010 & 0020)
      @series.add_attributes_to_dcm(dcm)
    end

  end

end
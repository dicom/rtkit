module RTKIT

  # A PixelSpace is an extension of a 2D NArray with some extra
  # attributes to describe its geometrical properties in a coordinate system.
  #
  class PixelSpace < NArray

    # An array of 6 direction cosines which describes the orientation of the
    # image (relationship between pixel indices and x,y,z coordinates).
    attr_accessor :cosines
    # Distance between pixel columns (Float value in units of mm).
    attr_reader :delta_col
    # Distance between pixel rows (Float value in units of mm).
    attr_reader :delta_row
    # The number of columns in the pixel array (Integer).
    attr_reader :columns
    # The number of rows in the pixel array (Integer).
    attr_reader :rows
    # Coordinate (corner position) of the pixel space (with Float values in units of mm).
    attr_reader :pos

    alias_method :nx, :columns
    alias_method :ny, :rows
    alias_method :delta_x, :delta_col
    alias_method :delta_y, :delta_row

    # Creates a PixelSpace instance with the given set of geometrical properties.
    #
    # @param [Integer] columns the number of columns (nx)
    # @param [Integer] rows the number of rows (ny)
    # @param [Float] delta_col the distance between pixel columns
    # @param [Float] delta_row the distance between pixel rows
    # @param [Coordinate] pos the position of the corner of the pixel space
    # @param [Array<Float>] cosines an array of 6 direction cosines
    # @return [PixelSpace] the created PixelSpace instance
    #
    def self.create(columns, rows, delta_col, delta_row, pos, cosines)
      # We choose to initalize as an NArray with type signed integer (2):
      ps = PixelSpace.new(NArray::SINT, columns, rows)
      # Set up our parameters:
      ps.send(:setup, delta_col, delta_row, pos, cosines)
      # Return the created instance:
      ps
    end

    # Creates a PixelSpace instance with gantry angle, source detector
    # distance and isocenter position, from which image position and cosines
    # are derived.
    #
    # @param [Integer] columns the number of columns (nx)
    # @param [Integer] rows the number of rows (ny)
    # @param [Float] delta_col the distance between pixel columns
    # @param [Float] delta_row the distance between pixel rows
    # @param [Float] gantry_angle the gantry angle of the beam
    # @param [Float] sdd the distance between the beam source and the detector plane
    # @param [Coordinate] isocenter the beam system's isocenter position
    # @return [PixelSpace] the created PixelSpace instance
    #
    def self.setup(columns, rows, delta_col, delta_row, gantry_angle, sdd, isocenter)
      raise ArgumentError, "Invalid argument 'sdd'. Must be a positive number, got #{sdd}" unless sdd.to_f > 0
      # Convert to radians:
      radians = gantry_angle / 180.0 * Math::PI
      # Calculate the cosines:
      cosines = Array.new(6, 0.0)
      # X-coordinate: Cosine 3 is always 0. Cosine 0 varies in the range <-1, 1>:
      cosines[0] = Math.cos(radians).round(15)
      # Y-coordinate: Cosine 4 is always 0. Cosine 1 varies in the range <-1, 1>:
      cosines[1] = Math.sin(radians).round(15)
      # Z-coordinate: Cosine 2 is always 0. Cosine 5 is always -1:
      cosines[5] = -1.0
      # Calculate the image position:
      # Compute the coordinate of the center of the pixel space (excl. isocenter):
      center_x = Math.cos(radians).round(15) * sdd * 0.5
      center_y = Math.sin(radians).round(15) * sdd * 0.5
      # Get the offset from the center of the image to the corner:
      row_offset = rows.odd? ? delta_row * (rows / 2) : delta_row * (rows / 2 - 0.5)
      col_offset = columns.odd? ? delta_col * (columns / 2) : delta_col * (columns / 2 - 0.5)
      # Get the offset between isocenter and the center of the image:
      img_offset_x = -0.5 * sdd * cosines[1]
      img_offset_y = 0.5 * sdd * cosines[0]
      # Z-coordinate: This depends only on the number of rows and the isocenter position:
      x = (isocenter.x - cosines[0] * col_offset + img_offset_x).round(14)
      y = (isocenter.y - cosines[1] * col_offset + img_offset_y).round(14)
      z = (isocenter.z - cosines[5] * row_offset).round(14)
      pos = Coordinate.new(x, y, z)
      # Create the instance:
      ps = self.create(columns, rows, delta_col, delta_row, pos, cosines)
    end

    # Checks for equality.
    #
    # Other and self are considered equivalent if they are
    # of compatible types and their attributes are equivalent.
    #
    # @param other an object to be compared with self
    # @return [Boolean] true if self and other are considered equivalent
    #
    def ==(other)
      if other.respond_to?(:to_pixel_space)
        attr_result = other.send(:state) == state
        # If the attributes are equal, proceed to compare the content of the two arrays:
        if attr_result
          NArray[self] == NArray[other]
        else
          false
        end
      end
    end

    alias_method :eql?, :==

    # Calculates the cartesian coordinate of the given pixel index pair.
    #
    # @param [Integer] i the image column index
    # @param [Integer] j the image row index
    # @return [Coordinate] the cartesian coordinate of the pixel
    #
    def coordinate(i, j)
      x = @pos.x + (i * @delta_col * @cosines[0]) + (j * @delta_row * @cosines[3])
      y = @pos.y + (i * @delta_col * @cosines[1]) + (j * @delta_row * @cosines[4])
      z = @pos.z + (i * @delta_col * @cosines[2]) + (j * @delta_row * @cosines[5])
      Coordinate.new(x, y, z)
    end

    # Sets the cosines attribute.
    #
    # @param [Array<Float>] array the 6 directional cosines which describes the orientation of the image
    #
    def cosines=(array)
      raise ArgumentError, "Invalid parameter 'array'. Exactly 6 elements needed, got #{array.length}" unless array.length == 6
      @cosines = array.collect {|val| val.to_f}
    end

    # Sets the delta_col attribute.
    #
    # @param [Float] distance the distance between columns in the pixel space
    #
    def delta_col=(distance)
      raise ArgumentError, "Invalid argument 'distance'. Must be a positive number, got #{distance}" unless distance.to_f > 0.0
      @delta_col = distance.to_f
    end

    # Sets the delta_row attribute.
    #
    # @param [Float] distance the distance between rows in the pixel space
    #
    def delta_row=(distance)
      raise ArgumentError, "Invalid argument 'distance'. Must be a positive number, got #{distance}" unless distance.to_f > 0.0
      @delta_row = distance.to_f
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

    # Sets the pos attribute.
    #
    # @param [Coordinate] position the position of the corner of the pixel space
    #
    def pos=(position)
      @pos = position.to_coordinate
    end

    # Returns self.
    #
    # @return [PixelSpace] self
    #
    def to_pixel_space
      self
    end

    # Converts the pixel space to one with a different typecode (e.g. from integer to float).
    #
    def to_type(code)
      # Set up the array:
      ps = PixelSpace.new(code, @columns, @rows)
      # Set up the associated parameters:
      ps.send(:setup, @delta_col, @delta_row, @pos, @cosines)
      ps
    end


    private


    # Sets up the instance variables.
    #
    def setup(delta_col, delta_row, pos, cosines)
      # Set up the provided parameters:
      self.delta_col = delta_col
      self.delta_row = delta_row
      self.pos = pos
      self.cosines = cosines
      # Set up the dimensional parameters:
      @columns, @rows = self.shape
    end

    # Collects the attributes of this instance.
    #
    # @return [Array<String>] an array of attributes
    #
    def state
      # Note that the state array doesn't include the actual pixel array values.
       [@delta_col, @delta_row, @pos]
    end

  end

end
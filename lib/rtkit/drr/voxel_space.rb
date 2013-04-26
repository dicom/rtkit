module RTKIT

  # A VoxelSpace is an extension of a 3D NArray with some extra
  # attributes to describe its geometrical properties in a coordinate system.
  #
  class VoxelSpace < NArray

    # Distance between voxels (Coordinate with Float values in units of mm).
    attr_accessor :delta_x
    attr_accessor :delta_y
    attr_accessor :delta_z
    # The number of columns in the voxel array (Integer).
    attr_reader :nx
    # The number of rows in the voxel array (Integer).
    attr_reader :ny
    # The number of slices in the voxel array (Integer).
    attr_reader :nz
    # Coordinate (corner position) of the voxel space (with Float values in units of mm).
    attr_reader :pos

    alias_method :columns, :nx
    alias_method :rows, :ny
    alias_method :slices, :nz

    # Creates a VoxelSpace instance with the given set of geometrical properties.
    #
    # @param [Integer] columns the number of columns (nx)
    # @param [Integer] rows the number of rows (ny)
    # @param [Integer] slices the number of slices (nz)
    # @param [Float] delta_x the distance between voxels along the x axis
    # @param [Float] delta_y the distance between voxels along the y axis
    # @param [Float] delta_z the distance between voxels along the z axis
    # @param [Coordinate] pos the position of the corner of the voxel space
    # @return [VoxelSpace] the created VoxelSpace instance
    #
    def self.create(columns, rows, slices, delta_x, delta_y, delta_z, pos)
      # We choose to initalize as an NArray with type double float (5):
      vs = VoxelSpace.new(NArray::DFLOAT, columns, rows, slices)
      # Set up our parameters:
      vs.send(:setup, delta_x, delta_y, delta_z, pos)
      # Return the created instance:
      vs
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
      if other.respond_to?(:to_voxel_space)
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
    # @param [Coordinate] position the position of the corner of the voxel space
    #
    def pos=(position)
      @pos = position.to_coordinate
    end

    # Returns self.
    #
    # @return [VoxelSpace] self
    #
    def to_voxel_space
      self
    end


    private


    # Sets up the instance variables.
    #
    def setup(delta_x, delta_y, delta_z, pos)
      # Set up the provided parameters:
      @delta_x = delta_x
      @delta_y = delta_y
      @delta_z = delta_z
      self.pos = pos
      # Set up the dimensional parameters:
      @nx, @ny, @nz = self.shape
    end

    # Collects the attributes of this instance.
    #
    # @return [Array<String>] an array of attributes
    #
    def state
      # Note that the state array doesn't include the actual voxel array values.
       [@delta_x, @delta_y, @delta_z, @pos]
    end

  end

end
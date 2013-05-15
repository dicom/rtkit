module RTKIT

  # Contains code for describing the geometry of a voxel space,
  # relative to a beam of interest.
  #
  class BeamGeometry

    attr_reader :attenuation
    attr_reader :isocenter
    attr_reader :source
    attr_reader :voxel_space

    # Creates a BeamGeometry instance which is setup by gantry angle and source
    # isocenter distance, instead of a source coordinate.
    #
    # @param [Float] gantry_angle the gantry angle of the beam
    # @param [Float] sid the distance between the beam source and the isocenter
    # @param [Coordinate] isocenter the beam's isocenter position
    # @param [VoxelSpace] voxel_space a voxel array located in the geometry
    # @param [Hash] options the options to use for creating the BeamGeometry instance
    # @option options [Attenuation] :attenuation an attenuation algorithm/energy to use for DRR creation
    # @return [BeamGeometry] the created BeamGeometry instance
    #
    def self.setup(gantry_angle, sid, isocenter, voxel_space, options={})
      raise ArgumentError, "Invalid argument 'sid'. Must be a positive number, got #{sid}" unless sid.to_f > 0
      # Convert to radians:
      radians = gantry_angle / 180.0 * Math::PI
      # Calculate the source coordinate from the provided information:
      source_x = isocenter.x + sid * (Math.sin(radians)).round(15)
      source_y = isocenter.y - sid * (Math.cos(radians)).round(15)
      # Create the instance:
      self.new(Coordinate.new(source_x, source_y, isocenter.z), isocenter, voxel_space, options)
    end

    # Creates a BeamGeometry instance.
    #
    # @param [Coordinate] source the beam's source position
    # @param [Coordinate] isocenter the beam system's isocenter position
    # @param [VoxelSpace] voxel_space a voxel array located in the geometry
    # @param [Hash] options the options to use for creating the BeamGeometry instance
    # @option options [Attenuation] :attenuation an attenuation instance to use for DRR creation (defaults to 50 keV photon attenuation)
    # @return [BeamGeometry] the created BeamGeometry instance
    #
    def initialize(source, isocenter, voxel_space, options={})
      # Set instance variables:
      self.source = source
      self.isocenter = isocenter
      self.voxel_space = voxel_space
      self.attenuation = options[:attenuation] ? options[:attenuation] : Attenuation.new
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
      if other.respond_to?(:to_beam_geometry)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Sets the attenuation attribute.
    #
    # @param [Attenuation] obj the instance to use for attenuation calculation for this beam geometry
    #
    def attenuation=(obj)
      @attenuation = obj.to_attenuation
    end

    # Computes a digitally reconstructed radiograph (DRR), using this beam geometry
    # for the given pixel space (image), applied to the associated voxel space.
    #
    # @param [PixelSpace] pixel_space the DRR pixel array (image)
    # @return [PixelSpace] the digitally reconstructed radiograph
    #
    def create_drr(pixel_space)
      # Ensure that we have a pixel_space with data values of type float,
      # which is necessary to store our fractional attenuation values:
      pixel_space = pixel_space.to_pixel_space.to_type(NArray::FLOAT)
      # Set up a ray instance and iterate the pixels of the radiograph:
      r = Ray.new
      pixel_space.columns.times do |i|
        pixel_space.rows.times do |j|
          # Set the properties for the current pixel and perform the ray trace:
          r.reset
          r.p1 = @source
          r.p2 = pixel_space.coordinate(i, j)
          r.vs = @voxel_space
          r.trace
          # Determine the attenuation (fractional value in the range 0 to 1):
          if r.indices.length > 0
            pixel_space[i, j] = @attenuation.vector_attenuation(@voxel_space[r.indices], r.lengths)
          end
        end
      end
      # Convert the pixel space from fractional attenuation values to 12 bit presentation pixel values:
      ps = pixel_space.to_type(NArray::INT)
      ps[true, true] = pixel_space[true, true] * 4095
      # Return the properly processed radiograph:
      ps
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

    # Sets the isocenter attribute.
    #
    # @param [Coordinate] position the position of the beam's isocenter
    #
    def isocenter=(position)
      @isocenter = position.to_coordinate
    end

    # Sets the source attribute.
    #
    # @param [Coordinate] position the position of the beam source
    #
    def source=(position)
      @source = position.to_coordinate
    end

    # Returns self.
    #
    # @return [BeamGeometry] self
    #
    def to_beam_geometry
      self
    end

    # Sets the voxel_space attribute.
    #
    # @param [VoxelSpace] vs a voxel array that is present in the geometric setup
    #
    def voxel_space=(vs)
      @voxel_space = vs.to_voxel_space
    end


    private


    # Collects the attributes of this instance.
    #
    # @return [Array<String>] an array of attributes
    #
    def state
      # Note that the state array doesn't include the actual pixel array values.
       [@isocenter, @source, @voxel_space]
    end

  end

end
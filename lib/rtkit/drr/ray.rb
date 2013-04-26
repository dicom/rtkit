module RTKIT

  # Contains code for tracing a ray through a 3D voxel space.
  #
  # === Relations
  #
  # * A Ray instance is associated with VoxelSpace, and a source and target Coordinate.
  #
  # === References
  #
  # This implementation is based on the original publication of an efficient ray-tracing
  # algorithm by Robert Siddon:
  # Fast calculation of the exact radiological path for a three-dimensional CT array
  # Medical Physics, volume 12, issue 2, p252-255, 1985
  #
  # Furthermore, it uses an optimization as described by Filip Jacobs et al:
  # A fast algorithm to calculate the exact radiological path through a pixel or voxel space
  # Journal of computing and information technology, 6(1), p89-94, 1998
  #
  class Ray

    # Summed density for the ray's intersection with the voxel space.
    attr_reader :d
    # An array of voxel space indices intersected by the ray's travel from p1 to p2.
    attr_reader :indices
    # An array of intersection lengths (floats in units of mm) for each voxel intersection.
    attr_reader :lengths
    # The ray's source coordinate.
    attr_reader :p1
    # The ray's target coordinate.
    attr_reader :p2
    # The voxel space (3D NArray) associated with this ray.
    attr_reader :vs

    # Creates a Ray instance and traces the ray's path through a voxel space.
    #
    # @param [Coordinate] p1 the ray's starting point
    # @param [Coordinate] p2 the ray's end point
    # @param [VoxelSpace] voxel_space the voxel space that the ray might intersect
    # @return [Ray] the traced Ray instance
    #
    def self.trace(p1, p2, voxel_space, options={})
      raise ArgumentError, "Invalid parameter p1. Expected Coordinate, got #{p1.class}" unless p1.respond_to?(:to_coordinate)
      raise ArgumentError, "Invalid parameter p2. Expected Coordinate, got #{p2.class}" unless p2.respond_to?(:to_coordinate)
      raise ArgumentError, "Invalid parameter voxel_space. Expected VoxelSpace, got #{voxel_space.class}" unless voxel_space.respond_to?(:to_voxel_space)
      r = Ray.new(options)
      # Assign the given instance variables:
      r.p1 = p1
      r.p2 = p2
      r.vs = voxel_space
      # Perform the ray tracing:
      r.trace
      r
    end

    # Creates a Ray instance.
    #
    # @param [Hash] options the options to use for the Ray instance
    # @option options [Boolean] :path if true, the indices intersected by the ray in the voxel space will be recorded
    # @return [Ray] the created Ray instance
    #
    def initialize(options={})
      # Assign optional parameters:
      @path = options[:path]
      # Initialize parameters:
      self.reset
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
      if other.respond_to?(:to_ray)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Calculates the fraction of the ray's movement (in the x direction), between
    # its source and destination, for the ray's travel to the given plane index i.
    #
    # @note This function may return values outside the interval <0, 1> for x
    #   indices that are outside the range of indices 'between' source and destination.
    # @param [Integer] i a plane index
    # @return [Float] a fraction of movement between source and target
    #
    def ax(i)
      val = (coord_x(i) - @p1.x) / (@p2.x - @p1.x)
      val.nan? ? Float::INFINITY : val
    end

    # Calculates the fraction of the ray's movement (in the y direction), between
    # its source and destination, for the ray's travel to the given plane index j.
    #
    # @note This function may return values outside the interval <0, 1> for y
    #   indices that are outside the range of indices 'between' source and destination.
    # @param [Integer] j a plane index
    # @return [Float] a fraction of movement between source and target
    #
    def ay(j)
      val = (coord_y(j) - @p1.y) / (@p2.y - @p1.y)
      val.nan? ? Float::INFINITY : val
    end

    # Calculates the fraction of the ray's movement (in the z direction), between
    # its source and destination, for the ray's travel to the given plane index k.
    #
    # @note This function may return values outside the interval <0, 1> for z
    #   indices that are outside the range of indices 'between' source and destination.
    # @param [Integer] k a plane index
    # @return [Float] a fraction of movement between source and target
    #
    def az(k)
      val = (coord_z(k) - @p1.z) / (@p2.z - @p1.z)
      val.nan? ? Float::INFINITY : val
    end

    # The coordinate of the first (zero) x plane of the voxel space.
    #
    # @return [Float] the corner x coordinate of the associated voxel space
    #
    def bx
      @vs.pos.x - 0.5 * @vs.delta_x
    end

    # The coordinate of the first (zero) y plane of the voxel space.
    #
    # @return [Float] the corner y coordinate of the associated voxel space
    #
    def by
      @vs.pos.y - 0.5 * @vs.delta_y
    end

    # The coordinate of the first (zero) z plane of the voxel space.
    #
    # @return [Float] the corner z coordinate of the associated voxel space
    #
    def bz
      @vs.pos.z - 0.5 * @vs.delta_z
    end

    # Calculates the x coordinate of a given intersection plane index i.
    #
    # @note The plane coordinates are shifted by a half voxel spacing compared
    #   to the voxel coordinates.
    # @param [Integer] i a plane index
    # @return [Float] the x coordinate of the given plane
    #
    def coord_x(i)
      @vs.pos.x + (i - 0.5) * @vs.delta_x
    end

    # Calculates the y coordinate of a given intersection plane index j.
    #
    # @note The plane coordinates are shifted by a half voxel spacing compared
    #   to the voxel coordinates.
    # @param [Integer] j a plane index
    # @return [Float] the y coordinate of the given plane
    #
    def coord_y(j)
      @vs.pos.y + (j - 0.5) * @vs.delta_y
    end

    # Calculates the z coordinate of a given intersection plane index k.
    #
    # @note The plane coordinates are shifted by a half voxel spacing compared
    #   to the voxel coordinates.
    # @param [Integer] k a plane index
    # @return [Float] the z coordinate of the given plane
    #
    def coord_z(k)
      @vs.pos.z + (k - 0.5) * @vs.delta_z
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

    # Calculates a voxel plane x index (i) from an alpha value.
    #
    # @param [Float] alpha a fraction of the ray's movement between source and target
    # @return [Integer] the calculated voxel plane index (i)
    #
    def phi_x(alpha)
      # If the ray is orthogonal on the x axis, the evaluation will yield NaN, and
      # we return the index i which corresponds to the source's x position instead.
      (((@p2.x - @p1.x == 0 ? @p1.x : px(alpha)) - bx) / @vs.delta_x).floor
    end

    # Calculates a voxel plane y index (j) from an alpha value.
    #
    # @param [Float] alpha a fraction of the ray's movement between source and target
    # @return [Integer] the calculated voxel plane index (j)
    #
    def phi_y(alpha)
      # If the ray is orthogonal on the y axis, the evaluation will yield NaN, and
      # we return the index j which corresponds to the source's y position instead.
      (((@p2.y - @p1.y == 0 ? @p1.y : py(alpha)) - by) / @vs.delta_y).floor
    end

    # Calculates a voxel plane z index (k) from an alpha value.
    #
    # @param [Float] alpha a fraction of the ray's movement between source and target
    # @return [Integer] the calculated voxel plane index (k)
    #
    def phi_z(alpha)
      # If the ray is orthogonal on the z axis, the evaluation will yield NaN, and
      # we return the index k which corresponds to the source's z position instead.
      (((@p2.z - @p1.z == 0 ? @p1.z : pz(alpha)) - bz) / @vs.delta_z).floor
    end

    # Sets the p1 attribute.
    #
    # @param [Coordinate] source the ray's source coordinate
    #
    def p1=(source)
      @p1 = source.to_coordinate
    end

    # Sets the p2 attribute.
    #
    # @param [Coordinate] target the ray's target coordinate
    #
    def p2=(target)
      @p2 = target.to_coordinate
    end

    # Sets the vs attribute.
    #
    # @param [VoxelSpace] voxel_space the voxel space which the ray may intersect
    #
    def vs=(voxel_space)
      @vs = voxel_space.to_voxel_space
    end

    # Calculates the ray's x position, given an alpha value.
    #
    # @param [Float] alpha a fraction of the ray's movement between source and target
    # @return [Float] the ray's x coordinate
    #
    def px(alpha)
      @p1.x + alpha * (@p2.x - @p1.x)
    end

    # Calculates the ray's y position, given an alpha value.
    #
    # @param [Float] alpha a fraction of the ray's movement between source and target
    # @return [Float] the ray's y coordinate
    #
    def py(alpha)
      @p1.y + alpha * (@p2.y - @p1.y)
    end

    # Calculates the ray's z position, given an alpha value.
    #
    # @param [Float] alpha a fraction of the ray's movement between source and target
    # @return [Float] the ray's z coordinate
    #
    def pz(alpha)
      @p1.z + alpha * (@p2.z - @p1.z)
    end

    # Resets the calculated parameters of this instance
    # (density (d) and trajectory (indices)).
    #
    def reset
      # Summed density for the ray through the voxel space:
      @d = 0.0
      # The trajectory (indices) of the voxel space travelled by the ray from p1 to p2:
      @indices = Array.new
      # The intersection lengths of each voxel intersection:
      @lengths = Array.new
      # An attribute keeping track of whether the ray has reached the voxel space:
      @reached_voxel_space = false
    end

    # Returns self.
    #
    # @return [Ray] self
    #
    def to_ray
      self
    end

    # Performs ray tracing, where the ray's possible intersection of the
    # associated voxel space is investigated for the ray's movement from
    # its source coordinate to its target coordinate.
    #
    # The resulting density experienced by the ray through the voxel space
    # is stored in the 'd' attribute. The indices of the voxel space
    # intersected by the ray is stored in the 'indices' attribute (if the
    # 'path' option has been set).
    #
    def trace
      # Set up instance varibles which depends on the initial conditions.
      # Delta positions determines whether the ray's travel is positive
      # or negative in the three directions.
      delta_x = @p1.x < @p2.x ? 1 : -1
      delta_y = @p1.y < @p2.y ? 1 : -1
      delta_z = @p1.z < @p2.z ? 1 : -1
      # Delta indices determines whether the ray's voxel space indices increments
      # in a positive or negative fashion as it travels through the voxel space.
      # Note that for rays travelling perpendicular on a particular axis, the
      # delta value of that axis will be undefined (zero).
      @delta_i = @p1.x == @p2.x ? 0 : delta_x
      @delta_j = @p1.y == @p2.y ? 0 : delta_y
      @delta_k = @p1.z == @p2.z ? 0 : delta_z
      # These variables describe how much the alpha fraction changes (in a
      # given axis) when we follow the ray through one voxel (across two planes).
      # This value is high if the ray is perpendicular on the axis (angle high, or close to 90 degrees),
      # and low if the angle is parallell with the axis (angle low, or close to 0 degrees).
      @delta_ax = @vs.delta_x / (@p2.x - @p1.x).abs
      @delta_ay = @vs.delta_y / (@p2.y - @p1.y).abs
      @delta_az = @vs.delta_z / (@p2.z - @p1.z).abs
      # Determines the ray length (from p1 to p2).
      @length = Math.sqrt((@p2.x-@p1.x)**2 + (@p2.y-@p1.y)**2 + (@p2.z-@p1.x)**2)
      # Perform the ray tracing:
      # Number of voxels: nx, ny, nz
      # Number of planes: nx+1, ny+1, nz+1
      # Voxel indices: 0..(nx-1), etc.
      # Plane indices: 0..nx, etc.
      intersection_with_voxel_space
      # Perform the ray trace only if the ray's intersection with the
      # voxel space is between the ray's start and end points:
      if @alpha_max > 0 && @alpha_min < 1
        min_and_max_indices
        number_of_planes
        axf, ayf, azf = first_intersection_point_in_voxel_space
        # If we didn't get any intersection points, there's no need to proceed with the ray trace:
        if [axf, ayf, azf].any?
          # Initialize the starting alpha values:
          initialize_alphas(axf, ayf, azf)
          @i, @j, @k = indices_first_intersection(axf, ayf, azf)
          # Initiate the ray tracing if we got valid starting coordinates:
          if @i && @j && @k
            # Calculate the first move:
            update
            # Next interactions:
            # To avoid float impresision issues we choose to round here before
            # doing the comparison. How many decimals should we choose to round to?
            # Perhaps there is a more prinipal way than the chosen solution?
            alpha_max_rounded = @alpha_max.round(8)
            while @ac.round(8) < alpha_max_rounded do
              update
            end
          end
        end
      end
    end


    private


    # Gives the minimum value among the directional fractions given, taking
    # into account that some of them may be nil, negative, or even -INFINITY,
    # and thus needs to be excluded before extracting the valid minimum value.
    #
    # @param [Array<Float, NilClass>] fractions a collection of alpha values
    # @return [Float] the minimum value among the valid alphas
    #
    def alpha_min(fractions)
      fractions.compact.collect { |a| a >= 0 ? a : nil}.compact.min
    end

    # Gives the minimum value among the directional fractions that is larger
    # than @alpha_min (e.g. invalid values like too small values, nil, negative,
    # or even -INFINITY are exlcuded).
    #
    # @param [Array<Float, NilClass>] fractions a collection of alpha values
    # @return [Float] the minimum value among the valid alphas
    #
    def alpha_min_first_intersection(fractions)
      fractions.compact.collect { |a| a > @alpha_min ? a : nil}.compact.min
    end

    # Determines the movement of the ray in the pending step.
    #
    def determine_movement
      # Determine which way to move the ray at the pending iteration:
      @a_min = alpha_min([@ax, @ay, @az])
      # Calculate the length to be traveled in the current step:
      @step_length = (@a_min - @ac) * @length
    end

    # Determines the alpha values for the first intersection after
    # the ray has entered the voxel space.
    #
    # @return [Array<Float>] directional x, y and z alpha values
    #
    def first_intersection_point_in_voxel_space
      a_x_min = ax(@i_min)
      a_y_min = ay(@j_min)
      a_z_min = az(@k_min)
      a_x_max = ax(@i_max)
      a_y_max = ay(@j_max)
      a_z_max = az(@k_max)
      alpha_x = alpha_min_first_intersection([a_x_min, a_x_max])
      alpha_y = alpha_min_first_intersection([a_y_min, a_y_max])
      alpha_z = alpha_min_first_intersection([a_z_min, a_z_max])
      return alpha_x, alpha_y, alpha_z
    end

    # Determines the voxel indices of the first intersection.
    #
    # @param [Float] axf a directional x alpha value for the ray's first intersection in voxel space
    # @param [Float] ayf a directional y alpha value for the ray's first intersection in voxel space
    # @param [Float] azf a directional z alpha value for the ray's first intersection in voxel space
    # @return [Array<Integer>] voxel indices i, j and k of the first intersection
    #
    def indices_first_intersection(axf, ayf, azf)
      i, j, k = nil, nil, nil
      # In cases of perpendicular ray travel, one or two arguments may be
      # -INFINITY, which must be excluded when searching for the minimum value:
      af_min = alpha_min([axf, ayf, azf])
      sorted_real_alpha_values([axf, ayf, azf]).each do |a|
        alpha_mean = (a + @alpha_min) * 0.5
        i0 = phi_x(alpha_mean)
        j0 = phi_y(alpha_mean)
        k0 = phi_z(alpha_mean)
        if indices_within_voxel_space(i0, j0, k0)
          i, j, k = i0, j0, k0
          break
        end
      end
      return i, j, k
    end

    # Checks whether the given voxel indices describe an index
    # that is within the associated voxel space.
    #
    # @param [Integer] i the first volume index (column)
    # @param [Integer] j the second volume index (row)
    # @param [Integer] k the third volume index (slice)
    # @return [Boolean] true if within, and false if not
    #
    def indices_within_voxel_space(i, j, k)
      if [i, j, k].min >= 0
        if i < @vs.nx && j < @vs.nz && k < @vs.nz
          true
        else
          false
        end
      else
        false
      end
    end

    # Initialize the alpha values.
    #
    # @param [Float] ax a fraction of movement between source and target in the x direction
    # @param [Float] ay a fraction of movement between source and target in the y direction
    # @param [Float] az a fraction of movement between source and target in the z direction
    #
    def initialize_alphas(ax, ay, az)
      # We need a variable to keep track of the current alpha value:
      @ac = @alpha_min
      # The 'on hold' (i.e. waiting to be used for moving in the voxel space) directional alphas:
      @ax = ax
      @ay = ay
      @az = az
    end

    # Determines at what fraction (alpha) of the ray's length (from source
    # to target) the ray may enter and leave the voxel space, when following
    # the shortest path (perpendicular to the voxel space).
    #
    def intersection_with_voxel_space
      alpha_x0 = ax(0)
      alpha_y0 = ay(0)
      alpha_z0 = az(0)
      alpha_x_last = ax(@vs.nx)
      alpha_y_last = ay(@vs.ny)
      alpha_z_last = az(@vs.nz)
      @alpha_x_min = [alpha_x0, alpha_x_last].min
      @alpha_y_min = [alpha_y0, alpha_y_last].min
      @alpha_z_min = [alpha_z0, alpha_z_last].min
      @alpha_x_max = [alpha_x0, alpha_x_last].max
      @alpha_y_max = [alpha_y0, alpha_y_last].max
      @alpha_z_max = [alpha_z0, alpha_z_last].max
      @alpha_min = [@alpha_x_min, @alpha_y_min, @alpha_z_min].max
      @alpha_max = [@alpha_x_max, @alpha_y_max, @alpha_z_max].min
    end

    # Determines the intersection indices [i,j,k]_min (the first intersected
    # plane after the ray entered the voxel space) and [i,j,k]_max (when the
    # destination is outside the voxel space, this will be the outer voxel plane).
    #
    def min_and_max_indices
      # I indices:
      if @p1.x < @p2.x
        if @alpha_min == @alpha_x_min
          @i_min = 1
        else
          @i_min = phi_x(@alpha_min)
        end
        if @alpha_max == @alpha_x_max
          @i_max = @vs.nx
        else
          @i_max = phi_x(@alpha_max)
        end
      else
        if @alpha_min == @alpha_x_min
          @i_max = @vs.nx - 1
        else
          @i_max = phi_x(@alpha_min)
        end
        if @alpha_max == @alpha_x_max
          @i_min = 0
        else
          @i_min = phi_x(@alpha_max)
        end
      end
      # J indices:
      if @p1.y < @p2.y
        if @alpha_min == @alpha_y_min
          @j_min = 1
        else
          @j_min = phi_y(@alpha_min)
        end
        if @alpha_max == @alpha_y_max
          @j_max = @vs.ny
        else
          @j_max = phi_y(@alpha_max)
        end
      else
        if @alpha_min == @alpha_y_min
          @j_max = @vs.ny - 1
        else
          @j_max = phi_y(@alpha_min)
        end
        if @alpha_max == @alpha_y_max
          @j_min = 0
        else
          @j_min = phi_y(@alpha_max)
        end
      end
      # K indices:
      if @p1.z < @p2.z
        if @alpha_min == @alpha_z_min
          @k_min = 1
        else
          @k_min = phi_z(@alpha_min)
        end
        if @alpha_max == @alpha_z_max
          @k_max = @vs.nz
        else
          @k_max = phi_z(@alpha_max)
        end
      else
        if @alpha_min == @alpha_z_min
          @k_max = @vs.nz - 1
        else
          @k_max = phi_z(@alpha_min)
        end
        if @alpha_max == @alpha_z_max
          @k_min = 0
        else
          @k_min = phi_z(@alpha_max)
        end
      end
    end

    # Moves the ray along one of the three axes of the voxel space,
    # and updates the corresponding instance variables.
    #
    def move_ray
      # Further updates is based on which way we decided to move:
      case @a_min
      when @ax
        @i += @delta_i
        @ac = @ax
        @ax += @delta_ax
      when @ay
        @j += @delta_j
        @ac = @ay
        @ay += @delta_ay
      when @az
        @k += @delta_k
        @ac = @az
        @az += @delta_az
      else
        raise "Unexpected error in move_ray case: #{@a_min}, #{@ax}, #{@ay}, #{@az}"
      end
    end

    # Calculates the number of planes crossed by the ray when as it travels
    # through the voxel space (after it first entered the voxel space).
    #
    def number_of_planes
      @np = (@i_max - @i_min + 1) + (@j_max - @j_min + 1) + (@k_max - @k_min + 1)
    end

    # Collects the attributes of this instance.
    #
    # @return [Array<String>] an array of attributes
    #
    def state
      [@d, @indices, @p1, @p2, @vs]
    end

    # Gives a sorted array of the directional fractions given, taking
    # into account that some of them may be nil, negative, or even -INFINITY,
    # and thus needs to be excluded before sorting.
    #
    # @param [Array<Float, NilClass>] fractions a collection of alpha values
    # @return [Array<Float>] sorted (valid) alpha values
    #
    def sorted_real_alpha_values(fractions)
      fractions.compact.collect { |a| a >= 0 && a.finite? ? a : nil}.compact.sort
    end

    # Moves the voxel based on the given values, and updates/stores attributes
    # such as density and indices.
    #
    def update
      determine_movement
      # Add the density contribution for this voxel intersection to the sum:
      @d += @step_length * @vs[@i, @j, @k]
      # Store path information such as the voxel index intersected,
      # as well as the intersection length (this will be moved into an if eventually):
      @indices << @vs.nx * @vs.ny * @k + @vs.nx * @j + @i
      @lengths << @step_length
      move_ray
    end

  end

end
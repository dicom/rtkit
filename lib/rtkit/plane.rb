module RTKIT

  # A Plane describes a flat, two-dimensional surface.
  #
  # A Plane can be defined in several ways, e.g. by:
  # * A point and a normal vector.
  # * A point and two vectors lying on it.
  # * 3 non-colinear points.
  #
  # We will describe the plane in the form of a plane equation:
  #  ax + by +cz +d = 0
  #
  # The Plane class can be useful for relating instances of image slices.
  #
  # @see For more information on Planes, refer to:  http://en.wikipedia.org/wiki/Plane_(geometry)
  #
  class Plane

    # The 'a' parameter of the plane equation.
    attr_reader :a
    # The 'b' parameter of the plane equation.
    attr_reader :b
    # The 'c' parameter of the plane equation.
    attr_reader :c
    # The 'd' parameter of the plane equation.
    attr_reader :d

    # Calculates a plane equation from the 3 specified coordinates.
    #
    # @return [Plane] the created Plane instance
    #
    def self.calculate(c1, c2, c3)
      raise ArgumentError, "Invalid argument 'c1'. Expected Coordinate, got #{c1.class}" unless c1.is_a?(Coordinate)
      raise ArgumentError, "Invalid argument 'c2'. Expected Coordinate, got #{c2.class}" unless c2.is_a?(Coordinate)
      raise ArgumentError, "Invalid argument 'c3'. Expected Coordinate, got #{c3.class}" unless c3.is_a?(Coordinate)
      x1, y1, z1 = c1.x.to_r, c1.y.to_r, c1.z.to_r
      x2, y2, z2 = c2.x.to_r, c2.y.to_r, c2.z.to_r
      x3, y3, z3 = c3.x.to_r, c3.y.to_r, c3.z.to_r
      raise ArgumentError, "Got at least two Coordinates that are equal. Expected unique Coordinates."  unless [[x1, y1, z1], [x2, y2, z2], [x3, y3, z3]].uniq.length == 3
      det = Matrix.rows([[x1, y1, z1], [x2, y2, z2], [x3, y3, z3]]).determinant
      if det == 0
        # Haven't experienced this case yet. Just raise an error to avoid unexpected behaviour.
        raise "The determinant was zero (which means the plane passes through the origin). Not able to calculate variables: a,b,c"
        #puts "Determinant was zero. Plane passes through origin. Find direction cosines instead?"
      else
        det = det.to_f
        # Find parameters a,b,c.
        a_m = Matrix.rows([[1, y1, z1], [1, y2, z2], [1, y3, z3]])
        b_m = Matrix.rows([[x1, 1, z1], [x2, 1, z2], [x3, 1, z3]])
        c_m = Matrix.rows([[x1, y1, 1], [x2, y2, 1], [x3, y3, 1]])
        d = Plane.d
        a = -d / det * a_m.determinant
        b = -d / det * b_m.determinant
        c = -d / det * c_m.determinant
        return self.new(a, b, c)
      end
    end

    # The custom plane parameter d (this constant can be equal to any non-zero
    # number).
    #
    # @return [Float] the 'd' value chosen in this implementation (500.0)
    #
    def self.d
      500.0
    end

    # Creates a new Plane instance.
    #
    # @param [Float] a the 'a' parameter of the plane equation
    # @param [Float] b the 'b' parameter of the plane equation
    # @param [Float] c the 'c' parameter of the plane equation
    #
    def initialize(a, b, c)
      raise ArgumentError, "Invalid argument 'a'. Expected Float, got #{a.class}." unless a.is_a?(Float)
      raise ArgumentError, "Invalid argument 'b'. Expected Float, got #{b.class}." unless b.is_a?(Float)
      raise ArgumentError, "Invalid argument 'c'. Expected Float, got #{c.class}." unless c.is_a?(Float)
      @a = a
      @b = b
      @c = c
      @d = Plane.d
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
      if other.respond_to?(:to_plane)
        other.send(:state) == state
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

    # Compares this Plane instance with an array of planes in order to find the
    # index of the plane who's plane equation is closest to the plane equation
    # of self.
    #
    # @param [Array<Plane>] planes an array of planes to match against
    # @return [Fixnumm, NilClass] the index of the matching plane in the specified array (or nil if no planes matched)
    #
    def match(planes)
      raise ArgumentError, "Invalid argument 'planes'. Expected Array, got #{planes.class}." unless planes.is_a?(Array)
      raise ArgumentError, "Invalid argument 'planes'. Expected Array containing only Planes, got #{planes.collect{|p| p.class}.uniq}." unless planes.collect{|p| p.class}.uniq == [Plane]
      # I don't really have a feeling for what a reasonable threshold should be here. Setting it at 0.01.
      # (So far, matched planes have been observed having a deviation in the order of 10e-5 to 10e-7,
      # while some obviously different planes have had values in the range of 8-21)
      deviation_threshold = 0.01
      # Since the 'd' parameter is just a constant selected by us when determining plane equations,
      # the comparison is carried out against the a, b & c parameters.
      # Register deviation for each parameter for each plane:
      a_deviations = NArray.float(planes.length)
      b_deviations = NArray.float(planes.length)
      c_deviations = NArray.float(planes.length)
      planes.each_index do |i|
        # Calculate absolute deviation for each of the three parameters:
        a_deviations[i] = (planes[i].a - @a).abs
        b_deviations[i] = (planes[i].b - @b).abs
        c_deviations[i] = (planes[i].c - @c).abs
      end
      # Compare the deviations of each parameter with the average deviation for that parameter,
      # taking care to adress the case where all deviations for a certain parameter may be 0:
      a_relatives = a_deviations.mean == 0 ? a_deviations : a_deviations / a_deviations.mean
      b_relatives = b_deviations.mean == 0 ? b_deviations : b_deviations / b_deviations.mean
      c_relatives = c_deviations.mean == 0 ? c_deviations : c_deviations / c_deviations.mean
      # Sum the relative deviations for each parameter, and find the index with the lowest summed relative deviation:
      deviations = NArray.float(planes.length)
      planes.each_index do |i|
        deviations[i] = a_relatives[i] + b_relatives[i] + c_relatives[i]
      end
      index = (deviations.eq deviations.min).where[0]
      deviation = a_deviations[index] + b_deviations[index] + c_deviations[index]
      index = nil if deviation > deviation_threshold
      return index
    end

    # Returns self.
    #
    # @return [Plane] self
    #
    def to_plane
      self
    end

    # Converts the Plane instance to a an easily readable string (containing
    # the parameters a, b & c).
    #
    # @return [String] the plane parameters formatted to a string
    #
    def to_s
      return "a: #{@a.round(2)}  b: #{@b.round(2)} c: #{@c.round(2)}"
    end


    private


    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@a, @b, @c, @d]
    end

  end
end
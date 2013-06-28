module RTKIT

  # Contains a X,Y,Z coordinate triplet, describing a position in 3-dimensional space.
  #
  # === Relations
  #
  # * The Coordinate may belong to a Contour.
  #
  class Coordinate

    # The Contour which the Coordinate belongs to.
    attr_reader :contour
    # The X position (in units of mm).
    attr_reader :x
    # The Y position (in units of mm).
    attr_reader :y
    # The Z position (in units of mm).
    attr_reader :z

    # Creates a new Coordinate instance.
    #
    # @param [Float] x the position of the point along the x axis (in units of mm)
    # @param [Float] y the position of the point along the y axis (in units of mm)
    # @param [Float] z the position of the point along the z axis (in units of mm)
    # @param [Contour] contour the Contour instance (if any) which the coordinate belongs to
    #
    def initialize(x, y, z, contour=nil)
      raise ArgumentError, "Invalid argument 'contour'. Expected Contour (or nil), got #{contour.class}." if contour && !contour.is_a?(Contour)
      @contour = contour
      @x = x.to_f
      @y = y.to_f
      @z = z.to_f
      # Register ourselves with the Contour:
      @contour.add_coordinate(self) if contour
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
      if other.respond_to?(:to_coordinate)
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

    # Returns self.
    #
    # @return [Coordinate] self
    #
    def to_coordinate
      self
    end

    # Gives a string with the x, y & z instance values separated by a '\'.
    #
    # @return [String] the x, y & z instance values joined by a '\'
    #
    def to_s
      [@x, @y, @z].join("\\")
    end

    # Moves the coordinate according to the given offset vector.
    #
    # @param [Float] x the offset along the x axis (in units of mm)
    # @param [Float] y the offset along the y axis (in units of mm)
    # @param [Float] z the offset along the z axis (in units of mm)
    #
    def translate(x, y, z)
      @x += x.to_f
      @y += y.to_f
      @z += z.to_f
    end


    private


    # Collects the attributes of this instance.
    #
    # @return [Array<String>] an array of attributes
    #
    def state
       [@x, @y, @z]
    end

  end

end
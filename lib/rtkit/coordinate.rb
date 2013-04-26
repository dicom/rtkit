module RTKIT

  # Contains a X,Y,Z coordinate triplet, describing a position in 3-dimensional space.
  #
  # === Relations
  #
  # * The Coordinate may belong to a Contour.
  #
  class Coordinate

    # The Contour that the Coordinate belongs to.
    attr_reader :contour
    # The X location (in units of mm).
    attr_reader :x
    # The Y location (in units of mm).
    attr_reader :y
    # The Z location (in units of mm).
    attr_reader :z

    # Creates a new Coordinate instance.
    #
    # === Parameters
    #
    # * <tt>x</tt> -- Float. The location of the Contour point along the x-axis (in units of mm).
    # * <tt>y</tt> -- Float. The location of the Contour point along the y-axis (in units of mm).
    # * <tt>z</tt> -- Float. The location of the Contour point along the z-axis (in units of mm).
    # * <tt>contour</tt> -- The Contour instance (if any) that this Coordinate belongs to.
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
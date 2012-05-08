module RTKIT

  # Contains a X,Y,Z triplet, which along with other Coordinates, defines a Contour.
  #
  # === Relations
  #
  # * The Coordinate belongs to a Contour.
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
      raise ArgumentError, "Invalid argument 'x'. Expected Float, got #{x.class}." unless x.is_a?(Float)
      raise ArgumentError, "Invalid argument 'y'. Expected Float, got #{y.class}." unless y.is_a?(Float)
      raise ArgumentError, "Invalid argument 'z'. Expected Float, got #{z.class}." unless z.is_a?(Float)
      raise ArgumentError, "Invalid argument 'contour'. Expected Contour (or nil), got #{contour.class}." if contour && !contour.is_a?(Contour)
      @contour = contour
      @x = x
      @y = y
      @z = z
      # Register ourselves with the Contour:
      @contour.add_coordinate(self) if contour
    end

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_coordinate)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Returns self.
    #
    def to_coordinate
      self
    end


    # Returns a string where the x, y & z values are separated by a '\'.
    #
    def to_s
      [@x, @y, @z].join("\\")
    end


    private


    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@x, @y, @z]
    end

  end

end
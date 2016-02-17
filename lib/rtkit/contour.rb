module RTKIT

  # Contains DICOM data and methods related to a Contour.
  # A set of Contours in a set of Slices defines a ROI.
  #
  # === Relations
  #
  # * The Contour belongs to a Slice.
  # * A Contour has many Coordinates.
  #
  # === Resources
  #
  # * ROI Contour Module: PS 3.3, C.8.8.6
  # * Patient Based Coordinate System: PS 3.3, C.7.6.2.1.1
  #
  class Contour

    # An array of Coordinates (x,y,z - triplets).
    attr_reader :coordinates
    # Contour Number.
    attr_reader :number
    # The Slice that the Contour belongs to.
    attr_reader :slice
    # Contour Geometric Type.
    attr_reader :type

    # Creates a new Contour instance from x, y and z coordinate arrays. This
    # method also creates and connects any child Coordinate instances as
    # indicated by the coordinate arrays.
    #
    # @param [Array<Float>] x an array of x coordinates
    # @param [Array<Float>] y an array of y coordinates
    # @param [Array<Float>] z an array of z coordinates
    # @param [Slice] slice the Slice instance which the Contour shall be associated with
    # @return [Contour] the created Contour instance
    #
    def self.create_from_coordinates(x, y, z, slice)
      raise ArgumentError, "Invalid argument 'x'. Expected Array, got #{x.class}." unless x.is_a?(Array)
      raise ArgumentError, "Invalid argument 'y'. Expected Array, got #{y.class}." unless y.is_a?(Array)
      raise ArgumentError, "Invalid argument 'z'. Expected Array, got #{z.class}." unless z.is_a?(Array)
      raise ArgumentError, "Invalid argument 'slice'. Expected Slice, got #{slice.class}." unless slice.is_a?(Slice)
      raise ArgumentError, "The coordinate arrays are of unequal length [#{x.length}, #{y.length}, #{z.length}]." unless [x.length, y.length, z.length].uniq.length == 1
      number = slice.roi.num_contours + 1
      # Create the Contour:
      c = self.new(slice, :number => number)
      # Create the Coordinates belonging to this Contour:
      x.each_index do |i|
        Coordinate.new(x[i], y[i], z[i], c)
      end
      return c
    end

    # Creates a new Contour instance from a contour item. This method also
    # creates and connects any Coordinates as indicated by the item.
    #
    # @param [DICOM::Item] contour_item a DICOM item from which to create the Contour
    # @param [Slice] slice the Slice instance which the Contour shall be associated with
    # @return [Contour] the created Contour instance
    #
    def self.create_from_item(contour_item, slice)
      raise ArgumentError, "Invalid argument 'contour_item'. Expected Item, got #{contour_item.class}." unless contour_item.is_a?(DICOM::Item)
      raise ArgumentError, "Invalid argument 'slice'. Expected Slice, got #{slice.class}." unless slice.is_a?(Slice)
      raise ArgumentError, "Invalid argument 'contour_item'. The specified Item does not contain a Contour Data Value (Element '3006,0050')." unless contour_item.value(CONTOUR_DATA)
      number = (contour_item.value(CONTOUR_NUMBER) ? contour_item.value(CONTOUR_NUMBER).to_i : nil)
      type = contour_item.value(CONTOUR_GEO_TYPE)
      #size = contour_item.value(NR_CONTOUR_POINTS) # May be used for QA of the content of the item, but not needed in the Contour object.
      # Create the Contour:
      c = self.new(slice, :type => type, :number => number)
      # Create the Coordinates belonging to this Contour:
      c.create_coordinates(contour_item.value(CONTOUR_DATA))
      return c
    end

    # Creates a new Contour instance.
    #
    # @param [Slice] slice the Slice instance which the Contour shall be associated with
    # @param [Hash] options the options to use for creating the Contour
    # @option options [Integer] :number the contour number
    # @option options [String] :type the contour geometric type (defaults to 'CLOSED_PLANAR')
    #
    def initialize(slice, options={})
      raise ArgumentError, "Invalid argument 'slice'. Expected Slice, got #{slice.class}." unless slice.is_a?(Slice)
      raise ArgumentError, "Invalid option :number. Expected Integer, got #{options[:number].class}." if options[:number] && !options[:number].is_a?(Integer)
      raise ArgumentError, "Invalid option :type. Expected String, got #{options[:type].class}." if options[:type] && !options[:type].is_a?(String)
      # Key attributes:
      @coordinates = Array.new
      @slice = slice
      @type = options[:type] || 'CLOSED_PLANAR'
      @number = options[:number] # don't need a default value for this attribute
      # Register ourselves with the Slice:
      @slice.add_contour(self)
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
      if other.respond_to?(:to_contour)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds a Coordinate instance to this Contour.
    #
    # @param [Coordinate] coordinate a coordinate instance to be associated with this contour
    #
    def add_coordinate(coordinate)
      raise ArgumentError, "Invalid argument 'coordinate'. Expected Coordinate, got #{coordinate.class}." unless coordinate.is_a?(Coordinate)
      @coordinates << coordinate unless @coordinates.include?(coordinate)
    end

    # Creates a string where the coordinates of this contour are packed to a
    # string in the format used in the Contour Data DICOM Element (3006,0050).
    #
    # @return [String] an encoded coordinate string (or an empty string if no coordinates are associated)
    #
    def contour_data
      x, y, z = coords
      return [x, y, z].transpose.flatten.join("\\")
    end

    # Extracts and transposes all coordinates of this contour, such that the
    # coordinates are given in arrays of x, y and z coordinates.
    #
    # @return [Array] the coordinates of this contour, converted to x, y and z arrays
    #
    def coords
      x, y, z = Array.new, Array.new, Array.new
      @coordinates.each do |coord|
        x << coord.x
        y << coord.y
        z << coord.z
      end
      return x, y, z
    end

    # Creates and connects Coordinate instances with this Contour instance
    # by processing the value of the Contour Data element value.
    #
    # @param [String, NilClass] contour_data a string containing x,y,z coordinate triplets separated by '\'
    #
    def create_coordinates(contour_data)
      raise ArgumentError, "Invalid argument 'contour_data'. Expected String (or nil), got #{contour_data.class}." unless [String, NilClass].include?(contour_data.class)
      if contour_data && contour_data != ""
        # Split the number strings, sperated by a '\', into an array:
        string_values = contour_data.split("\\")
        size = string_values.length/3
        # Extract every third value of the string array as x, y, and z, respectively, and collect them as floats instead of strings:
        x = string_values.values_at(*(Array.new(size){|i| i*3    })).collect{|val| val.to_f}
        y = string_values.values_at(*(Array.new(size){|i| i*3+1})).collect{|val| val.to_f}
        z = string_values.values_at(*(Array.new(size){|i| i*3+2})).collect{|val| val.to_f}
        x.each_index do |i|
          Coordinate.new(x[i], y[i], z[i], self)
        end
      end
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

    # Returns self.
    #
    # @return [Contour] self
    #
    def to_contour
      self
    end

    # Creates a Contour Sequence Item from the attributes of the Contour.
    #
    # @return [DICOM::Item] the created DICOM item
    #
    def to_item
      # FIXME: We need to decide on how to principally handle the situation when an image series has not been
      # loaded, and how to set up the ROI slices. A possible solution is to create Image instances if they hasn't been loaded.
      item = DICOM::Item.new
      item.add(DICOM::Sequence.new(CONTOUR_IMAGE_SQ))
      item[CONTOUR_IMAGE_SQ].add_item
      item[CONTOUR_IMAGE_SQ][0].add(DICOM::Element.new(REF_SOP_CLASS_UID, @slice.image ? @slice.image.series.class_uid : '1.2.840.10008.5.1.4.1.1.2')) # Deafult to CT if image ref. doesn't exist.
      item[CONTOUR_IMAGE_SQ][0].add(DICOM::Element.new(REF_SOP_UID, @slice.uid))
      item.add(DICOM::Element.new(CONTOUR_GEO_TYPE, @type))
      item.add(DICOM::Element.new(NR_CONTOUR_POINTS, @coordinates.length.to_s))
      item.add(DICOM::Element.new(CONTOUR_NUMBER, @number.to_s))
      item.add(DICOM::Element.new(CONTOUR_DATA, contour_data))
      return item
    end

    # Moves the coordinates of this contour according to the given offset
    # vector.
    #
    # @param [Float] x the offset along the x axis (in units of mm)
    # @param [Float] y the offset along the y axis (in units of mm)
    # @param [Float] z the offset along the z axis (in units of mm)
    #
    def translate(x, y, z)
      @coordinates.each do |c|
        c.translate(x, y, z)
      end
    end


    private


    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@coordinates, @number, @type]
    end

  end
end
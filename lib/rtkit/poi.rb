module RTKIT

  # Contains DICOM data and methods related to a Point of Interest, defined in a Structure Set.
  #
  # === Relations
  #
  # * A POI has a Coordinate.
  #
  class POI < Structure

    # The POI's coordinate.
    attr_reader :coordinate
    # The Image which the POI is located to.
    attr_reader :image
    # The Image which the POI is located to.
    attr_reader :image
    # The Referenced SOP Instance UID.
    attr_reader :uid

    # Creates a new POI instance.
    #
    # @param [String] name the POI name
    # @param [Integer] number the POI number
    # @param [Frame] frame the Frame instance which this POI is associated with
    # @param [StructureSet] struct the StructureSet instance that this POI belongs to
    # @param [Hash] options the options to use for creating the POI
    # @option options [String] :algorithm the POI generation algorithm (defaults to 'Automatic')
    # @option options [String] :color the POI display color (defaults to a random color string (format: 'x\y\z' where [x,y,z] is a byte (0-255)))
    # @option options [String] :interpreter the POI interpreter (defaults to 'RTKIT')
    # @option options [String] :type the POI interpreted type (defaults to 'CONTROL')
    # @option options [String] :uid the SOP Instance UID string reference of the POI
    #
    def initialize(name, number, frame, struct, options={})
      raise ArgumentError, "Invalid argument 'name'. Expected String, got #{name.class}." unless name.is_a?(String)
      raise ArgumentError, "Invalid argument 'number'. Expected Integer, got #{number.class}." unless number.is_a?(Integer)
      raise ArgumentError, "Invalid argument 'frame'. Expected Frame, got #{frame.class}." unless frame.is_a?(Frame)
      raise ArgumentError, "Invalid argument 'struct'. Expected StructureSet, got #{struct.class}." unless struct.is_a?(StructureSet)
      raise ArgumentError, "Invalid option :algorithm. Expected String, got #{options[:algorithm].class}." if options[:algorithm] && !options[:algorithm].is_a?(String)
      raise ArgumentError, "Invalid option :color. Expected String, got #{options[:color].class}." if options[:color] && !options[:color].is_a?(String)
      raise ArgumentError, "Invalid option :interpreter. Expected String, got #{options[:interpreter].class}." if options[:interpreter] && !options[:interpreter].is_a?(String)
      raise ArgumentError, "Invalid option :type. Expected String, got #{options[:type].class}." if options[:type] && !options[:type].is_a?(String)
      super(name, number, frame, struct, options)
      @uid = options[:uid] || RTKIT.sop_uid
      # Register ourselves with the Frame and StructureSet:
      @frame.add_structure(self)
      @struct.add_structure(self)
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
      if other.respond_to?(:to_poi)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Sets the coordinate attribute.
    #
    # @param [Coordinate] coordinate a coordinate instance to be associated with this POI
    #
    def coordinate=(value)
      @coordinate = value && value.to_coordinate
    end

    # Sets the algorithm attribute.
    #
    # @param [NilClass, #to_s] value the POI generation algorithm (3006,0036)
    #
    def algorithm=(value)
      @algorithm = value && value.to_s
    end

=begin
    # Attaches a POI to a specified ImageSeries.
    #
    # This method can be useful when you have multiple segmentations based on
    # the same image series from multiple raters (perhaps as part of a
    # comparison study), and the rater's software has modified the UIDs of the
    # original image series, so that the references of the returned Structure
    # Set does not match your original image series.
    #
    # @param [Series] series the new ImageSeries instance which the POI shall be associated with
    #
    def attach_to(series)
      raise ArgumentError, "Invalid argument 'series'. Expected ImageSeries, got #{series.class}." unless series.is_a?(Series)
      # Change struct association if indicated:
      if series.struct != @struct
        @struct.remove_structure(self)
        StructureSet.new(RTKIT.series_uid, series) unless series.struct
        series.struct.add_poi(self)
        @struct = series.struct
      end
      # Change Frame if different:
      if @frame != series.frame
        @frame = series.frame
      end
      # How to match the POI to a new image? It's not possible to deduce a Plane
      # equation for a single point. Leaving this method unspecified for now.
    end
=end

    # Creates a POI Contour Sequence Item from the attributes of the POI instance.
    #
    # @return [DICOM::Item] a POI contour sequence item
    #
    def contour_item
      item = DICOM::Item.new
      item.add(DICOM::Element.new(ROI_COLOR, @color))
      item.add(DICOM::Element.new(REF_ROI_NUMBER, @number.to_s))
      s = DICOM::Sequence.new(CONTOUR_SQ)
      item.add(s)
      i = s.add_item
      i.add(DICOM::Sequence.new(CONTOUR_IMAGE_SQ))
      i[CONTOUR_IMAGE_SQ].add_item
      i[CONTOUR_IMAGE_SQ][0].add(DICOM::Element.new(REF_SOP_CLASS_UID, @image ? @image.series.class_uid : '1.2.840.10008.5.1.4.1.1.2')) # Deafult to CT if image ref. doesn't exist.
      i[CONTOUR_IMAGE_SQ][0].add(DICOM::Element.new(REF_SOP_UID, @uid))
      i.add(DICOM::Element.new(CONTOUR_GEO_TYPE, 'POINT'))
      i.add(DICOM::Element.new(NR_CONTOUR_POINTS, '1'))
      i.add(DICOM::Element.new(CONTOUR_NUMBER, @number.to_s))
      i.add(DICOM::Element.new(CONTOUR_DATA, @coordinate.to_s)) if @coordinate
      return item
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

    # Sets up the POI image and coordinate references by processing its contour
    # sequence.
    #
    # @param [DICOM::Sequence] contour_sequence a Contour Sequence
    #
    def setup(contour_sequence)
      raise ArgumentError, "Invalid argument 'contour_sequence'. Expected DICOM::Sequence, got #{contour_sequence.class}." unless contour_sequence.is_a?(DICOM::Sequence)
      contour_item = contour_sequence[0]
      # Image reference:
      sop_uid = contour_item[CONTOUR_IMAGE_SQ][0].value(REF_SOP_UID)
      @image = @frame.image(sop_uid)
      # POI coordinates:
      self.coordinate = Coordinate.new(*contour_item.value(CONTOUR_DATA).split("\\")[0..2])
    end

    # Returns self.
    #
    # @return [POI] self
    #
    def to_poi
      self
    end

    # Moves the POI by applying the given offset vector to its coordinates.
    #
    # @param [Float] x the offset along the x axis (in units of mm)
    # @param [Float] y the offset along the y axis (in units of mm)
    # @param [Float] z the offset along the z axis (in units of mm)
    #
    def translate(x, y, z)
      @coordinate.translate(x, y, z)
    end


    private


    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       super << @image << @coordinate
    end

  end
end
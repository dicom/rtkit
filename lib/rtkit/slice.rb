module RTKIT

  # Contains DICOM data and methods related to an image Slice, in which a
  # number of contours are defined.
  #
  # === Relations
  #
  # * A Slice is characterized by a SOP Instance UID, which relates it to an Image.
  # * A ROI has many Slices, as derived from the Structure Set.
  # * A Slice has many Contours.
  #
  class Slice

    # An array containing the Contours defined for this Slice.
    attr_reader :contours
    # The Slice's Image reference.
    attr_reader :image
    # The ROI that the Slice belongs to.
    attr_reader :roi
    # The Referenced SOP Instance UID.
    attr_reader :uid

    # Creates a new Slice instance from an array of contour items belonging to
    # a single slice of a particular ROI. This method also creates and connects
    # any child structures as indicated in the items (e.g. contours).
    #
    # @param [String] sop_uid the referenced SOP Instance UID string of this slice
    # @param [Array<DICOM::Item>] contour_items items belonging to the same slice from the Contour Sequence in ROI Contour Sequence
    # @param [ROI] roi the ROI instance which the Slice shall be associated with
    # @return [Slice] the created Slice instance
    #
    def self.create_from_items(sop_uid, contour_items, roi)
      raise ArgumentError, "Invalid argument 'sop_uid'. Expected String, got #{sop_uid.class}." unless sop_uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'contour_items'. Expected Array, got #{contour_items.class}." unless contour_items.is_a?(Array)
      raise ArgumentError, "Invalid argument 'roi'. Expected ROI, got #{roi.class}." unless roi.is_a?(ROI)
      # Create the Slice instance:
      slice = self.new(sop_uid, roi)
      # Create the Contours belonging to the ROI in this Slice:
      contour_items.each do |contour_item|
        Contour.create_from_item(contour_item, slice)
      end
      return slice
    end

    # Creates a new Slice instance.
    #
    # @param [String] sop_uid the referenced SOP Instance UID string of this slice
    # @param [ROI] roi the ROI instance which the Slice shall be associated with
    #
    def initialize(sop_uid, roi)
      raise ArgumentError, "Invalid argument 'sop_uid'. Expected String, got #{sop_uid.class}." unless sop_uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'roi'. Expected ROI, got #{roi.class}." unless roi.is_a?(ROI)
      # Key attributes:
      @contours = Array.new
      @uid = sop_uid
      @roi = roi
      # Set up the Image reference:
      @image = roi.frame.image(@uid)
      # Register ourselves with the ROI:
      @roi.add_slice(self)
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
      if other.respond_to?(:to_slice)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds a Contour instance to this Slice.
    #
    # @param [Contour] contour a contour instance to be associated with this slice
    #
    def add_contour(contour)
      raise ArgumentError, "Invalid argument 'contour'. Expected Contour, got #{contour.class}." unless contour.is_a?(Contour)
      @contours << contour unless @contours.include?(contour)
    end

    # Calculates the area defined by the contours of this slice.
    #
    # @return [Float] the delineated area (in units of square millimeters)
    #
    def area
      bin_image.area
    end

    # Attaches a Slice to an Image instance belonging to the specified
    # ImageSeries, by setting the Image reference of the Slice to an Image
    # instance which matches the coordinates of the Slice's Contour(s).
    #
    # This method can be useful when you have multiple segmentations based on the same image series
    # from multiple raters (perhaps as part of a comparison study), and the rater's software has modified
    # the UIDs of the original image series, so that the references of the returned Structure Set does
    # not match your original image series. This method uses coordinate information to calculate plane
    # equations, which allows it to identify the corresponding image slice even in the case of
    # slice geometry being non-perpendicular with respect to the patient geometry (direction cosine values != [0,1]).
    #
    # @param [Series] series the new ImageSeries instance which the Slice shall be associated with through its images
    # @raise [ArgumentError] if a suitable match is not found for the Slice
    #
    def attach_to(series)
      raise ArgumentError, "Invalid argument 'series'. Expected ImageSeries, got #{series.class}." unless series.is_a?(Series)
      # Do not bother to attempt this change if we have an image reference and this image instance already belongs to the series:
      if @image && !series.image(@image.uid) or !@image
        # Query the ImageSeries for an Image instance that matches the Plane of this Slice:
        matched_image = series.match_image(plane)
        if matched_image
          @image = matched_image
          @uid = matched_image.uid
        else
          raise "No matching Image was found for this Slice."
        end
      end
    end

    # Creates a binary segmented image, from the contours defined for this
    # slice, applied to the referenced Image instance.
    #
    # @param [Image] source_image the image on which the binary image will be applied (defaults to the referenced (anatomical) image, but may be e.g. a dose image)
    # @return [BinImage] the derived binary image instance (with dimensions equal to that of the source image)
    #
    def bin_image(source_image=@image)
      raise "Referenced ROI Slice Image is missing from the dataset. Unable to construct image." unless @image
      bin_img = BinImage.new(NArray.byte(source_image.columns, source_image.rows), source_image)
      # Delineate and fill for each contour, then create the final image:
      @contours.each_with_index do |contour, i|
        x, y, z = contour.coords
        bin_img.add(source_image.binary_image(x, y, z))
      end
      return bin_img
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

    # Sets the image attribute.
    #
    # @param [NilClass, #to_slice_image] value a SliceImage instance
    #
    def image=(value)
      @image = value && value.to_slice_image
    end

    # Gives a Plane corresponding to this Slice geometry. The plane is
    # calculated from coordinates belonging to this instance.
    #
    # @return [Plane] the derived plane
    # @raise [RuntimeError] unless the required number of coordinates are present (at least 3)
    #
    def plane
      # Such a change is only possible if the Slice instance has a Contour with at least three Coordinates:
      raise "This Slice does not contain a Contour. Plane determination is not possible." if @contours.length == 0
      raise "This Slice does not contain a Contour with at least 3 Coordinates. Plane determination is not possible." if @contours.first.coordinates.length < 3
      # Get three coordinates from our Contour:
      contour = @contours.first
      num_coords = contour.coordinates.length
      c1 = contour.coordinates.first
      c2 = contour.coordinates[num_coords / 3]
      c3 = contour.coordinates[2 * num_coords / 3]
      return Plane.calculate(c1, c2, c3)
    end

    # Gives the position of this slice.
    #
    # @return [Float, NilClass] the slice position of the referenced image (or nil if no image is referenced)
    #
    def pos
      return @image ? @image.pos_slice : nil
    end

    # Returns self.
    #
    # @return [Slice] self
    #
    def to_slice
      self
    end

    # Moves the coordinates of the contours of this slice according to the
    # given offset vector.
    #
    # @param [Float] x the offset along the x axis (in units of mm)
    # @param [Float] y the offset along the y axis (in units of mm)
    # @param [Float] z the offset along the z axis (in units of mm)
    #
    def translate(x, y, z)
      @contours.each do |c|
        c.translate(x, y, z)
      end
    end


    private


    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@contours, @image, @uid]
    end

  end
end
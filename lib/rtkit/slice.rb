module RTKIT

  # Contains DICOM data and methods related to an Image Slice, in which a set of contours are defined.
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

    # Creates a new Slice instance from an array of contour items belonging to a single slice of a particular ROI.
    # This method also creates and connects any child structures as indicated in the items (e.g. Contours).
    # Returns the Slice.
    #
    # === Parameters
    #
    # * <tt>sop_uid</tt> -- The SOP Instance UID reference for this slice.
    # * <tt>contour_item</tt> -- An array of contour items from the Contour Sequence in ROI Contour Sequence, belonging to the same slice.
    # * <tt>roi</tt> -- The ROI instance that this Slice belongs to.
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
    # === Parameters
    #
    # * <tt>sop_uid</tt> -- The SOP Instance UID reference for this slice.
    # * <tt>roi</tt> -- The ROI instance that this Slice belongs to.
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

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_slice)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds a Contour instance to this Slice.
    #
    def add_contour(contour)
      raise ArgumentError, "Invalid argument 'contour'. Expected Contour, got #{contour.class}." unless contour.is_a?(Contour)
      @contours << contour unless @contours.include?(contour)
    end

    # Calculates the area defined by the contours of this slice.
    # Returns a float value, in units of millimeters squared.
    #
    def area
      bin_image.area
    end

    # Attaches a Slice to an Image instance belonging to the specified ImageSeries,
    # by setting the Image reference of the Slice to an Image instance which matches
    # the coordinates of the Slice's Contour(s).
    # Raises an exception if a suitable match is not found for the Slice.
    #
    # === Notes
    #
    # This method can be useful when you have multiple segmentations based on the same image series
    # from multiple raters (perhaps as part of a comparison study), and the rater's software has modified
    # the UIDs of the original image series, so that the references of the returned Structure Set does
    # not match your original image series. This method uses coordinate information to calculate plane
    # equations, which allows it to identify the corresponding image slice even in the case of
    # slice geometry being non-perpendicular with respect to the patient geometry (direction cosine values != [0,1]).
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

    # Creates a binary segmented image, from the contours defined for this slice, applied to the referenced Image instance.
    # Returns an BinImage instance, containing a 2d NArray with dimensions: columns*rows
    #
    # === Parameters
    #
    # * <tt>source_image</tt> -- The image on which the binary volume will be applied (defaults to the referenced image, but may be e.g. a dose 'image').
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

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Returns the Plane corresponding to this Slice.
    # The plane is calculated from coordinates belonging to this instance,
    # and an error is raised if not enough Coordinates are present (at least 3 required).
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

    # Returns the position of this slice, which in effect
    # is the pos_slice attribute of the referenced image.
    #
    def pos
      return @image ? @image.pos_slice : nil
    end

    # Returns self.
    #
    def to_slice
      self
    end


    private


    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@contours, @image, @uid]
    end

  end
end
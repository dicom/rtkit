module RTKIT

  # The ImageSeries class contains methods that are specific for the slice based image modalites (e.g. CT, MR).
  #
  # === Inheritance
  #
  # * ImageSeries inherits all methods and attributes from the Series class.
  #
  class ImageSeries < Series

    include ImageParent

    # The Frame (of Reference) which this ImageSeries belongs to.
    attr_accessor :frame
    # An array of Image references.
    attr_reader :images
    # A hash containing SOP Instance UIDs as key and Slice Positions as value.
    attr_reader :slices
    # A hash containing Slice Positions as key and SOP Instance UIDS as value.
    attr_accessor :sop_uids
    # An array of Structure Sets associated with this Image Series.
    attr_reader :structs

    # Creates a new ImageSeries instance by loading series information from the specified DICOM object.
    # The Series' UID string value is used to uniquely identify an ImageSeries.
    #
    # === Parameters
    #
    # * <tt>dcm</tt> -- An instance of a DICOM object (DICOM::DObject) with an image type modality (e.g. CT or MR).
    # * <tt>study</tt> -- The Study instance that this ImageSeries belongs to.
    #
    def self.load(dcm, study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'study'. Expected Study, got #{study.class}." unless study.is_a?(Study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject with an Image Series type modality, got #{dcm.value(MODALITY)}." unless IMAGE_SERIES.include?(dcm.value(MODALITY))
      # Required attributes:
      modality = dcm.value(MODALITY)
      series_uid = dcm.value(SERIES_UID)
      # Optional attributes:
      class_uid = dcm.value(SOP_CLASS)
      date = dcm.value(SERIES_DATE)
      time = dcm.value(SERIES_TIME)
      description = dcm.value(SERIES_DESCR)
      # Check if a Frame with the given UID already exists, and if not, create one:
      frame = study.patient.dataset.frame(dcm.value(FRAME_OF_REF)) || frame = study.patient.create_frame(dcm.value(FRAME_OF_REF), dcm.value(POS_REF_INDICATOR))
      # Create the ImageSeries instance:
      is = self.new(series_uid, modality, frame, study, :class_uid => class_uid, :date => date, :time => time, :description => description)
      is.add(dcm)
      # Add our ImageSeries instance to its corresponding Frame:
      frame.add_series(is)
      return is
    end

    # Creates a new ImageSeries instance.
    #
    # === Parameters
    #
    # * <tt>series_uid</tt> -- The Series Instance UID string.
    # * <tt>modality</tt> -- The Modality string of the ImageSeries, e.g. 'CT' or 'MR'.
    # * <tt>frame</tt> -- The Frame instance that this ImageSeries belongs to.
    # * <tt>study</tt> -- The Study instance that this ImageSeries belongs to.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:class_uid</tt> -- String. The SOP Class UID (DICOM tag '0008,0016').
    # * <tt>:date</tt> -- String. The Series Date (DICOM tag '0008,0021').
    # * <tt>:time</tt> -- String. The Series Time (DICOM tag '0008,0031').
    # * <tt>:description</tt> -- String. The Series Description (DICOM tag '0008,103E').
    #
    def initialize(series_uid, modality, frame, study, options={})
      raise ArgumentError, "Invalid argument 'series_uid'. Expected String, got #{series_uid.class}." unless series_uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'modality'. Expected String, got #{modality.class}." unless modality.is_a?(String)
      raise ArgumentError, "Invalid argument 'frame'. Expected Frame, got #{frame.class}." unless frame.is_a?(Frame)
      raise ArgumentError, "Invalid argument 'study'. Expected Study, got #{study.class}." unless study.is_a?(Study)
      raise ArgumentError, "Invalid argument 'modality'. Expected an Image Series type modality, got #{modality}." unless IMAGE_SERIES.include?(modality)
      # Pass attributes to Series initialization:
      super(series_uid, modality, study, options)
      # Key attributes:
      @frame = frame
      # Default attributes:
      @slices = Hash.new
      @sop_uids = Hash.new
      @images = Array.new
      @structs = Array.new
      @image_positions = Hash.new
      # A hash with the associated StructureSet's UID as key and the instance of the StructureSet that belongs to this ImageSeries as value:
      @associated_structs = Hash.new
      # Register ourselves with the study & frame:
      @study.add_series(self)
      @frame.add_series(self)
    end

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_image_series)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds a DICOM image object to the ImageSeries, by creating a new SliceImage instance linked to this ImageSeries.
    #
    def add(dcm)
      SliceImage.load(dcm, self)
    end

    # Adds an Image to this ImageSeries.
    #
    def add_image(image)
      raise ArgumentError, "Invalid argument 'image'. Expected Image, got #{image.class}." unless image.is_a?(Image)
      @images << image unless @frame.image(image.uid)
      @slices[image.uid] = image.pos_slice
      @image_positions[image.pos_slice.round(2)] = image
      @sop_uids[image.pos_slice] = image.uid
      # The link between image uid and image instance is kept in the Frame, instead of the ImageSeries:
      @frame.add_image(image) unless @frame.image(image.uid)
    end

    # Adds a StructureSet to this ImageSeries.
    #
    def add_struct(struct)
      raise ArgumentError, "Invalid argument 'struct'. Expected StructureSet, got #{struct.class}." unless struct.is_a?(StructureSet)
      # Do not add it again if the struct already belongs to this instance:
      @structs << struct unless @associated_structs[struct.uid]
      @associated_structs[struct.uid] = struct
    end

=begin
    # Returns the array position in the sorted array of slices that is closest to the provided slice.
    # If slice value is out of bounds (it is further from boundaries than the slice interval), false is returned.
    def corresponding_slice(slice, slices)
      above_pos = (0...slices.length).select{|x| slices[x]>=slice}.first
      below_pos = (0...slices.length).select{|x| slices[x]<=slice}.last
      # With Ruby 1.9 this can supposedly be simplified to:  below_pos = slices.index{|x| x<=slice}
      # Exact match or between two slices?
      if above_pos == below_pos
        # Exact match (both point to the same index).
        slice_index = above_pos
      else
        # Value in between. Return the index of the value that is closest to our value.
        if (slice-slices[above_pos]).abs < (slice-slices[below_pos]).abs
          slice_index = above_pos
        else
          slice_index = below_pos
        end
      end
      return slice_index
    end
=end

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Returns the Image instance mathcing the specified SOP Instance UID (if an argument is used).
    # If a specified UID doesn't match, nil is returned.
    # If no argument is passed, the first Image instance associated with the ImageSeries is returned.
    #
    # === Parameters
    #
    # * <tt>uid</tt> -- String. The value of the SOP Instance UID element of the Image.
    #
    def image(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        if args.first.is_a?(Float)
          # Presumably an image position:
          return @image_positions[args.first.round(2)]
        else
          # Presumably a uid string:
          return @frame.image(args.first)
        end
      else
        # No argument used, therefore we return the first Image instance:
        return @images.first
      end
    end

    # Analyses the Image instances belonging to this ImageSeries to determine
    # if there is an Image which matches the specified Plane.
    # Returns the Image if a match is found, nil if not.
    #
    # === Parameters
    #
    # * <tt>plane</tt> -- The Plane instance which images will be matched against.
    #
    def match_image(plane)
      raise ArgumentError, "Invalid argument 'plane'. Expected Plane, got #{plane.class}." unless plane.is_a?(Plane)
      matching_image = nil
      planes_in_series = Array.new
      @images.each do |image|
        # Get three coordinates from the image:
        col_indices = NArray.to_na([0,image.columns/2, image.columns-1])
        row_indices = NArray.to_na([image.rows/2, image.rows-1, 0])
        x, y, z = image.coordinates_from_indices(col_indices, row_indices)
        coordinates = Array.new
        x.length.times do |i|
          coordinates << Coordinate.new(x[i], y[i], z[i])
        end
        # Determine the image plane:
        planes_in_series << Plane.calculate(coordinates[0], coordinates[1], coordinates[2])
      end
      # Search for a match amongst the planes of this series:
      index = plane.match(planes_in_series)
      matching_image = @images[index] if index
      return matching_image
    end

    # Returns all ROIs having the same Frame of Reference as this
    # image series from the structure set(s) belonging to this series.
    # Returns the ROIs in an Array. If no ROIs are matched, an empty array is returned.
    #
    def rois
      frame_rois = Array.new
      structs.each do |struct|
        frame_rois << struct.rois_in_frame(@frame.uid)
      end
      return frame_rois.flatten
    end

    # Sets the resolution of all images in this image series.
    # The images will either be expanded or cropped depending on whether
    # the specified resolution is bigger or smaller than the existing one.
    #
    # === Parameters
    #
    # * <tt>columns</tt> -- Integer. The number of columns applied to the cropped/expanded image series.
    # * <tt>rows</tt> -- Integer. The number of rows applied to the cropped/expanded image series.
    #
    # === Options
    #
    # * <tt>:hor</tt> -- Symbol. The side (in the horisontal image direction) to apply the crop/border (:left, :right or :even (default)).
    # * <tt>:ver</tt> -- Symbol. The side (in the vertical image direction) to apply the crop/border (:bottom, :top or :even (default)).
    #
    def set_resolution(columns, rows, options={})
      @images.each do |img|
        img.set_resolution(columns, rows, options)
      end
    end

    # Returns the StructureSet instance mathcing the specified SOP Instance UID (if an argument is used).
    # If a specified UID doesn't match, nil is returned.
    # If no argument is passed, the first StructureSet instance associated with the ImageSeries is returned.
    #
    # === Parameters
    #
    # * <tt>uid</tt> -- String. The value of the SOP Instance UID element.
    #
    def struct(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        raise ArgumentError, "Expected String (or nil), got #{args.first.class}." unless [String, NilClass].include?(args.first.class)
        return @associated_structs[args.first]
      else
        # No argument used, therefore we return the first StructureSet instance:
        return @structs.first
      end
    end

    # Returns self.
    #
    def to_image_series
      self
    end

    # Writes all images in this image series to DICOM files in the specified folder.
    # The file names are set by the image's UID string, followed by a '.dcm' extension.
    #
    def write(path)
      @images.each do |img|
        img.write(path + img.uid + '.dcm')
      end
    end


    private


    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@images, @series_uid, @structs]
    end

  end
end
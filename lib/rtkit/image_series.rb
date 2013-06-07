module RTKIT

  # The ImageSeries class contains methods that are specific for the slice
  # based image modalites (e.g. CT, MR).
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

    # Creates a new ImageSeries instance by loading series information from the
    # specified DICOM object. The Series' UID string value is used to uniquely
    # identify an ImageSeries.
    #
    # @param [DICOM::DObject] dcm an image type modality DICOM object from which to create the ImageSeries
    # @param [Study] study the Study instance which the ImageSeries shall be associated with
    # @return [ImageSeries] the created ImageSeries instance
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
    # @param [String] series_uid the Series Instance UID string
    # @param [String] modality the modality string of the image series (e.g. 'CT' or 'MR')
    # @param [String] frame the Frame instance which this ImageSeries is associated with
    # @param [Study] study the Study instance which this ImageSeries is associated with
    # @param [Hash] options the options to use for creating the image series
    # @option options [String] :class_uid the SOP Class UID (DICOM tag '0008,0016')
    # @option options [String] :date the Series Date (DICOM tag '0008,0021')
    # @option options [String] :time the Series Time (DICOM tag '0008,0031')
    # @option options [String] :description the Series Description (DICOM tag '0008,103E')
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

    # Checks for equality.
    #
    # Other and self are considered equivalent if they are
    # of compatible types and their attributes are equivalent.
    #
    # @param other an object to be compared with self.
    # @return [Boolean] true if self and other are considered equivalent
    #
    def ==(other)
      if other.respond_to?(:to_image_series)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Registers a DICOM object to the image series, and processes it to create
    # (and reference) a slice image instance linked to this image series.
    #
    # @param [DICOM::DObject] dcm an image type modality DICOM object
    #
    def add(dcm)
      SliceImage.load(dcm, self)
    end

    # Adds an Image to this ImageSeries.
    #
    # @param [Image] image an image instance to be associated with this image series
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
    # @param [Image] struct a structure set instance to be associated with this image series
    #
    def add_struct(struct)
      raise ArgumentError, "Invalid argument 'struct'. Expected StructureSet, got #{struct.class}." unless struct.is_a?(StructureSet)
      # Do not add it again if the struct already belongs to this instance:
      @structs << struct unless @associated_structs[struct.uid]
      @associated_structs[struct.uid] = struct
    end

=begin
    # Gives the index in the sorted array of slices that positionally is
    # closest to the provided slice.
    #
    # @note If the slice value is out of bounds (it is further from the
    #   boundaries than the slice interval), then false is returned.
    # @param [Float] slice the slice position
    # @param [Array<Float>] slices an array of slice positions
    # @return [Fixnum, FalseClass] the determined slice index (or false if no match)
    #
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

    # Computes a hash code for this object.
    #
    # @note Two objects with the same attributes will have the same hash code.
    #
    # @return [Fixnum] the object's hash code
    #
    def hash
      state.hash
    end

    # Gives the Image instance mathcing the specified UID or image position.
    #
    # @overload image(pos)
    #   @param [Float] pos image slice position
    #   @return [SliceImage, NilClass] the matched image (or nil if no image is matched)
    # @overload image(uid)
    #   @param [String] uid image UID
    #   @return [SliceImage, NilClass] the matched image (or nil if no image is matched)
    # @overload image
    #   @return [SliceImage, NilClass] the first image of this instance (or nil if no child images exists)
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

    # Analyses the images belonging to this ImageSeries to determine if there
    # is any image with a geometry that matches the specified plane.
    #
    # @param [Plane] plane an image plane to be compared against the associated images
    # @return [SliceImage, NilClass] the matched image (or nil if no image is matched)
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

    # Gives all ROIs having the same Frame of Reference as this image series
    # from the structure set(s) belonging to this series.
    #
    # @return [Array<ROI>] the ROIs associated with this image series
    #
    def rois
      frame_rois = Array.new
      structs.each do |struct|
        frame_rois << struct.rois_in_frame(@frame.uid)
      end
      return frame_rois.flatten
    end

    # Sets the resolution of the associated images. The images will either be
    # expanded or cropped depending on whether the specified resolution is
    # bigger or smaller than the existing one.
    #
    # @param [Integer] columns the number of columns in the resized images
    # @param [Integer] rows the number of rows in the resized images
    # @param [Hash] options the options to use for changing the image resolution
    # @option options [Float] :hor the side (in the horisontal image direction) at which to apply the crop/border operation (:left, :right or :even (default))
    # @option options [Float] :ver the side (in the vertical image direction) at which to apply the crop/border operation (:bottom, :top or :even (default))
    #
    def set_resolution(columns, rows, options={})
      @images.each do |img|
        img.set_resolution(columns, rows, options)
      end
    end

    # Gives the StructureSet instance mathcing the specified UID.
    #
    # @overload struct(uid)
    #   @param [String] uid the structure set SOP instance UID
    #   @return [StructureSet, NilClass] the matched structure set (or nil if no structure set is matched)
    # @overload struct
    #   @return [StructureSet, NilClass] the first structure set of this instance (or nil if no child structure sets exists)
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
    # @return [ImageSeries] self
    #
    def to_image_series
      self
    end

    # Writes all images in this image series to DICOM files in the specified
    # folder. The file names are set by the image's UID string, followed by a
    # '.dcm' extension.
    #
    # @deprecated This method is not considered principal and will probably be removed,
    # @param [String] path the directory in which to write the files
    #
    def write(path)
      @images.each do |img|
        img.write(path + img.uid + '.dcm')
      end
    end


    private


    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@images, @series_uid, @structs]
    end

  end
end
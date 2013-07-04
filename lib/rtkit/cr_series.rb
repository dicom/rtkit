module RTKIT

  # The CRSeries class contains methods that are specific for series of images
  # of unknown characteristics (i.e. they can be either projection type images
  # or slice type images without it being possibly to determine at load time).
  #
  # === Inheritance
  #
  # * CRSeries inherits all methods and attributes from the Series class.
  #
  class CRSeries < Series

    include ImageParent

    # An array of Image references.
    attr_reader :images

    # Creates a new CRSeries instance by loading series information from the
    # specified DICOM object. The Series' UID string value is used to uniquely
    # identify an CRSeries.
    #
    # @param [DICOM::DObject] dcm a DICOM object of CR modality from which to create the CRSeries
    # @param [Study] study the Study instance which the CRSeries shall be associated with
    # @return [CRSeries] the created CRSeries instance
    #
    def self.load(dcm, study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'study'. Expected Study, got #{study.class}." unless study.is_a?(Study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject with modality 'CR', got #{dcm.value(MODALITY)}." unless dcm.value(MODALITY) == 'CR'
      # Required attributes:
      series_uid = dcm.value(SERIES_UID)
      # Optional attributes:
      class_uid = dcm.value(SOP_CLASS)
      date = dcm.value(SERIES_DATE)
      time = dcm.value(SERIES_TIME)
      description = dcm.value(SERIES_DESCR)
      # Create the CRSeries instance:
      crs = self.new(series_uid, modality, study, :class_uid => class_uid, :date => date, :time => time, :description => description)
      crs.add(dcm)
      return crs
    end

    # Creates a new CRSeries instance.
    #
    # @param [String] series_uid the Series Instance UID string
    # @param [Study] study the Study instance which this CRSeries is associated with
    # @param [Hash] options the options to use for creating the image series
    # @option options [String] :class_uid the SOP Class UID (DICOM tag '0008,0016')
    # @option options [String] :date the Series Date (DICOM tag '0008,0021')
    # @option options [String] :time the Series Time (DICOM tag '0008,0031')
    # @option options [String] :description the Series Description (DICOM tag '0008,103E')
    #
    def initialize(series_uid, study, options={})
      raise ArgumentError, "Invalid argument 'series_uid'. Expected String, got #{series_uid.class}." unless series_uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'study'. Expected Study, got #{study.class}." unless study.is_a?(Study)
      # Pass attributes to Series initialization:
      super(series_uid, 'CR', study, options)
      # Default attributes:
      @images = Array.new
      @image_uids = Hash.new
      # Register ourselves with the study:
      @study.add_series(self)
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
      if other.respond_to?(:to_cr_series)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Registers a DICOM object to the cr series, and processes it to create
    # (and reference) an image instance linked to this series.
    #
    # @param [DICOM::DObject] dcm a DICOM object of modality CR
    #
    def add(dcm)
      Image.load(dcm, self)
    end

    # Adds an Image to this CRSeries.
    #
    # @param [Image] image an image instance to be associated with this series
    #
    def add_image(image)
      raise ArgumentError, "Invalid argument 'image'. Expected Image, got #{image.class}." unless image.is_a?(Image)
      @images << image
      @image_uids[image.uid] = image
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

    # Gives the Image instance mathcing the specified UID.
    #
    # @overload image(uid)
    #   @param [String] uid image UID
    #   @return [Image, NilClass] the matched image (or nil if no image is matched)
    # @overload image
    #   @return [Image, NilClass] the first image of this instance (or nil if no child images exists)
    #
    def image(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        return @image_uids[args.first]
      else
        # No argument used, therefore we return the first Image instance:
        return @images.first
      end
    end

    # Returns self.
    #
    # @return [CRSeries] self
    #
    def to_cr_series
      self
    end


    private


    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@images, @series_uid]
    end

  end
end
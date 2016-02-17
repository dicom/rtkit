module RTKIT

  # Contains the DICOM data and methods related to a Frame of Reference.
  #
  # === Relations
  #
  # * A Frame of Reference belongs to a Patient.
  # * A Frame of Reference can have many ImageSeries.
  #
  class Frame

    # An array of ImageSeries belonging to this Frame.
    attr_reader :image_series
    # The Position Reference Indicator (an optional annotation indicating the anatomical reference location).
    attr_reader :indicator
    # The Patient which this Frame of Reference belongs to.
    attr_reader :patient
    # An array of ROIs & POIs belonging to this Frame.
    attr_reader :structures
    # The Frame of Reference UID.
    attr_reader :uid

    # Creates a new Frame instance. The Frame of Reference UID tag value
    # uniquely identifies the Frame.
    #
    # @param [String] uid the frame of reference UID
    # @param [Patient] patient the Patient instance which this Frame is associated with
    # @param [Hash] options the options to use for creating the frame
    # @option options [Boolean] :indicator the Position Reference Indicator string
    #
    def initialize(uid, patient, options={})
      raise ArgumentError, "Invalid argument 'uid'. Expected String, got #{uid.class}." unless uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'patient'. Expected Patient, got #{patient.class}." unless patient.is_a?(Patient)
      raise ArgumentError, "Invalid option :indicator. Expected String, got #{indicator.class}." if options[:indicator] && !options[:indicator].is_a?(String)
      @associated_series = Hash.new
      @associated_instance_uids = Hash.new
      @image_series = Array.new
      @structures = Array.new
      @uid = uid
      @patient = patient
      @indicator = options[:indicator]
      # Register ourselves with the patient and its dataset:
      @patient.add_frame(self)
      @patient.dataset.add_frame(self)
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
      if other.respond_to?(:to_frame)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds an Image to this Frame.
    #
    # @param [Image] image an image instance to be associated with this frame
    #
    def add_image(image)
      raise ArgumentError, "Invalid argument 'image'. Expected Image, got #{image.class}." unless image.is_a?(Image)
      @associated_instance_uids[image.uid] = image
      # If the ImageSeries of an added Image is not connected to this Frame yet, do so:
      add_series(image.series) unless series(image.series.uid)
    end

    # Adds a ROI or POI to this Frame.
    #
    # @param [ROI, POI] structure a structure to be associated with this frame
    #
    def add_structure(structure)
      raise ArgumentError, "Invalid argument 'structure'. Expected ROI/POI, got #{structure.class}." unless structure.respond_to?(:to_roi) or structure.respond_to?(:to_poi)
      @structures << structure unless @structures.include?(structure)
    end

    # Adds an ImageSeries to this Frame.
    #
    # @param [ImageSeries, DoseVolume] series an image series instance to be associated with this frame
    #
    def add_series(series)
      raise ArgumentError, "Invalid argument 'series' Expected ImageSeries or DoseVolume, got #{series.class}." unless [ImageSeries, DoseVolume].include?(series.class)
      @image_series << series
      @associated_series[series.uid] = series
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
    #   @return [Image, NilClass] the first image of the first image series associated with this frame (or nil if no child images exists)
    #
    def image(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        raise ArgumentError, "Expected String (or nil), got #{args.first.class}." unless [String, NilClass].include?(args.first.class)
        return @associated_instance_uids[args.first]
      else
        # No argument used, therefore we return the first Image of the first ImageSeries instance:
        return @image_series.first.image
      end
    end

    # Gives the ROI/POI that matches the specified number or name.
    #
    # @param [String, Fixnum] name_or_number a structure's name or number
    # @return [ROI, POI, NilClass] the matched structure (or nil if no structure was matched)
    #
    def structure(name_or_number)
      raise ArgumentError, "Invalid argument 'name_or_number'. Expected String or Integer, got #{name_or_number.class}." unless [String, Integer, Fixnum].include?(name_or_number.class)
      if name_or_number.is_a?(String)
        @structures.each do |s|
          return s if s.name == name_or_number
        end
      else
        @structures.each do |s|
          return s if s.number == name_or_number
        end
      end
      return nil
    end

    # Gives the ImageSeries instance mathcing the specified UID.
    #
    # @overload series(uid)
    #   @param [String] uid a series instance UID value
    #   @return [ImageSeries, NilClass] the matched image series (or nil if no image series is matched)
    # @overload series
    #   @return [ImageSeries, NilClass] the first image series of this instance (or nil if no child image series exists)
    #
    def series(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        raise ArgumentError, "Expected String (or nil), got #{args.first.class}." unless [String, NilClass].include?(args.first.class)
        return @associated_series[args.first]
      else
        # No argument used, therefore we return the first Study instance:
        return @image_series.first
      end
    end

    # Returns self.
    #
    # @return [Frame] self
    #
    def to_frame
      self
    end


    private


    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@frame_uid, @image_series, @indicator]
    end

  end
end
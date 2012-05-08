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
    # An array of ROI instances belonging to this Frame.
    attr_reader :rois
    # The Frame of Reference UID.
    attr_reader :uid

    # Creates a new Frame instance. The Frame of Reference UID tag value uniquely identifies the Frame.
    #
    # === Parameters
    #
    # * <tt>uid</tt> -- The Frame of Reference UID string.
    # * <tt>patient</tt> -- The Patient instance that this Frame belongs to.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:indicator</tt> -- The Position Reference Indicator string.
    #
    def initialize(uid, patient, options={})
      raise ArgumentError, "Invalid argument 'uid'. Expected String, got #{uid.class}." unless uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'patient'. Expected Patient, got #{patient.class}." unless patient.is_a?(Patient)
      raise ArgumentError, "Invalid option :indicator. Expected String, got #{indicator.class}." if options[:indicator] && !options[:indicator].is_a?(String)
      @associated_series = Hash.new
      @associated_instance_uids = Hash.new
      @image_series = Array.new
      @rois = Array.new
      @uid = uid
      @patient = patient
      @indicator = options[:indicator]
      # Register ourselves with the patient and its dataset:
      @patient.add_frame(self)
      @patient.dataset.add_frame(self)
    end

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_frame)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds an Image to this Frame.
    #
    def add_image(image)
      raise ArgumentError, "Invalid argument 'image'. Expected Image, got #{image.class}." unless image.is_a?(Image)
      #@images << image
      @associated_instance_uids[image.uid] = image
      # If the ImageSeries of an added Image is not connected to this Frame yet, do so:
      add_series(image.series) unless series(image.series.uid)
    end

    # Adds a ROI to this Frame.
    #
    def add_roi(roi)
      raise ArgumentError, "Invalid argument 'roi'. Expected ROI, got #{roi.class}." unless roi.is_a?(ROI)
      @rois << roi unless @rois.include?(roi)
    end

    # Adds an ImageSeries to this Frame.
    #
    def add_series(series)
      raise ArgumentError, "Invalid argument 'series' Expected ImageSeries or DoseVolume, got #{series.class}." unless [ImageSeries, DoseVolume].include?(series.class)
      @image_series << series
      @associated_series[series.uid] = series
    end

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Returns the Image instance mathcing the specified SOP Instance UID (if an argument is used).
    # If a specified UID doesn't match, nil is returned.
    # If no argument is passed, the first Image of the first ImageSeries instance associated with the Frame is returned.
    #
    # === Parameters
    #
    # * <tt>uid</tt> -- String. The value of the Series Instance UID element.
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

    # Returns a ROI that matches the specified number or name.
    # Returns nil if no match is found.
    #
    def roi(name_or_number)
      raise ArgumentError, "Invalid argument 'name_or_number'. Expected String or Integer, got #{name_or_number.class}." unless [String, Integer, Fixnum].include?(name_or_number.class)
      if name_or_number.is_a?(String)
        @rois.each do |r|
          return r if r.name == name_or_number
        end
      else
        @rois.each do |r|
          return r if r.number == name_or_number
        end
      end
      return nil
    end

    # Returns the ImageSeries instance mathcing the specified Series Instance UID (if an argument is used).
    # If a specified UID doesn't match, nil is returned.
    # If no argument is passed, the first Series instance associated with the Frame is returned.
    #
    # === Parameters
    #
    # * <tt>uid</tt> -- String. The value of the Series Instance UID element.
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
    def to_frame
      self
    end


    private


    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@frame_uid, @image_series, @indicator]
    end

  end
end
module RTKIT

  # Contains the DICOM data and methods related to a study.
  #
  # === Relations
  #
  # * A Study belongs to a Patient.
  # * A Study has many Series instances.
  #
  class Study

    # The Study Date.
    attr_reader :date
    # The Study Description.
    attr_reader :description
    # The Study ID.
    attr_reader :id
    # An array of ImageSeries references.
    attr_reader :image_series
    # The Study's Patient reference.
    attr_reader :patient
    # An array of Series references.
    attr_reader :series
    # The Study Instance UID.
    attr_reader :study_uid
    # The Study Time.
    attr_reader :time

    # Creates a new Study instance by loading study information from the
    # specified DICOM object. The Study's UID string value is used to uniquely
    # identify a study.
    #
    # @param [DICOM::DObject] dcm a DICOM object from which to create the Study
    # @param [Patient] patient the Patient instance which the Study shall be associated with
    # @return [Study] the created Study instance
    #
    def self.load(dcm, patient)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'patient'. Expected Patient, got #{patient.class}." unless patient.is_a?(Patient)
      uid = dcm.value(STUDY_UID)
      date = dcm.value(STUDY_DATE)
      time = dcm.value(STUDY_TIME)
      description = dcm.value(STUDY_DESCR)
      id = dcm.value(STUDY_ID)
      study = self.new(uid, patient, :date => date, :time => time, :description => description, :id => id)
      study.add(dcm)
      return study
    end

    # Creates a new Study instance. The Study Instance UID string is used to
    # uniquely identify a study.
    #
    # @param [String] study_uid the Study Instance UID string
    # @param [Patient] patient the Patient instance which this Study is associated with
    # @param [Hash] options the options to use for creating the study
    # @option options [String] :date the study date (DICOM tag '0008,0020')
    # @option options [String] :description the study description (DICOM tag '0008,1030')
    # @option options [String] :id the study ID (DICOM tag '0020,0010')
    # @option options [String] :time the study time (DICOM tag '0008,0030')
    #
    def initialize(study_uid, patient, options={})
      raise ArgumentError, "Invalid argument 'study_uid'. Expected String, got #{study_uid.class}." unless study_uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'patient'. Expected Patient, got #{patient.class}." unless patient.is_a?(Patient)
      raise ArgumentError, "Invalid option ':date'. Expected String, got #{options[:date].class}." if options[:date] && !options[:date].is_a?(String)
      raise ArgumentError, "Invalid option ':time'. Expected String, got #{options[:time].class}." if options[:time] && !options[:time].is_a?(String)
      raise ArgumentError, "Invalid option ':description'. Expected String, got #{options[:description].class}." if options[:description] && !options[:description].is_a?(String)
      raise ArgumentError, "Invalid option ':id'. Expected String, got #{options[:id].class}." if options[:id] && !options[:id].is_a?(String)
      # Key attributes:
      @study_uid = study_uid
      @patient = patient
      # Default attributes:
      @image_series = Array.new
      @series = Array.new
      # A hash with the associated Series' UID as key and the instance of the Series that belongs to this Study as value:
      @associated_series = Hash.new
      @associated_iseries = Hash.new
      # Optional attributes:
      @date = options[:date]
      @time = options[:time]
      @description = options[:description]
      @id = options[:id]
      # Register ourselves with the patient:
      @patient.add_study(self)
    end

    # Registers a DICOM object to the study, and processes it to either create
    # (and reference) a new series instance linked to this study, or
    # registering it with an existing series.
    #
    # @param [DICOM::DObject] dcm a DICOM object
    #
    def add(dcm)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      existing_series = @associated_series[dcm.value(SERIES_UID)]
      if existing_series
        existing_series.add(dcm)
      else
        # New series (series subclass depends on modality):
        case dcm.value(MODALITY)
        when *IMAGE_SERIES
          # Create the ImageSeries:
          s = ImageSeries.load(dcm, self)
        when 'RTSTRUCT'
          s = StructureSet.load(dcm, self)
        when 'RTPLAN'
          s = Plan.load(dcm, self)
        when 'RTDOSE'
          s = RTDose.load(dcm, self)
        when 'RTIMAGE'
          s = RTImage.load(dcm, self)
        when 'CR'
          s = CRSeries.load(dcm, self)
        else
          raise ArgumentError, "Unexpected (unsupported) modality (#{dcm.value(MODALITY)})in Study#add()"
        end
        # Add the newly created series to this study:
        add_series(s)
      end
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
      if other.respond_to?(:to_study)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds a Series to this Study.
    #
    # @param [Series] series a series instance to be associated with this study
    #
    def add_series(series)
      raise ArgumentError, "Invalid argument 'series'. Expected Series, got #{series.class}." unless series.is_a?(Series)
      # Do not add it again if the series already belongs to this instance:
      @series << series unless @associated_series[series.uid]
      @image_series << series if series.is_a?(ImageSeries) && !@associated_series[series.uid]
      @associated_series[series.uid] = series
      @associated_iseries[series.uid] = series if series.is_a?(ImageSeries)
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

    # Gives the ImageSeries instance mathcing the specified UID.
    #
    # @overload iseries(uid)
    #   @param [String] uid series instance UID
    #   @return [ImageSeries, NilClass] the matched image series (or nil if no image series is matched)
    # @overload iseries
    #   @return [ImageSeries, NilClass] the first image series of this instance (or nil if no child image series exists)
    #
    def iseries(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        raise ArgumentError, "Expected String (or nil), got #{args.first.class}." unless [String, NilClass].include?(args.first.class)
        return @associated_iseries[args.first]
      else
        # No argument used, therefore we return the first ImageSeries instance:
        return @image_series.first
      end
    end

    # Gives the Series instance mathcing the specified UID.
    #
    # @overload fseries(uid)
    #   @param [String] uid unique identifier (either a series instance UID or a SOP instance UID, depending on the type of series)
    #   @return [Series, NilClass] the matched series (or nil if no series is matched)
    # @overload fseries
    #   @return [Series, NilClass] the first series of this instance (or nil if no child series exists)
    #
    def fseries(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        raise ArgumentError, "Expected String (or nil), got #{args.first.class}." unless [String, NilClass].include?(args.first.class)
        return @associated_series[args.first]
      else
        # No argument used, therefore we return the first Series instance:
        return @series.first
      end
    end

    # Returns self.
    #
    # @return [Study] self
    #
    def to_study
      self
    end

    # Gives the unique identifier string, which for this class is the Study
    # Instance UID.
    #
    # @return [String] the study instance UID
    #
    def uid
      return @study_uid
    end


    private


    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@date, @description, @id, @image_series, @time, @study_uid]
    end

  end
end
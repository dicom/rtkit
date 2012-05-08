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

    # Creates a new Study instance by loading study information from the specified DICOM object.
    # The Study's UID string value is used to uniquely identify a study.
    #
    # === Parameters
    #
    # * <tt>dcm</tt> -- An instance of a DICOM object (DICOM::DObject).
    # * <tt>patient</tt> -- The Patient instance that this Study belongs to.
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

    # Creates a new Study instance. The Study Instance UID string is used to uniquely identify a Study.
    #
    # === Parameters
    #
    # * <tt>study_uid</tt> -- The Study Instance UID string.
    # * <tt>patient</tt> -- The Patient instance that this Study belongs to.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:date</tt> -- String. The Study Date (DICOM tag '0008,0020').
    # * <tt>:time</tt> -- String. The Study Time (DICOM tag '0008,0030').
    # * <tt>:description</tt> -- String. The Study Description (DICOM tag '0008,1030').
    # * <tt>:id</tt> -- String. The Study ID (DICOM tag '0020,0010').
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

    # Adds a DICOM object to the study, by adding it
    # to an existing Series, or creating a new Series.
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
          @image_series << s
        when 'RTSTRUCT'
          s = StructureSet.load(dcm, self)
        when 'RTPLAN'
          s = Plan.load(dcm, self)
        when 'RTDOSE'
          s = RTDose.load(dcm, self)
        when 'RTIMAGE'
          s = RTImage.load(dcm, self)
        else
          raise ArgumentError, "Unexpected (unsupported) modality (#{dcm.value(MODALITY)})in Study#add()"
        end
        # Add the newly created series to this study:
        add_series(s)
      end
    end

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_study)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds a Series to this Study.
    #
    #--
    # Note: At some time we may decide to allow only ImageSeries
    # (i.e. excluding other kinds of series) to be attached to a study.
    #
    def add_series(series)
      raise ArgumentError, "Invalid argument 'series'. Expected Series, got #{series.class}." unless series.is_a?(Series)
      # Do not add it again if the series already belongs to this instance:
      @series << series unless @associated_series[series.uid]
      @image_series << series if series.is_a?(ImageSeries) && !@associated_series[series.uid]
      @associated_series[series.uid] = series
      @associated_iseries[series.uid] = series if series.is_a?(ImageSeries)
    end

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Returns the ImageSeries instance mathcing the specified Series Instance UID (if an argument is used).
    # If a specified UID doesn't match, nil is returned.
    # If no argument is passed, the first ImageSeries instance associated with the Study is returned.
    #
    # === Parameters
    #
    # * <tt>uid</tt> -- String. The value of the Series Instance UID element.
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

    # Returns the Series instance mathcing the specified unique identifier (if an argument is used).
    # The unique identifier is either a Series Instance UID (for ImageSeries) or a SOP Instance UID (for other kinds).
    # If a specified UID doesn't match, nil is returned.
    # If no argument is passed, the first Series instance associated with the Study is returned.
    #
    # === Parameters
    #
    # * <tt>uid</tt> -- The Series' unique identifier string.
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
    def to_study
      self
    end

    # Returns the unique identifier string, which for this class is the Study Instance UID.
    #
    def uid
      return @study_uid
    end


    private


    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@date, @description, @id, @image_series, @time, @study_uid]
    end

  end
end
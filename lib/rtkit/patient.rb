module RTKIT

  # Contains the DICOM data and methods related to a patient.
  #
  # === Relations
  #
  # * A Patient has many Study instances.
  #
  class Patient

    # The Patient's birth date.
    attr_reader :birth_date
    # The DataSet which this Patient belongs to.
    attr_reader :dataset
    # An array of Frame (of Reference) instances belonging to this Patient.
    attr_reader :frames
    # The Patient's ID (string).
    attr_reader :id
    # The Patient's name.
    attr_reader :name
    # The Patient's sex.
    attr_reader :sex
    # An array of Study references.
    attr_reader :studies

    # Creates a new Patient instance by loading patient information from the specified DICOM object.
    # The Patient's ID string value is used to uniquely identify a patient.
    #
    # === Parameters
    #
    # * <tt>dcm</tt> -- An instance of a DICOM object (DICOM::DObject).
    # * <tt>dataset</tt> -- The DataSet instance that this Patient belongs to.
    #
    def self.load(dcm, dataset)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'dataset'. Expected DataSet, got #{dataset.class}." unless dataset.is_a?(DataSet)
      name = dcm.value(PATIENTS_NAME)
      id = dcm.value(PATIENTS_ID)
      birth_date = dcm.value(BIRTH_DATE)
      sex = dcm.value(SEX)
      pat = self.new(name, id, dataset, :birth_date => birth_date, :sex => sex)
      pat.add(dcm)
      return pat
    end

    # Creates a new Patient instance. The Patient's ID string is used to uniquely identify a patient.
    #
    # === Parameters
    #
    # * <tt>name</tt> -- String. The Name of the Patient.
    # * <tt>id</tt> -- String. The ID of the Patient.
    # * <tt>dataset</tt> -- The DataSet instance which the Patient is associated with.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:birth_date</tt> -- A Date String of the Patient's birth date.
    # * <tt>:sex</tt> -- A code string indicating the Patient's sex.
    #
    def initialize(name, id, dataset, options={})
      raise ArgumentError, "Invalid argument 'name'. Expected String, got #{name.class}." unless name.is_a?(String)
      raise ArgumentError, "Invalid argument 'id'. Expected String, got #{id.class}." unless id.is_a?(String)
      raise ArgumentError, "Invalid argument 'dataset'. Expected DataSet, got #{dataset.class}." unless dataset.is_a?(DataSet)
      raise ArgumentError, "Invalid option ':birth_date'. Expected String, got #{options[:birth_date].class}." if options[:birth_date] && !options[:birth_date].is_a?(String)
      raise ArgumentError, "Invalid option ':sex'. Expected String, got #{options[:sex].class}." if options[:sex] && !options[:sex].is_a?(String)
      # Key attributes:
      @name = name
      @id = id
      @dataset = dataset
      # Default attributes:
      @frames = Array.new
      @studies = Array.new
      @associated_frames = Hash.new
      @associated_studies = Hash.new
      # Optional attributes:
      @birth_date = options[:birth_date]
      @sex = options[:sex]
      # Register ourselves with the dataset:
      @dataset.add_patient(self)
    end

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_patient)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds a DICOM object to the patient, by adding it
    # to an existing Study, or creating a new Study.
    #
    def add(dcm)
      s = study(dcm.value(STUDY_UID))
      if s
        s.add(dcm)
      else
        add_study(Study.load(dcm, self))
      end
    end

    # Adds a Frame to this Patient.
    #
    def add_frame(frame)
      raise ArgumentError, "Invalid argument 'frame'. Expected Frame, got #{frame.class}." unless frame.is_a?(Frame)
      # Do not add it again if the frame already belongs to this instance:
      @frames << frame unless @associated_frames[frame.uid]
      @associated_frames[frame.uid] = frame
    end

    # Adds a Study to this Patient.
    #
    def add_study(study)
      raise ArgumentError, "Invalid argument 'study'. Expected Study, got #{study.class}." unless study.is_a?(Study)
      # Do not add it again if the study already belongs to this instance:
      @studies << study unless @associated_studies[study.uid]
      @associated_studies[study.uid] = study
    end

    # Sets the birth_date attribute.
    #
    def birth_date=(value)
      @birth_date = value && value.to_s
    end

    # Creates (and returns) a Frame instance added to this Patient.
    #
    # === Parameters
    #
    # * <tt>uid</tt> -- The Frame of Reference UID string.
    # * <tt>indicator</tt> -- The Position Reference Indicator string. Defaults to nil.
    #
    def create_frame(uid, indicator=nil)
      raise ArgumentError, "Invalid argument 'uid'. Expected String, got #{uid.class}." unless uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'indicator'. Expected String or nil, got #{indicator.class}." unless [String, NilClass].include?(indicator.class)
      frame = Frame.new(uid, self, :indicator => indicator)
      add_frame(frame)
      @dataset.add_frame(frame)
      return frame
    end

    # Returns the Frame instance mathcing the specified Frame Instance UID (if an argument is used).
    # If a specified UID doesn't match, nil is returned.
    # If no argument is passed, the first Frame instance associated with the Patient is returned.
    #
    # === Parameters
    #
    # * <tt>uid</tt> -- String. The value of the Frame Instance UID element.
    #
    def frame(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        raise ArgumentError, "Expected String (or nil), got #{args.first.class}." unless [String, NilClass].include?(args.first.class)
        return @associated_frames[args.first]
      else
        # No argument used, therefore we return the first Frame instance:
        return @frames.first
      end
    end

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Sets the id attribute.
    #
    def id=(value)
      @id = value && value.to_s
    end

    # Sets the name attribute.
    #
    def name=(value)
      @name = value && value.to_s
    end

    # Sets the sex attribute.
    #
    def sex=(value)
      @sex = value && value.to_s
    end

    # Returns the Study instance mathcing the specified Study Instance UID (if an argument is used).
    # If a specified UID doesn't match, nil is returned.
    # If no argument is passed, the first Study instance associated with the Patient is returned.
    #
    # === Parameters
    #
    # * <tt>uid</tt> -- String. The value of the Study Instance UID element.
    #
    def study(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        raise ArgumentError, "Expected String (or nil), got #{args.first.class}." unless [String, NilClass].include?(args.first.class)
        return @associated_studies[args.first]
      else
        # No argument used, therefore we return the first Study instance:
        return @studies.first
      end
    end

    # Returns self.
    #
    def to_patient
      self
    end

    # Returns the unique identifier string, which for this class is the Patient's ID.
    #
    def uid
      return @id
    end


    private


    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@birth_date, @frames, @id, @name, @sex, @studies]
    end

  end
end
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

    # Creates a new Patient instance by loading patient information from the
    # specified DICOM object. The Patient's ID string value is used to uniquely
    # identify a patient.
    #
    # @param [DICOM::DObject] dcm a DICOM object
    # @param [DataSet] dataset the dataset instance which the Patient is associated with
    # @return [Patient] the created Patient instance
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

    # Creates a new Patient instance. The Patient's ID string is used to
    # uniquely identify a patient.
    #
    # @param [String] name the patient's name (DICOM tag 0010,0010)
    # @param [String] id the patient's ID (DICOM tag 0010,0020)
    # @param [DataSet] dataset the DataSet instance which this Patient is associated with
    # @param [Hash] options the options to use for creating the patient
    # @option options [String] :birth_date the patient's birth date (DICOM tag 0010,0030)
    # @option options [String] :sex a code string representing the patient's sex (DICOM tag 0010,0040)
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

    # Checks for equality.
    #
    # Other and self are considered equivalent if they are
    # of compatible types and their attributes are equivalent.
    #
    # @param other an object to be compared with self.
    # @return [Boolean] true if self and other are considered equivalent
    #
    def ==(other)
      if other.respond_to?(:to_patient)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Registers a DICOM object to the patient, by adding it to an existing
    # Study, or creating a new Study.
    #
    # @param [DICOM::DObject] dcm a DICOM object
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
    # @param [Frame] frame a frame instance to be associated with this patient
    #
    def add_frame(frame)
      raise ArgumentError, "Invalid argument 'frame'. Expected Frame, got #{frame.class}." unless frame.is_a?(Frame)
      # Do not add it again if the frame already belongs to this instance:
      @frames << frame unless @associated_frames[frame.uid]
      @associated_frames[frame.uid] = frame
    end

    # Adds a Study to this Patient.
    #
    # @param [Study] study a study instance to be associated with this patient
    #
    def add_study(study)
      raise ArgumentError, "Invalid argument 'study'. Expected Study, got #{study.class}." unless study.is_a?(Study)
      # Do not add it again if the study already belongs to this instance:
      @studies << study unless @associated_studies[study.uid]
      @associated_studies[study.uid] = study
    end

    # Sets the birth_date attribute.
    #
    # @param [NilClass, #to_s] value the patient's birth date (0010,0030)
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
    # @param [String] uid the Frame of Reference UID string (0020,0052)
    # @param [String, NilClass] indicator the Position Reference Indicator (0020,1040)
    # @return [Frame] the created frame
    #
    def create_frame(uid, indicator=nil)
      raise ArgumentError, "Invalid argument 'uid'. Expected String, got #{uid.class}." unless uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'indicator'. Expected String or nil, got #{indicator.class}." unless [String, NilClass].include?(indicator.class)
      frame = Frame.new(uid, self, :indicator => indicator)
      add_frame(frame)
      @dataset.add_frame(frame)
      return frame
    end

    # Gives the Frame instance mathcing the specified UID.
    #
    # @overload frame(uid)
    #   @param [String] uid frame instance UID
    #   @return [Frame, NilClass] the matched frame (or nil if no frame is matched)
    # @overload frame
    #   @return [Frame, NilClass] the first frame of this instance (or nil if no child frames exists)
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

    # Computes a hash code for this object.
    #
    # @note Two objects with the same attributes will have the same hash code.
    #
    # @return [Fixnum] the object's hash code
    #
    def hash
      state.hash
    end

    # Sets the id attribute.
    #
    # @param [NilClass, #to_s] value the patient's ID (0010,0020)
    #
    def id=(value)
      @id = value && value.to_s
    end

    # Sets the name attribute.
    #
    # @param [NilClass, #to_s] value the patient's name (0010,0010)
    #
    def name=(value)
      @name = value && value.to_s
    end

    # Sets the sex attribute.
    #
    # @param [NilClass, #to_s] value the patient's sex (0010,0040)
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

    # Gives the Study instance mathcing the specified UID.
    #
    # @overload study(uid)
    #   @param [String] uid study instance UID
    #   @return [Study, NilClass] the matched study (or nil if no study is matched)
    # @overload study
    #   @return [Study, NilClass] the first study of this instance (or nil if no child studies exists)
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
    # @return [Patient] self
    #
    def to_patient
      self
    end

    # Gives the unique identifier string, which for this class is served by
    # the Patient's ID.
    #
    # @return [String] the patient's ID (0010,0020)
    #
    def uid
      return @id
    end


    private


    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@birth_date, @frames, @id, @name, @sex, @studies]
    end

  end
end
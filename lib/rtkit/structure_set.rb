module RTKIT

  # The StructureSet class contains methods that are specific for this modality (RTSTRUCT).
  #
  # === Inheritance
  #
  # * StructureSet inherits all methods and attributes from the Series class.
  #
  class StructureSet < Series

    # The original DObject instance of the StructureSet.
    attr_reader :dcm
    # An array of ImageSeries that this Structure Set Series references has ROIs defined for.
    attr_reader :image_series
    #  An array of RTPlans associated with this Structure Set Series.
    attr_reader :plans
    # An array of ROIs belonging to this structure set.
    attr_reader :rois
    # The SOP Instance UID.
    attr_reader :sop_uid

    # Creates a new StructureSet instance by loading the relevant information from the specified DICOM object.
    # The SOP Instance UID string value is used to uniquely identify a StructureSet instance.
    #
    # === Parameters
    #
    # * <tt>dcm</tt> -- An instance of a DICOM object (DICOM::DObject) with modality 'RTSTRUCT'.
    # * <tt>study</tt> -- The Study instance that this StructureSet belongs to.
    #
    def self.load(dcm, study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'study'. Expected Study, got #{study.class}." unless study.is_a?(Study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject with modality 'RTSTUCT', got #{dcm.value(MODALITY)}." unless dcm.value(MODALITY) == 'RTSTRUCT'
      # Required attributes:
      sop_uid = dcm.value(SOP_UID)
      # Optional attributes:
      class_uid = dcm.value(SOP_CLASS)
      date = dcm.value(SERIES_DATE)
      time = dcm.value(SERIES_TIME)
      description = dcm.value(SERIES_DESCR)
      series_uid = dcm.value(SERIES_UID)
      # Get the corresponding image series:
      image_series = self.image_series(dcm, study)
      # Create the StructureSet instance:
      ss = self.new(sop_uid, image_series, :class_uid => class_uid, :date => date, :time => time, :description => description, :series_uid => series_uid)
      ss.add(dcm)
      return ss
    end

    # Identifies the ImageSeries that the StructureSet object belongs to.
    # If the referenced instances (ImageSeries & Frame) does not exist, they are created by this method.
    #
    def self.image_series(dcm, study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      raise ArgumentError, "Invalid argument 'study'. Expected Study, got #{study.class}." unless study.is_a?(Study)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject with modality 'RTSTUCT', got #{dcm.value(MODALITY)}." unless dcm.value(MODALITY) == 'RTSTRUCT'
      # Extract the Referenced Frame UID:
      frame_uid = nil
      img_series_uid = nil
      dcm[REF_FRAME_OF_REF_SQ].each_item do |frame_item|
        frame_uid = frame_item.value(FRAME_OF_REF)
        if frame_item.exists?(RT_REF_STUDY_SQ)
          frame_item[RT_REF_STUDY_SQ].each_item do |study_item|
            if study_item.exists?(RT_REF_SERIES_SQ)
              study_item[RT_REF_SERIES_SQ].each_item do |series_item|
                img_series_uid = series_item.value(SERIES_UID)
                break if img_series_uid
              end
            end
            break if img_series_uid
          end
        end
        break if img_series_uid
      end
      raise "Invalid structure set. Frame UID reference (#{frame_uid}) and/or image series UID reference (#{img_series_uid}) missing." unless frame_uid && img_series_uid
      # Create the Frame if it doesn't exist:
      f = study.patient.dataset.frame(frame_uid)
      f = Frame.new(frame_uid, study.patient) unless f
      # Create the ImageSeries if it doesnt exist:
      is = f.series(img_series_uid)
      is = ImageSeries.new(img_series_uid, 'CT', f, study) unless is
      study.add_series(is)
      return is
    end

    # Creates a new StructureSet instance.
    #
    # === Parameters
    #
    # * <tt>sop_uid</tt> -- The SOP Instance UID string.
    # * <tt>image_series</tt> -- An Image Series that this StructureSet belongs to.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:date</tt> -- String. The Series Date (DICOM tag '0008,0021').
    # * <tt>:time</tt> -- String. The Series Time (DICOM tag '0008,0031').
    # * <tt>:description</tt> -- String. The Series Description (DICOM tag '0008,103E').
    # * <tt>:series_uid</tt> -- String. The Series Instance UID (DICOM tag '0020,000E').
    #
    def initialize(sop_uid, image_series, options={})
      raise ArgumentError, "Invalid argument 'sop_uid'. Expected String, got #{sop_uid.class}." unless sop_uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'image_series'. Expected ImageSeries, got #{image_series.class}." unless image_series.is_a?(ImageSeries)
      # Pass attributes to Series initialization:
      options[:class_uid] = '1.2.840.10008.5.1.4.1.1.481.3' # RT Structure Set Storage
      # Get a randomized Series UID unless it has been defined in the options hash:
      series_uid = options[:series_uid] || RTKIT.series_uid
      super(series_uid, 'RTSTRUCT', image_series.study, options)
      @sop_uid = sop_uid
      # Default attributes:
      @image_series = Array.new
      @rois = Array.new
      @plans = Array.new
      @associated_plans = Hash.new
      # Register ourselves with the ImageSeries:
      image_series.add_struct(self)
      @image_series << image_series
    end

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_structure_set)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Registers a DICOM Object to the StructureSet, and processes it
    # to create (and reference) the ROIs contained in the object.
    #
    def add(dcm)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      @dcm = dcm
      load_rois
    end

    # Adds a Plan Series to this StructureSet.
    # Note: Intended for internal use in the library only.
    #
    def add_plan(plan)
      raise ArgumentError, "Invalid argument 'plan'. Expected Plan, got #{plan.class}." unless plan.is_a?(Plan)
      @plans << plan unless @associated_plans[plan.uid]
      @associated_plans[plan.uid] = plan
    end

    # Adds a ROI instance to this StructureSet.
    #
    def add_roi(roi)
      raise ArgumentError, "Invalid argument 'roi'. Expected ROI, got #{roi.class}." unless roi.is_a?(ROI)
      @rois << roi unless @rois.include?(roi)
    end

    # Creates a ROI belonging to this StructureSet.
    # Returns the created ROI.
    #
    # === Notes
    #
    # * The ROI is created without Slices, and these must be added after the ROI creation.
    #
    # === Parameters
    #
    # * <tt>frame</tt> -- The Frame instance which the ROI will belong to.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:algorithm</tt> -- String. The ROI Generation Algorithm. Defaults to 'Automatic'.
    # * <tt>:name</tt> -- String. The ROI Name. Defaults to 'RTKIT-VOLUME'.
    # * <tt>:number</tt> -- Integer. The ROI Number. Defaults to the first available ROI Number in the StructureSet.
    # * <tt>:interpreter</tt> -- String. The ROI Interpreter. Defaults to 'RTKIT'.
    # * <tt>:type</tt> -- String. The ROI Interpreted Type. Defaults to 'CONTROL'.
    #
    def create_roi(frame, options={})
      raise ArgumentError, "Expected Frame, got #{frame.class}." unless frame.is_a?(Frame)
      # Set values:
      algorithm = options[:algorithm] || 'Automatic'
      name = options[:name] || 'RTKIT-VOLUME'
      interpreter = options[:interpreter] || 'RTKIT'
      type = options[:type] || 'CONTROL'
      if options[:number]
        raise ArgumentError, "Expected Integer, got #{options[:number].class} for the option :number." unless options[:number].is_a?(Integer)
        raise ArgumentError, "The specified ROI Number (#{options[:roi_number]}) is already used by one of the existing ROIs (#{roi_numbers})." if roi_numbers.include?(options[:number])
        number = options[:number]
      else
        number = (roi_numbers.max ? roi_numbers.max + 1 : 1)
      end
      # Create ROI:
      roi = ROI.new(name, number, frame, self, :algorithm => algorithm, :name => name, :number => number, :interpreter => interpreter, :type => type)
      return roi
    end

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Assigns a new image series parent to this structure set.
    #
    # @note This method is a temporary fix! A final specification on the relationship
    #   between image series, structure sets and rois is pending.
    #
    def image_series=(img_series)
      @image_series = [img_series]
    end

    # Returns the Plan instance mathcing the specified SOP Instance UID (if an argument is used).
    # If a specified UID doesn't match, nil is returned.
    # If no argument is passed, the first Plan instance associated with the StructureSet is returned.
    #
    # === Parameters
    #
    # * <tt>uid</tt> -- String. The value of the SOP Instance UID element.
    #
    def plan(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        raise ArgumentError, "Expected String (or nil), got #{args.first.class}." unless [String, NilClass].include?(args.first.class)
        return @associated_plans[args.first]
      else
        # No argument used, therefore we return the first Plan instance:
        return @plans.first
      end
    end

    # Removes the ROI (specified by a ROI Number) from the Structure Set.
    #
    # === Parameters
    #
    # * <tt>instance_or_number</tt> -- The ROI Instance (or ROI Number of the instance) to be removed.
    #
    def remove_roi(instance_or_number)
      raise ArgumentError, "Invalid argument 'instance_or_number'. Expected a ROI Instance or an Integer (ROI Number). Got #{instance_or_number.class}." unless [ROI, Integer].include?(instance_or_number.class)
      roi_instance = instance_or_number
      if instance_or_number.is_a?(Integer)
        roi_instance = roi(instance_or_number)
      end
      index = @rois.index(roi_instance)
      if index
        @rois.delete_at(index)
        roi_instance.remove_references
      end
    end

    # Removes all ROIs from the Structure Set.
    #
    def remove_rois
      @rois.each do |roi|
        roi.remove_references
      end
      @rois = Array.new
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

    # Returns the ROI Names assigned to the various structures present in the structure set.
    # The names are returned in an array.
    #
    def roi_names
      names = Array.new
      @rois.each do |roi|
        names << roi.name
      end
      return names
    end

    # Returns the ROI Numbers assigned to the various structures present in the structure set.
    # The numbers are returned in an array.
    #
    def roi_numbers
      numbers = Array.new
      @rois.each do |roi|
        numbers << roi.number
      end
      return numbers
    end

    # Returns all ROIs defined in this structure set that belongs to the specified Frame of Reference UID.
    # Returns an empty array if no matching ROIs are found.
    #
    def rois_in_frame(uid)
      raise ArgumentError, "Expected String, got #{uid.class}." unless uid.is_a?(String)
      frame_rois = Array.new
      @rois.each do |roi|
        frame_rois << roi if roi.frame.uid == uid
      end
      return frame_rois
    end

    # Sets new color values for all ROIs belonging to the StructureSet.
    # Color values will be selected in a way which attempts to make the ROI colors maximally different.
    # The method uses a predefined list containing 54 colors, which means for the rare case of more
    # than 24 ROIs, some will not be assigned a color.
    # Obviously, the more ROIs to assign colors to, the more similar the color values will be.
    #
    def set_colors
      if @rois.length > 0
        # Determine colors:
        initialize_colors
        # Set colors:
        @rois.each_index do |i|
          @rois[i].color = @colors[i] if i < 24
        end
      end
    end

    # Sets new ROI Numbers to all ROIs belonging to the StructureSet.
    # Numbers increase sequentially, starting at 1 for the first ROI.
    #
    def set_numbers
      @rois.each_with_index do |roi, i|
        roi.number = i + 1
      end
    end

    # Dumps the StructureSet instance to a DObject.
    # This overwrites the dcm instance attribute.
    # Returns the DObject instance.
    #
    def to_dcm
      # Use the original DICOM object as a starting point (keeping all non-sequence elements):
      #@dcm[REF_FRAME_OF_REF_SQ].delete_children
      @dcm[STRUCTURE_SET_ROI_SQ].delete_children
      @dcm[ROI_CONTOUR_SQ].delete_children
      @dcm[RT_ROI_OBS_SQ].delete_children
      # Create DICOM
      @rois.each do |roi|
        @dcm[STRUCTURE_SET_ROI_SQ].add_item(roi.ss_item)
        @dcm[ROI_CONTOUR_SQ].add_item(roi.contour_item)
        @dcm[RT_ROI_OBS_SQ].add_item(roi.obs_item)
      end
      return @dcm
    end

    # Returns self.
    #
    def to_structure_set
      self
    end

    # Writes the StructureSet to a DICOM file given by the specified file string.
    #
    def write(path)
      to_dcm
      @dcm.write(path)
    end


    private


=begin
    # Registers this Structure Set instance with the ImageSeries that it references.
    #
    def connect_to_image_series
      # Find out which Image Series is referenced:
      @dcm[REF_FRAME_OF_REF_SQ].each do |frame_item|
        ref_frame_of_ref = frame_item.value(FRAME_OF_REF)
        # Continue if the Referenced Frame of Ref matches one of the Frames registered to our DataSet.
        matched_frame = @study.patient.dataset.frame(ref_frame_of_ref)
        if matched_frame
          frame_item[RT_REF_STUDY_SQ].each do |study_item|
            # Skip testing against the Study UID.
            #ref_study_uid = study_item.value(REF_SOP_UID)
            study_item[RT_REF_SERIES_SQ].each do |series_item|
              ref_series_uid = series_item.value(SERIES_UID)
              matched_series = matched_frame.series(ref_series_uid)
              if matched_series
                # The referenced series exists in our dataset. Proceed with setting up the references:
                matched_series.add_struct(self)
                @image_series << matched_series
              end
            end
          end
        end
      end
    end
=end

    # Loads the (first occuring set of) UID references for frame of reference
    # as well as the image series from the Referenced Frame of Reference Sequence.
    #
    # @param [DObject] dcm a structure set DICOM object
    # @return [Array<String, NilClass>] the frame uid and image series uid string pair (if found, otherwise nil)
    #
    def load_image_series_reference(dcm)
      frame_uid = nil
      img_series_uid = nil
      dcm[REF_FRAME_OF_REF_SQ].each_item do |frame_item|
        if frame_item.exists?(RT_REF_STUDY_SQ)
          frame_item[RT_REF_STUDY_SQ].each_item do |study_item|
            if study_item.exists?(RT_REF_SERIES_SQ)
              study_item[RT_REF_SERIES_SQ].each_item do |series_item|
                img_series_uid = series_item.value(SERIES_UID)
                break if img_series_uid
              end
            end
            break if img_series_uid
          end
        end
        break if img_series_uid
      end
      return frame_uid, img_series_uid
    end

    # Loads the ROI Items contained in the structure set and creates ROI instances.
    #
    def load_rois
      if @dcm[STRUCTURE_SET_ROI_SQ] && @dcm[ROI_CONTOUR_SQ] && @dcm[RT_ROI_OBS_SQ]
        # Load the information in a nested hash:
        item_group = Hash.new
        @dcm[STRUCTURE_SET_ROI_SQ].each do |roi_item|
          item_group[roi_item.value(ROI_NUMBER)] = {:roi => roi_item}
        end
        @dcm[ROI_CONTOUR_SQ].each do |contour_item|
          item_group[contour_item.value(REF_ROI_NUMBER)][:contour] = contour_item
        end
        @dcm[RT_ROI_OBS_SQ].each do |rt_item|
          item_group[rt_item.value(REF_ROI_NUMBER)][:rt] = rt_item
        end
        # Create a ROI instance for each set of items:
        item_group.each_value do |roi_items|
          ROI.create_from_items(roi_items[:roi], roi_items[:contour], roi_items[:rt], self)
        end
      else
        RTKIT.logger.warn "The structure set contained one or more empty ROI sequences. No ROIs extracted."
      end
    end

    # Initializes the color instance array.
    #
    def initialize_colors
      @colors = [
        # 6 colors with only 255:
        "255\\0\\0",
        "0\\255\\0",
        "0\\0\\255",
        "255\\255\\0",
        "0\\255\\255",
        "255\\0\\255",
        # 12 colors with a mix of 128 and 255:
        "255\\128\\0",
        "128\\255\\0",
        "0\\128\\255",
        "255\\0\\128",
        "0\\255\\128",
        "128\\0\\255",
        "255\\255\\128",
        "128\\255\\255",
        "255\\128\\255",
        "255\\128\\128",
        "128\\128\\255",
        "128\\255\\128",
        # 6 colors with only 128:
        "128\\0\\0",
        "0\\128\\0",
        "0\\0\\128",
        "128\\128\\0",
        "0\\128\\128",
        "128\\0\\128",
      ]
    end

    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@plans, @rois, @sop_uid]
    end

  end
end
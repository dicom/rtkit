module RTKIT

  # The StructureSet class contains methods that are specific for this modality
  # (RTSTRUCT).
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
    # The SOP Instance UID.
    attr_reader :sop_uid
    # An array of ROIs & POIs belonging to this structure set.
    attr_reader :structures

    # Creates a new StructureSet instance by loading the relevant information
    # from the specified DICOM object. The SOP Instance UID string value is
    # used to uniquely identify a StructureSet instance.
    #
    # @param [DICOM::DObject] dcm an RTSTRUCT DICOM object from which to create the StructureSet
    # @param [Study] study the Study instance which the StructureSet shall be associated with
    # @return [StructureSet] the created StructureSet instance
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
    # If the referenced instances (ImageSeries & Frame) does not exist, they
    # are created by this method.
    #
    # @param [DICOM::DObject] dcm an RTSTRUCT DICOM object
    # @param [Study] study the Study instance which the StructureSet instance shall be associated with
    # @return [ImageSeries] the ImageSeries that the StructureSet instance is to be associated with
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
    # @param [String] sop_uid the SOP instance UID string
    # @param [ImageSeries] image_series the ImageSeries which this StructureSet is associated with
    # @param [Hash] options the options to use for creating the StructureSet
    # @option options [String] :date the series date (DICOM tag '0008,0021')
    # @option options [String] :description the series description (DICOM tag '0008,103E')
    # @option options [String] :series_uid the series instance UID (DICOM tag '0020,000E')
    # @option options [String] :time the series time (DICOM tag '0008,0031')
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
      @structures = Array.new
      @plans = Array.new
      @associated_plans = Hash.new
      # Register ourselves with the ImageSeries:
      image_series.add_struct(self)
      @image_series << image_series
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
      if other.respond_to?(:to_structure_set)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Registers a DICOM object to the StructureSet, and processes it to create
    # (and reference) the ROIs contained in the object.
    #
    # @param [DICOM::DObject] dcm an RTSTRUCT DICOM object
    #
    def add(dcm)
      raise ArgumentError, "Invalid argument 'dcm'. Expected DObject, got #{dcm.class}." unless dcm.is_a?(DICOM::DObject)
      @dcm = dcm
      load_structures
    end

    # Adds a Plan Series to this StructureSet.
    #
    # @param [Plan] plan a plan instance to be associated with this structure set
    #
    def add_plan(plan)
      raise ArgumentError, "Invalid argument 'plan'. Expected Plan, got #{plan.class}." unless plan.is_a?(Plan)
      @plans << plan unless @associated_plans[plan.uid]
      @associated_plans[plan.uid] = plan
    end

    # Adds a POI instance to this StructureSet.
    #
    # @param [POI] poi a poi instance to be associated with this structure set
    #
    def add_poi(poi)
      raise ArgumentError, "Invalid argument 'poi'. Expected POI, got #{poi.class}." unless poi.is_a?(POI)
      @structures << poi unless @structures.include?(poi)
    end

    # Adds a Structure instance to this StructureSet.
    #
    # @param [ROI, POI] structure a Structure to be associated with this StructureSet
    #
    def add_structure(structure)
      raise ArgumentError, "Invalid argument 'structure'. Expected ROI/POI, got #{structure.class}." unless structure.respond_to?(:to_roi) or structure.respond_to?(:to_poi)
      @structures << structure unless @structures.include?(structure)
    end

    # Adds a ROI instance to this StructureSet.
    #
    # @param [ROI] roi a roi instance to be associated with this structure set
    #
    def add_roi(roi)
      raise ArgumentError, "Invalid argument 'roi'. Expected ROI, got #{roi.class}." unless roi.is_a?(ROI)
      @structures << roi unless @structures.include?(roi)
    end

    # Creates a ROI belonging to this StructureSet.
    #
    # @note The ROI is created without any Slice instances (these must be added
    # after the ROI creation).
    #
    # @param [Frame] frame the Frame which the ROI is to be associated with
    # @param [Hash] options the options to use for creating the ROI
    # @option options [String] :algorithm the ROI generation algorithm (defaults to 'Automatic')
    # @option options [String] :interpreter the ROI interpreter (defaults to 'RTKIT')
    # @option options [String] :name the ROI name (defaults to 'RTKIT-VOLUME')
    # @option options [String] :number the ROI number (defaults to the first available ROI number in the structure set)
    # @option options [String] :type the ROI interpreted type (defaults to 'CONTROL')
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
        raise ArgumentError, "The specified ROI Number (#{options[:roi_number]}) is already used by one of the existing ROIs (#{roi_numbers})." if structure_numbers.include?(options[:number])
        number = options[:number]
      else
        number = (structure_numbers.max ? structure_numbers.max + 1 : 1)
      end
      # Create ROI:
      roi = ROI.new(name, number, frame, self, :algorithm => algorithm, :name => name, :number => number, :interpreter => interpreter, :type => type)
      return roi
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

    # Assigns a new image series parent to this structure set.
    #
    # @note This method is a temporary fix! A final specification on the
    #   relationship between image series, structure sets and rois is pending.
    # @param [ImageSeries] img_series the image series which this structure set is to be associated with
    #
    def image_series=(img_series)
      @image_series = [img_series]
    end

    # Gives the Plan instance mathcing the specified UID.
    #
    # @overload plan(uid)
    #   @param [String] uid SOP instance UID
    #   @return [Plan, NilClass] the matched plan (or nil if no plan is matched)
    # @overload plan
    #   @return [Plan, NilClass] the first plan of this instance (or nil if no child plans exists)
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

    # Extracts the POIs associated with this structure set.
    #
    # @return [Array<POI>] the associated POIs
    #
    def pois
      @structures.select {|s| s.is_a?(POI)}
    end

    # Removes a ROI or POI from the structure set.
    #
    # @param [ROI, POI, Integer] instance_or_number the ROI/POI instance or its identifying number
    #
    def remove_structure(instance_or_number)
      raise ArgumentError, "Invalid argument 'instance_or_number'. Expected a ROI Instance or an Integer (ROI Number). Got #{instance_or_number.class}." unless [ROI, Integer].include?(instance_or_number.class)
      s_instance = instance_or_number
      if instance_or_number.is_a?(Integer)
        s_instance = structure(instance_or_number)
      end
      index = @structures.index(s_instance)
      if index
        @structures.delete_at(index)
        s_instance.remove_references
      end
    end

    # Removes all ROI/POI instances from the structure set.
    #
    def remove_structures
      @structures.each do |s|
        s.remove_references
      end
      @structures = Array.new
    end

    # Extracts the ROIs associated with this structure set.
    #
    # @return [Array<ROI>] the associated ROIs
    #
    def rois
      @structures.select {|s| s.is_a?(ROI)}
    end

    # Gives a ROI/POI that matches the specified number or name.
    #
    # @param [String, Integer] name_or_number a ROI/POI's name or number attribute
    # @return [ROI, POI, NilClass] the matching structure (or nil if no structure is matched)
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

    # Gives the names of the structure set's associated structures.
    #
    # @return [Array<String>] the names of the associated structures
    #
    def structure_names
      names = Array.new
      @structures.each do |s|
        names << s.name
      end
      return names
    end

    # Gives the numbers of the structure set's associated structures.
    #
    # @return [Array<Integer>] the numbers of the associated structures
    #
    def structure_numbers
      numbers = Array.new
      @structures.each do |s|
        numbers << s.number
      end
      return numbers
    end

    # Gives all ROIs/POIs associated with this structure set which belongs to
    # the specified Frame of Reference UID.
    #
    # @return [Array<ROI, POI>] the matching ROIs/POIs (an empty Array if no structures are matched)
    #
    def structures_in_frame(uid)
      raise ArgumentError, "Expected String, got #{uid.class}." unless uid.is_a?(String)
      frame_structures = Array.new
      @structures.each do |s|
        frame_structures << s if s.frame.uid == uid
      end
      return frame_structures
    end

    # Sets new color values for all ROIs belonging to this structure set.
    # Color values are selected in a way which attempts to make the ROI colors
    # maximally different. Obviously, the more ROIs to assign colors to, the
    # more similar the color values will be.
    #
    # The method uses a predefined collection of 24 colors, which means that if
    # the structure set contains more than 24 ROIs, some will not be assigned a
    # new color.
    #
    def set_colors
      if @structures.length > 0
        # Determine colors:
        initialize_colors
        # Set colors:
        @structures.each_index do |i|
          @structures[i].color = @colors[i] if i < 24
        end
      end
    end

    # Sets new ROI numbers to all structures belonging to the structure set. The
    # numbers increment sequentially, starting at 1 for the first ROI/POI.
    #
    def set_numbers
      @structures.each_with_index do |s, i|
        s.number = i + 1
      end
    end

    # Converts the structure set instance to a DICOM object.
    #
    # @note This method uses the original DICOM object of the structure set,
    #   and updates it with attributes from the structure set instance.
    # @return [DICOM::DObject] the processed DICOM object
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
    # @return [StructureSet] self
    #
    def to_structure_set
      self
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
    # as well as the image series from the Referenced Frame of Reference
    # Sequence.
    #
    # @param [DICOM::DObject] dcm a structure set DICOM object
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

    # Loads the ROI Items contained in the structure set and creates ROI
    # and POI instances, which are referenced to this structure set.
    #
    def load_structures
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
          Structure.create_from_items(roi_items[:roi], roi_items[:contour], roi_items[:rt], self)
        end
      else
        RTKIT.logger.warn "The structure set contained one or more empty ROI sequences. No ROIs extracted."
      end
    end

    # Initializes an instance color array which is used for setting ROI colors.
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

    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@plans, @structures, @sop_uid]
    end

  end
end
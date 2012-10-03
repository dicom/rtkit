module RTKIT

  # Contains DICOM data and methods related to a Region of Interest, defined in a Structure Set.
  #
  # === Relations
  #
  # * An image series has many ROIs, defined through a Structure Set.
  # * An image slice has only the ROIs which are contoured in that particular slice in the Structure Set.
  # * A ROI has many Slices.
  #
  class ROI

    # ROI Generation Algorithm.
    attr_reader :algorithm
    # ROI Display Color.
    attr_reader :color
    # The Frame which this ROI belongs to.
    attr_reader :frame
    # ROI Interpreter.
    attr_reader :interpreter
    # ROI Name.
    attr_reader :name
    # ROI Number (Integer).
    attr_reader :number
    # An array containing the Slices that the ROI is defined in.
    attr_reader :slices
    # The StructureSet that the ROI is defined in.
    attr_reader :struct
    # RT ROI Interpreted Type.
    attr_reader :type

    # Creates a new ROI instance from the three items of the structure set
    # which contains the information related to a particular ROI.
    # This method also creates and connects any child structures as indicated in the items (e.g. Slices).
    # Returns the ROI instance.
    #
    # === Parameters
    #
    # * <tt>roi_item</tt> -- The ROI's Item from the Structure Set ROI Sequence in the DObject of a Structure Set.
    # * <tt>contour_item</tt> -- The ROI's Item from the ROI Contour Sequence in the DObject of a Structure Set.
    # * <tt>rt_item</tt> -- The ROI's Item from the RT ROI Observations Sequence in the DObject of a Structure Set.
    # * <tt>struct</tt> -- The StructureSet instance that this ROI belongs to.
    #
    def self.create_from_items(roi_item, contour_item, rt_item, struct)
      raise ArgumentError, "Invalid argument 'roi_item'. Expected DICOM::Item, got #{roi_item.class}." unless roi_item.is_a?(DICOM::Item)
      raise ArgumentError, "Invalid argument 'contour_item'. Expected DICOM::Item, got #{contour_item.class}." unless contour_item.is_a?(DICOM::Item)
      raise ArgumentError, "Invalid argument 'rt_item'. Expected DICOM::Item, got #{rt_item.class}." unless rt_item.is_a?(DICOM::Item)
      raise ArgumentError, "Invalid argument 'struct'. Expected StructureSet, got #{struct.class}." unless struct.is_a?(StructureSet)
      # Values from the Structure Set ROI Sequence Item:
      number = roi_item.value(ROI_NUMBER).to_i
      frame_of_ref = roi_item.value(REF_FRAME_OF_REF)
      name = roi_item.value(ROI_NAME) || ''
      algorithm = roi_item.value(ROI_ALGORITHM) || ''
      # Values from the RT ROI Observations Sequence Item:
      type = rt_item.value(ROI_TYPE) || ''
      interpreter = rt_item.value(ROI_INTERPRETER) || ''
      # Values from the ROI Contour Sequence Item:
      color = contour_item.value(ROI_COLOR)
      # Get the frame:
      frame = struct.study.patient.dataset.frame(frame_of_ref)
      # If the frame didnt exist, create it (assuming the frame belongs to our patient):
      frame = struct.study.patient.create_frame(frame_of_ref) unless frame
      # Create the ROI instance:
      roi = self.new(name, number, frame, struct, :algorithm => algorithm, :color => color, :interpreter => interpreter, :type => type)
      # Create the Slices in which the ROI has contours defined:
      roi.create_slices(contour_item[CONTOUR_SQ]) if contour_item[CONTOUR_SQ]
      return roi
    end

    # Creates a new ROI instance.
    #
    # === Parameters
    #
    # * <tt>name</tt> -- String. The ROI Name.
    # * <tt>number</tt> -- Integer. The ROI Number.
    # * <tt>frame</tt> -- The Frame instance that this ROI belongs to.
    # * <tt>struct</tt> -- The StructureSet instance that this ROI belongs to.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:algorithm</tt> -- String. The ROI Generation Algorithm. Defaults to 'Automatic'.
    # * <tt>:color</tt> -- String. The ROI Display Color. Defaults to a random color string (format: 'x\y\z' where [x,y,z] is a byte (0-255)).
    # * <tt>:interpreter</tt> -- String. The ROI Interpreter. Defaults to 'RTKIT'.
    # * <tt>:type</tt> -- String. The ROI Interpreted Type. Defaults to 'CONTROL'.
    #
    def initialize(name, number, frame, struct, options={})
      raise ArgumentError, "Invalid argument 'name'. Expected String, got #{name.class}." unless name.is_a?(String)
      raise ArgumentError, "Invalid argument 'number'. Expected Integer, got #{number.class}." unless number.is_a?(Integer)
      raise ArgumentError, "Invalid argument 'frame'. Expected Frame, got #{frame.class}." unless frame.is_a?(Frame)
      raise ArgumentError, "Invalid argument 'struct'. Expected StructureSet, got #{struct.class}." unless struct.is_a?(StructureSet)
      raise ArgumentError, "Invalid option :algorithm. Expected String, got #{options[:algorithm].class}." if options[:algorithm] && !options[:algorithm].is_a?(String)
      raise ArgumentError, "Invalid option :color. Expected String, got #{options[:color].class}." if options[:color] && !options[:color].is_a?(String)
      raise ArgumentError, "Invalid option :interpreter. Expected String, got #{options[:interpreter].class}." if options[:interpreter] && !options[:interpreter].is_a?(String)
      raise ArgumentError, "Invalid option :type. Expected String, got #{options[:type].class}." if options[:type] && !options[:type].is_a?(String)
      @slices = Array.new
      @associated_instance_uids = Hash.new
      # Set values:
      @number = number
      @name = name
      @algorithm = options[:algorithm] || 'Automatic'
      @type = options[:type] || 'CONTROL'
      @interpreter = options[:interpreter] || 'RTKIT'
      @color = options[:color] || random_color
      # Set references:
      @frame = frame
      @struct = struct
      # Register ourselves with the Frame and StructureSet:
      @frame.add_roi(self)
      @struct.add_roi(self)
    end

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_roi)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds a Slice instance to this ROI.
    #
    def add_slice(slice)
      raise ArgumentError, "Invalid argument 'slice'. Expected Slice, got #{slice.class}." unless slice.is_a?(Slice)
      @slices << slice unless @associated_instance_uids[slice.uid]
      @associated_instance_uids[slice.uid] = slice
    end

    # Sets the algorithm attribute.
    #
    def algorithm=(value)
      @algorithm = value && value.to_s
    end

    # Attaches a ROI to a specified ImageSeries, by setting the ROIs frame reference to the
    # Frame which the ImageSeries belongs to, and setting the Image reference of each of the Slices
    # belonging to the ROI to an Image instance which matches the coordinates of the Slice's Contour(s).
    # Raises an exception if a suitable match is not found for any Slice.
    #
    # === Notes
    #
    # This method can be useful when you have multiple segmentations based on the same image series
    # from multiple raters (perhaps as part of a comparison study), and the rater's software has modified
    # the UIDs of the original image series, so that the references of the returned Structure Set does
    # not match your original image series. This method uses coordinate information to calculate plane
    # equations, which allows it to identify the corresponding image slice even in the case of
    # slice geometry being non-perpendicular with respect to the patient geometry (direction cosine values != [0,1]).
    #
    def attach_to(series)
      raise ArgumentError, "Invalid argument 'series'. Expected ImageSeries, got #{series.class}." unless series.is_a?(Series)
      # Change struct association if indicated:
      if series.struct != @struct
        @struct.remove_roi(self)
        series.struct.add_roi(self)
        @struct = series.struct
      end
      # Change Frame if different:
      if @frame != series.frame
        @frame = series.frame
      end
      # Update slices:
      @slices.each do |slice|
        slice.attach_to(series)
      end
    end

    # Creates a binary volume object consisting of a series of binary (segmented) images,
    # extracted from the contours defined for the slices of this ROI.
    # Returns a BinVolume instance with binary image references equal to
    # the number of slices defined for this ROI.
    #
    # === Parameters
    #
    # * <tt>image_volume</tt> -- By default the BinVolume is created against the ImageSeries of the ROI's StructureSet. Optionally, a DoseVolume can be specified.
    #
    def bin_volume(image_volume=@struct.image_series.first)
      return BinVolume.from_roi(self, image_volume)
    end

    # Sets a new color for this ROI.
    #
    # === Parameters
    #
    # * <tt>col</tt> -- String. A proper color string (3 integers 0-255, each separated by a '\').
    #
    def color=(col)
      raise ArgumentError, "Invalid argument 'col'. Expected String, got #{col.class}." unless col.is_a?(String)
      colors = col.split("\\")
      raise ArgumentError, "Invalid argument 'col'. Expected 3 color values, got #{colors.length}." unless colors.length == 3
      colors.each do |str|
        c = str.to_i
        raise ArgumentError, "Invalid argument 'col'. Expected valid integer (0-255), got #{str}." if c < 0 or c > 255
        raise ArgumentError, "Invalid argument 'col'. Expected an integer, got #{str}." if c == 0 and str != "0"
      end
      @color = col
    end

    # Creates and returns a ROI Contour Sequence Item from the attributes of the ROI.
    #
    def contour_item
      item = DICOM::Item.new
      item.add(DICOM::Element.new(ROI_COLOR, @color))
      s = DICOM::Sequence.new(CONTOUR_SQ)
      item.add(s)
      item.add(DICOM::Element.new(REF_ROI_NUMBER, @number.to_s))
      # Add Contour items to the Contour Sequence (one or several items per Slice):
      @slices.each do |slice|
        slice.contours.each do |contour|
          s.add_item(contour.to_item)
        end
      end
      return item
    end

    # Iterates the Contour Sequence Items, collects Contour Items for each slice and passes them along to the Slice class.
    #
    def create_slices(contour_sequence)
      raise ArgumentError, "Invalid argument 'contour_sequence'. Expected DICOM::Sequence, got #{contour_sequence.class}." unless contour_sequence.is_a?(DICOM::Sequence)
      # Sort the contours by slices:
      slice_collection = Hash.new
      contour_sequence.each do |slice_contour_item|
        sop_uid = slice_contour_item[CONTOUR_IMAGE_SQ][0].value(REF_SOP_UID)
        slice_collection[sop_uid] = Array.new unless slice_collection[sop_uid]
        slice_collection[sop_uid] << slice_contour_item
      end
      # Create slices:
      slice_collection.each_pair do |sop_uid, items|
        Slice.create_from_items(sop_uid, items, self)
      end
    end

    # Creates a DoseDistribution based on the delineation of this ROI in the
    # specified RTDose series.
    #
    # === Parameters
    #
    # * <tt>dose_volume</tt> -- The DoseVolume to extract the dose distribution from. Defaults to the sum of the dose volumes of the first RTDose of the first plan of the parent StructureSet.
    #
    def distribution(dose_volume=@struct.plan.rt_dose.sum)
      raise ArgumentError, "Invalid argument 'dose_volume'. Expected DoseVolume, got #{dose_volume.class}." unless dose_volume.is_a?(DoseVolume)
      raise ArgumentError, "Invalid argument 'dose_volume'. The specified DoseVolume does not belong to this ROI's StructureSet." unless dose_volume.dose_series.plan.struct == @struct
      # Extract a binary volume from the ROI, based on the dose data:
      bin_vol = bin_volume(dose_volume)
      # Create a DoseDistribution from the BinVolume:
      dose_distribution = DoseDistribution.create(bin_vol)
      return dose_distribution
    end

    # Sets the frame attribute.
    #
    def frame=(frame)
      @frame = frame.to_frame
    end

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Returns the ImageSeries instance that this ROI is defined in.
    #
    def image_series
      return @struct.image_series.first
    end

    # Sets the interpreter attribute.
    #
    def interpreter=(value)
      @interpreter = value && value.to_s
    end

    # Sets the name attribute.
    #
    def name=(value)
      @name = value && value.to_s
    end

    # Returns the number of Contours belonging to this ROI through its Slices.
    #
    def num_contours
      num = 0
      @slices.each do |slice|
        num += slice.contours.length
      end
      return num
    end

    # Sets the number attribute.
    #
    def number=(value)
      @number = value.to_i
    end

    # Creates and returns a RT ROI Obervations Sequence Item from the attributes of the ROI.
    #
    def obs_item
      item = DICOM::Item.new
      item.add(DICOM::Element.new(OBS_NUMBER, @number.to_s))
      item.add(DICOM::Element.new(REF_ROI_NUMBER, @number.to_s))
      item.add(DICOM::Element.new(ROI_TYPE, @type))
      item.add(DICOM::Element.new(ROI_INTERPRETER, @interpreter))
      return item
    end

    # Removes the parent references of the ROI (StructureSet and Frame).
    #
    def remove_references
      @frame = nil
      @struct = nil
    end

    # Calculates the size (volume) of the ROI by evaluating the ROI's
    # delination in the referenced image series.
    # Returns a float, giving the volume in units of cubic centimeters,
    #
    def size
      volume = 0.0
      last_index = @slices.length - 1
      # Iterate each slice:
      @slices.each_index do |i|
        # Get the contoured area in this slice, convert it to volume and add to our total.
        # If the slice is the first or last, only multiply by half of the slice thickness:
        if i == 0 or i == last_index
          volume += @slices[i].area * image_series.slice_spacing * 0.5
        else
          volume += @slices[i].area * image_series.slice_spacing
        end
      end
      # Convert from mm^3 to cm^3:
      return volume / 1000.0
    end

    # Returns the Slice instance mathcing the specified SOP Instance UID (if an argument is used).
    # If a specified UID doesn't match, nil is returned.
    # If no argument is passed, the first Slice instance associated with the ROI is returned.
    #
    # === Parameters
    #
    # * <tt>uid</tt> -- String. The value of the SOP Instance UID element.
    #
    def slice(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        raise ArgumentError, "Invalid argument 'uid'. Expected String (or nil), got #{args.first.class}." unless [String, NilClass].include?(args.first.class)
        return @associated_instance_uids[args.first]
      else
        # No argument used, therefore we return the first Image instance:
        return @slices.first
      end
    end

    # Creates and returns a Structure Set ROI Sequence Item from the attributes of the ROI.
    #
    def ss_item
      item = DICOM::Item.new
      item.add(DICOM::Element.new(ROI_NUMBER, @number.to_s))
      item.add(DICOM::Element.new(REF_FRAME_OF_REF, @frame.uid))
      item.add(DICOM::Element.new(ROI_NAME, @name))
      item.add(DICOM::Element.new(ROI_ALGORITHM, @algorithm))
      return item
    end

    # Returns self.
    #
    def to_roi
      self
    end

    # Sets the type attribute.
    #
    def type=(value)
      @type = value && value.to_s
    end


    private


    # Creates and returns a random color string (used for the ROI Display Color element).
    #
    def random_color
      return "#{rand(256).to_i}\\#{rand(256).to_i}\\#{rand(256).to_i}"
    end

    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@algorithm, @color, @interpreter, @name, @number, @slices, @type]
    end

  end
end
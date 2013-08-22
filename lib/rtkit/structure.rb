module RTKIT

  # Contains DICOM data and methods related to the structures found in a Structure Set.
  #
  class Structure

    # ROI Generation Algorithm.
    attr_reader :algorithm
    # ROI Display Color.
    attr_reader :color
    # The Frame which this structure belongs to.
    attr_reader :frame
    # ROI Interpreter.
    attr_reader :interpreter
    # ROI Name.
    attr_reader :name
    # ROI Number (Integer).
    attr_reader :number
    # The StructureSet that the structure is defined in.
    attr_reader :struct
    # RT ROI Interpreted Type.
    attr_reader :type

    # Creates a new ROI instance from the three items of the structure set
    # which contains the information related to a particular ROI. This method
    # also creates and connects any child structures as indicated in the items
    # (e.g. Slice instances).
    #
    # @param [DICOM::Item] roi_item the ROI's Item from the Structure Set ROI Sequence
    # @param [DICOM::Item] contour_item the ROI's Item from the ROI Contour Sequence
    # @param [DICOM::Item] rt_item the ROI's Item from the RT ROI Observations Sequence
    # @param [StructureSet] struct the StructureSet instance which the ROI shall be associated with
    # @return [ROI] the created ROI instance
    #
    def self.create_from_items(roi_item, contour_item, rt_item, struct)
      raise ArgumentError, "Invalid argument 'roi_item'. Expected DICOM::Item, got #{roi_item.class}." unless roi_item.is_a?(DICOM::Item)
      raise ArgumentError, "Invalid argument 'contour_item'. Expected DICOM::Item, got #{contour_item.class}." unless contour_item.is_a?(DICOM::Item)
      raise ArgumentError, "Invalid argument 'rt_item'. Expected DICOM::Item, got #{rt_item.class}." unless rt_item.is_a?(DICOM::Item)
      raise ArgumentError, "Invalid argument 'struct'. Expected StructureSet, got #{struct.class}." unless struct.is_a?(StructureSet)
      # Determine what kind of structure we are dealing with:
      begin
        geometric_type = contour_item[CONTOUR_SQ][0].value(CONTOUR_GEO_TYPE)
      rescue
        RTKIT.logger.warn "A ROI item extracted from the structure set is missing necessary contour information."
        nil
      end
      # Extract DICOM information:
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
      if geometric_type == 'POINT'
        # Create the ROI instance:
        uid = contour_item[CONTOUR_SQ][0][CONTOUR_IMAGE_SQ][0].value(REF_SOP_UID)
        poi = POI.new(name, number, frame, struct, :algorithm => algorithm, :color => color, :interpreter => interpreter, :type => type, :uid => uid)
        poi.setup(contour_item[CONTOUR_SQ]) if contour_item[CONTOUR_SQ]
        poi
      elsif geometric_type == 'CLOSED_PLANAR'
        # Create the ROI instance:
        roi = ROI.new(name, number, frame, struct, :algorithm => algorithm, :color => color, :interpreter => interpreter, :type => type)
        # Create the Slices in which the ROI has contours defined:
        roi.create_slices(contour_item[CONTOUR_SQ]) if contour_item[CONTOUR_SQ]
        roi
      else
        RTKIT.logger.warn "Unsupported Contour Geometric Type enountered (#{geometric_type}). Unable to create ROI/POI."
        nil
      end
    end

    # Creates a new Structure instance.
    #
    # @param [String] name the ROI name
    # @param [Integer] number the ROI number
    # @param [Frame] frame the Frame instance which this Structure is associated with
    # @param [StructureSet] struct the StructureSet instance that this Structure belongs to
    # @param [Hash] options the options to use for creating the Structure
    # @option options [String] :algorithm the ROI generation algorithm (defaults to 'Automatic')
    # @option options [String] :color the ROI display color (defaults to a random color string (format: 'x\y\z' where [x,y,z] is a byte (0-255)))
    # @option options [String] :interpreter the ROI interpreter (defaults to 'RTKIT')
    # @option options [String] :type the ROI interpreted type (defaults to 'CONTROL')
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
      if other.respond_to?(:to_structure)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Sets the algorithm attribute.
    #
    # @param [NilClass, #to_s] value the ROI generation algorithm (3006,0036)
    #
    def algorithm=(value)
      @algorithm = value && value.to_s
    end

=begin
    # Attaches a Structure to a specified ImageSeries, by setting the structure's frame
    # reference to the Frame which the ImageSeries belongs to, and setting the
    # Image reference of each of the Slices belonging to the ROI to an Image
    # instance which matches the coordinates of the Slice's Contour(s).
    #
    # This method can be useful when you have multiple segmentations based on
    # the same image series from multiple raters (perhaps as part of a
    # comparison study), and the rater's software has modified the UIDs of the
    # original image series, so that the references of the returned Structure
    # Set does not match your original image series. This method uses
    # coordinate information to calculate plane equations, which allows it to
    # identify the corresponding image slice even in the case of slice geometry
    # being non-perpendicular with respect to the patient geometry (direction
    # cosine values != [0,1]).
    #
    # @param [Series] series the new ImageSeries instance which the ROI shall be associated with
    # @raise [ArgumentError] if a suitable match is not found for any of the ROI's slices
    #
    def attach_to(series)
      raise ArgumentError, "Invalid argument 'series'. Expected ImageSeries, got #{series.class}." unless series.is_a?(Series)
      # Change struct association if indicated:
      if series.struct != @struct
        @struct.remove_roi(self)
        StructureSet.new(RTKIT.series_uid, series) unless series.struct
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
=end

    # Sets a new color for this Structure.
    #
    # @param [String] value a properly formatted color string (3 integers 0-255 - each separated by a '\') (3006,002A)
    #
    def color=(value)
      # Make sure that the color string is of valid format before saving it:
      raise ArgumentError, "Invalid argument 'value'. Expected String, got #{value.class}." unless value.is_a?(String)
      colors = value.split("\\")
      raise ArgumentError, "Invalid argument 'value'. Expected 3 color values, got #{colors.length}." unless colors.length == 3
      colors.each do |str|
        c = str.to_i
        raise ArgumentError, "Invalid argument 'value'. Expected valid integer (0-255), got #{str}." if c < 0 or c > 255
        raise ArgumentError, "Invalid argument 'value'. Expected an integer, got #{str}." if c == 0 and str != "0"
      end
      @color = value
    end

    # Sets the frame attribute.
    #
    # @param [NilClass, #to_frame] value the ROI's referenced Frame instance
    #
    def frame=(value)
      @frame = value.to_frame
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

    # Gives the ImageSeries instance which this Structure is defined for.
    #
    # @return [ImageSeries] the image series which this Structure belongs to
    #
    def image_series
      return @struct.image_series.first
    end

    # Sets the interpreter attribute.
    #
    # @param [NilClass, #to_s] value the ROI interpreter (3006,00A6)
    #
    def interpreter=(value)
      @interpreter = value && value.to_s
    end

    # Sets the name attribute.
    #
    # @param [NilClass, #to_s] value the ROI name (3006,0026)
    #
    def name=(value)
      @name = value && value.to_s
    end

    # Sets the number attribute.
    #
    # @param [NilClass, #to_s] value the ROI number (3006,0022 - 3006,0082 - 3006,0084)
    #
    def number=(value)
      @number = value.to_i
    end

    # Creates a RT ROI Obervations Sequence Item from the attributes of the ROI instance.
    #
    # @return [DICOM::Item] a RT ROI obervations sequence item
    #
    def obs_item
      item = DICOM::Item.new
      item.add(DICOM::Element.new(OBS_NUMBER, @number.to_s))
      item.add(DICOM::Element.new(REF_ROI_NUMBER, @number.to_s))
      item.add(DICOM::Element.new(ROI_TYPE, @type))
      item.add(DICOM::Element.new(ROI_INTERPRETER, @interpreter))
      return item
    end

    # Removes the parent references of the Structure: the StructureSet
    # association (struct) and Frame association (frame).
    #
    def remove_references
      @frame = nil
      @struct = nil
    end

    # Creates a Structure Set ROI Sequence Item from the attributes of the Structure instance.
    #
    # @return [DICOM::Item] a structure set ROI sequence item
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
    # @return [Structure] self
    #
    def to_structure
      self
    end

    # Sets the type attribute.
    #
    # @param [NilClass, #to_s] value the RT ROI interpreted type (3006,00A4)
    #
    def type=(value)
      @type = value && value.to_s
    end


    private


    # Creates a random color string (used for the ROI Display Color element).
    #
    # @return [String] a properly formatted DICOM color string (with random colors)
    #
    def random_color
      return "#{rand(256).to_i}\\#{rand(256).to_i}\\#{rand(256).to_i}"
    end

    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@algorithm, @color, @interpreter, @name, @number, @type]
    end

  end
end
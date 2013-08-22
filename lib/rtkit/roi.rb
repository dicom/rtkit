module RTKIT

  # Contains DICOM data and methods related to a Region of Interest, defined in a Structure Set.
  #
  # === Relations
  #
  # * An image series has many ROIs, defined through a StructureSet.
  # * An image slice has only the ROIs which are contoured in that particular slice in the StructureSet.
  # * A ROI has many Slices.
  #
  class ROI < Structure

    # An array containing the Slices that the ROI is defined in.
    attr_reader :slices

    # Creates a new ROI instance.
    #
    # @param [String] name the ROI name
    # @param [Integer] number the ROI number
    # @param [Frame] frame the Frame instance which this ROI is associated with
    # @param [StructureSet] struct the StructureSet instance that this ROI belongs to
    # @param [Hash] options the options to use for creating the ROI
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
      @slices = Array.new
      @associated_instance_uids = Hash.new
      super(name, number, frame, struct, options)
      # Register ourselves with the Frame and StructureSet:
      @frame.add_structure(self)
      @struct.add_structure(self)
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
      if other.respond_to?(:to_roi)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds a Slice instance to this ROI.
    #
    # @param [Slice] slice a slice instance to be associated with this ROI
    #
    def add_slice(slice)
      raise ArgumentError, "Invalid argument 'slice'. Expected Slice, got #{slice.class}." unless slice.is_a?(Slice)
      @slices << slice unless @associated_instance_uids[slice.uid]
      @associated_instance_uids[slice.uid] = slice
    end

    # Attaches a ROI to a specified ImageSeries, by setting the ROIs frame
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
        @struct.remove_structure(self)
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

    # Creates a binary volume object consisting of a series of binary
    # (segmented) images which are extracted from the contours defined for the
    # slices of this ROI.
    #
    # @param [ImageSeries, DoseVolume] image_volume the DoseVolume/ImageSeries to create the binary volume against (defaults to the ImageSeries of the ROI's structure set)
    # @return [BinVolume] a binary volume with binary images equal to the number of slices defined for this ROI
    #
    def bin_volume(image_volume=@struct.image_series.first)
      return BinVolume.from_roi(self, image_volume)
    end

    # Creates a ROI Contour Sequence Item from the attributes of the ROI instance.
    #
    # @return [DICOM::Item] a ROI contour sequence item
    #
    def contour_item
      item = DICOM::Item.new
      item.add(DICOM::Element.new(ROI_COLOR, @color))
      item.add(DICOM::Element.new(REF_ROI_NUMBER, @number.to_s))
      s = DICOM::Sequence.new(CONTOUR_SQ)
      item.add(s)
      # Add Contour items to the Contour Sequence (one or several items per Slice):
      @slices.each do |slice|
        slice.contours.each do |contour|
          s.add_item(contour.to_item)
        end
      end
      return item
    end

    # Creates Slice instances from the contour sequence items of the contour
    # sequence, and connects these slices to this ROI instance.
    #
    # @param [DICOM::Sequence] contour_sequence a Contour Sequence
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

    # Creates a DoseDistribution based on the delineation by this ROI in the
    # specified RTDose series.
    #
    # @param [DoseVolume] dose_volume the dose volume to extract the dose distribution from (defaults to the sum of the dose volumes of the first RTDose of the first plan of the parent StructureSet)
    # @raise [ArgumentError] if given a dose volume who's plan does not belong to this ROI's structure set
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

    # Transfers the ROI (i.e. the pixels delineated by the ROI in its referenced
    # image series) to another (target) image series, where they are inserted
    # (overwriting existing pixel values) using the given offset vector.
    #
    # @param [ImageSeries] target_series the image series to export the ROI pixels to
    # @param [Coordinate] offset the cartesian offset applied to the ROI coordinates in the image series transfer
    #
    def export_pixels(target_series, offset)
      # Iterate the slices and determine the target image which corresponds to each slice:
      # Note we need to dupe the slices array, because this method will
      # add 'target slices' to this ROI instance.
      @slices.dup.each do |slice|
        target = target_series.image(slice.pos + offset.z)
        if target
          # Temporarily align the target image position with the source image:
          target.pos_x = target.pos_x - offset.x
          target.pos_y = target.pos_y - offset.y
          # Create a target slice (need to set the image reference manually, since the
          # target image is not related to this ROI (actually its Frame):
          t_slice = Slice.new(target.uid, self)
          t_slice.image = target
          # Iterate the contours of this slice to transfer pixels:
          slice.contours.each do |contour|
            t_slice.add_contour(contour)
          end
          # Determine the indices of the target image which is to get a new pixel value
          indices = t_slice.bin_image.indices
          # Determine the coordinate positions of each pixel:
          column_indices, row_indices = target.indices_general_to_specific(indices)
          x_positions, y_positions, z_positions = target.coordinates_from_indices(NArray[column_indices], NArray[row_indices])
          # Extract pixel values from original image by its coordinates.
          pixels = slice.image.extract_pixels(x_positions, y_positions, z_positions)
          # Insert pixel values in the target image.
          target.insert_pixels(indices, pixels)
          # Restore target image position:
          target.pos_x = target.pos_x + offset.x
          target.pos_y = target.pos_y + offset.y
        end
      end
    end

    # Fills the pixels of a volume (as defined by the delineation of this ROI)
    # in an image series with the given value. By default, the image series
    # related to the ROI's structure set is used, however, an alternative image
    # series (or dose volume) can be specified.
    #
    # @note As of yet the image class does not handle presentation values, so
    #   the input value has to be 'raw' values.
    # @param [Integer] value the pixel value to fill the ROI volume with
    # @param [ImageSeries, DoseVolume] image_volume the image series in which to fill the volume delineated by the ROI with a specific pixel value
    # @return [ImageSeries, DoseVolume] the modified image series
    #
    def fill(value, image_volume=@struct.image_series.first)
      bv = BinVolume.from_roi(self, image_volume)
      bv.bin_images.each do |bin_image|
        # Match a slice from the image volume to the current binary image:
        ref_image = image_volume.image(bin_image.pos_slice)
        ref_image.set_pixels(bin_image.selection.indices, value)
      end
      image_volume
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

    # Gives the number of Contour instances belonging to this ROI (through its
    # Slices).
    #
    # @return [Fixnum] the contour count
    #
    def num_contours
      num = 0
      @slices.each do |slice|
        num += slice.contours.length
      end
      return num
    end

    # Calculates the size (volume) of the ROI by evaluating the ROI's
    # delination in the referenced image series.
    #
    # @return [Float] the ROI volume (in units of cubic centimeters)
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

    # Gives the Slice instance mathcing the specified UID.
    #
    # @overload slice(uid)
    #   @param [String] uid SOP instance UID
    #   @return [Slice, NilClass] the matched slice (or nil if no slice is matched)
    # @overload slice
    #   @return [Slice, NilClass] the first slice of this instance (or nil if no child slices exists)
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

    # Returns self.
    #
    # @return [ROI] self
    #
    def to_roi
      self
    end

    # Moves the ROI by applying the given offset vector to its coordinates.
    #
    # @param [Float] x the offset along the x axis (in units of mm)
    # @param [Float] y the offset along the y axis (in units of mm)
    # @param [Float] z the offset along the z axis (in units of mm)
    #
    def translate(x, y, z)
      @slices.each do |s|
        s.translate(x, y, z)
      end
    end


    private


    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
      super << @slices
    end

  end
end
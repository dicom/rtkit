module RTKIT

  # Contains the DICOM data and methods related to a binary volume.
  #
  class BinVolume

    # An array of BinImage references.
    attr_reader :bin_images
    # Dice's Coeffecient.
    attr_accessor :dice
    # A NArray associated with this BinVolume (NB! This is a cached copy.
    # If you want to ensure to extract an narray which corresponds to the
    # BinVolume's Images, use the narray method instead.
    attr_accessor :narr
    # A score (fraction) of the segmented volume compared to a master volume, ranging from 0 (worst) to 1 (all true voxels segmented in this volume).
    attr_accessor :sensitivity
    # The BinVolume's series reference (e.g. ImageSeries or DoseVolume).
    attr_reader :series
    # A reference to the source of this BinaryVolume (ROI or Dose instance).
    attr_reader :source
    # A score (fraction) of the segmented volume compared to a master volume, ranging from 0 (worst) to 1 (none of the true remaining voxels are segmented in this volume).
    attr_accessor :specificity

    # Creates a new BinVolume instance from a DoseVolume. The BinVolume is
    # typically defined from a ROI delineation against an image series,
    # but it may also be applied to an rtdose 'image' series.
    #
    # @note Even though listed as optional parameters, at least one of the min and max
    #   options must be specified in order to construct a valid binary volume.
    #
    # @param [DoseVolume] dose_volume the dose volume from which to derive the binary volume
    # @param [Float, NilClass] min an (optional) lower dose limit from which to define the the binary volume
    # @param [Float, NilClass] max an (optional) upper dose limit from which to define the the binary volume
    # @param [ImageSeries, DoseVolume] image_volume the reference image series (image references for the binary images will be picked from this series)
    # @return [BinVolume] the created BinVolume instance
    #
    def self.from_dose(dose_volume, min=nil, max=nil, image_volume)
      raise ArgumentError, "Invalid argument 'dose_volume'. Expected DoseVolume, got #{dose_volume.class}." unless dose_volume.class == DoseVolume
      raise ArgumentError, "Invalid argument 'image_volume'. Expected ImageSeries or DoseVolume, got #{image_volume.class}." unless [ImageSeries, DoseVolume].include?(image_volume.class)
      raise ArgumentError "Need at least one dose limit parameter. Neither min nor max was specified." unless min or max
      # Create the BinVolume instance:
      bv = self.new(dose_volume) # FIXME: Specify dose limit somehow here?!
      # Add BinImages for each of the DoseVolume's images:
      dose_narr = dose_volume.dose_arr
      dose_volume.images.each_index do |i|
        #ref_image = image_volume.image(dose_img.pos_slice)
        ref_image = image_volume.images[i]
        dose_image = dose_narr[i, true, true]
        # Create the bin narray:
        narr = NArray.byte(ref_image.columns, ref_image.rows)
        if !min
          # Only the max limit is specified:
          marked_indices = (dose_image.le max.to_f)
        elsif !max
          # Only the min limit is specified:
          marked_indices = (dose_image.ge min.to_f)
        else
          # Both min and max limits are specified:
          smaller = (dose_image.le max.to_f)
          bigger = (dose_image.ge min.to_f)
          marked_indices = smaller.and bigger
        end
        narr[marked_indices] = 1
        bin_img = BinImage.new(narr, ref_image)
        bv.add(bin_img)
      end
      return bv
    end

    # Creates a new BinVolume instance from a ROI. The BinVolume is
    # typically defined from a ROI delineation against an image series,
    # but it may also be applied to an rtdose 'image' series.
    #
    # @param [ROI] roi the ROI from which to define the binary volume
    # @param [ImageSeries, DoseVolume] image_volume the reference image series (image references for the binary images will be picked from this series)
    # @return [BinVolume] the created BinVolume instance
    #
    def self.from_roi(roi, image_volume)
      raise ArgumentError, "Invalid argument 'roi'. Expected ROI, got #{roi.class}." unless roi.is_a?(ROI)
      raise ArgumentError, "Invalid argument 'image_volume'. Expected ImageSeries or DoseVolume, got #{image_volume.class}." unless [ImageSeries, DoseVolume].include?(image_volume.class)
      # Create the BinVolume instance:
      bv = self.new(roi.image_series, :source => roi)
      missed_slices = 0
      # Add BinImages for each of the ROIs slices:
      roi.slices.each do |slice|
        image = image_volume.image(slice.pos)
        if image
          BinImage.from_contours(slice.contours, image, bv)
        else
          missed_slices += 1
        end
      end
      RTKIT.logger.warn("The BinVolume created from ROI '#{roi.name}' missed #{missed_slices} slices. #{bv.bin_images.length} slices were successfully created.") if missed_slices > 0
      return bv
    end

    # Creates a new BinVolume instance from an image series (i.e. ImageSeries
    # or DoseVolume). A BinVolume created this way specifies the entire volume:
    # i.e. the Binvolume has the same dimensions as the image series, and all
    # pixels are 1.
    #
    # @param [ImageSeries, DoseVolume] image_volume the reference image series (image references for the binary images will be picked from this series)
    # @return [BinVolume] the created BinVolume instance
    #
    def self.from_volume(image_volume)
      raise ArgumentError, "Invalid argument 'image_volume'. Expected ImageSeries or DoseVolume, got #{image_volume.class}." unless [ImageSeries, DoseVolume].include?(image_volume.class)
      # Create the BinVolume instance:
      bv = self.new(image_volume)
      # Add BinImages for each of the ROIs slices:
      image_volume.images.each do |image|
        # Make an NArray of proper size filled with ones:
        narr = NArray.byte(image.columns, image.rows).fill(1)
        # Create the BinImage instance and add it to the BinVolume:
        bin_img = BinImage.new(narr, image)
        bv.add(bin_img)
      end
      return bv
    end

    # Creates a new BinVolume instance.
    #
    # @param [ImageSeries, DoseVolume] series the image series which forms the reference data of the binary volume
    # @param [Hash] options the options to use for creating the BinVolume
    # @option options [Array<BinImage>] :images beam type (defaults to 'STATIC')
    # @option options [ROI, RTDose] :source treatment delivery type (defaults to 'TREATMENT')
    #
    def initialize(series, options={})
      raise ArgumentError, "Invalid argument 'series'. Expected ImageSeries or DoseVolume, got #{series.class}." unless [ImageSeries, DoseVolume].include?(series.class)
      raise ArgumentError, "Invalid option 'images'. Expected Array, got #{options[:images].class}." if options[:images] && options[:images].class != Array
      raise ArgumentError, "Invalid option 'source'. Expected ROI or RTDose, got #{options[:source].class}." if options[:source] && ![ROI, RTDose].include?(options[:source].class)
      raise ArgumentError, "Invalid option 'images'. Expected only BinImage instances in the array, got #{options[:images].collect{|i| i.class}.uniq}." if options[:images] && options[:images].collect{|i| i.class}.uniq.length > 1
      @series = series
      @bin_images = options[:images] || Array.new
      @source = options[:source]
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
      if other.respond_to?(:to_bin_volume)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds a BinImage instance to the volume.
    #
    # @param [BinImage] bin_image a binary image object
    #
    def add(bin_image)
      raise ArgumentError, "Invalid argument 'bin_image'. Expected BinImage, got #{bin_image.class}." unless bin_image.is_a?(BinImage)
      @bin_images << bin_image
    end

    # Gives the the number of columns in the images of the volume.
    #
    # @return [Integer, NilClass] the number of columns in the associated binary image arrays
    #
    def columns
      return @bin_images.first.columns if @bin_images.first
    end

    # Returns the number of frames (slices) in the set of images that makes up this volume.
    #
    # @return [Integer] the number of frames in the associated binary image set
    #
    def frames
      return @bin_images.length
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

    # Creates a 3D volume array consisting of the 2d Narray images from the
    # BinImage instances that makes up this volume.
    #
    # @param [Boolean] sort_slices
    # @return [NArray, NilClass] a 3D numerical array (or nil if no binary images are associated)
    #
    def narray(sort_slices=true)
      if @bin_images.length > 0
        # Determine the slice position of each BinImage:
        locations = Array.new
        if sort_slices
          @bin_images.collect {|image| locations << image.pos_slice}
          images = @bin_images.sort_by_order(locations.sort_order)
        else
          images = @bin_images
        end
        # Create volume array and fill in the images:
        volume = NArray.byte(frames, columns, rows)
        images.each_with_index do |sorted_image, i|
          volume[i, true, true] = sorted_image.narray
        end
        @narr = volume
      end
    end

    # Rearranges the binary image instances belonging to this volume by the
    # given order.
    #
    # @param [Array<Integer>] order an array of indices
    # @return [Array<BinImage>] the reordered images
    #
    def reorder_images(order)
      @bin_images = @bin_images.sort_by_order(order)
    end

    # Gives the the number of rows in the images of the volume.
    #
    # @return [Integer, NilClass] the number of rows in the associated binary image arrays
    #
    def rows
      return @bin_images.first.rows if @bin_images.first
    end

    # Returns self.
    #
    # @return [BinImage] self
    #
    def to_bin_volume
      self
    end

    # Creates a ROI instance from the segmentation of this BinVolume.
    #
    # @param [StructureSet] struct the structure set instance which the created ROI will be associated with
    # @param [Hash] options the options to use for creating the ROI
    # @option options [String] :algorithm the ROI generation algorithm (defaults to 'STATIC')
    # @option options [String] :name the ROI name (defaults to 'BinVolume')
    # @option options [Integer] :number the ROI number (defaults to the first available ROI Number in the StructureSet)
    # @option options [String] :interpreter the ROI interpreter (defaults to 'RTKIT')
    # @option options [String] :type the ROI interpreted type (defaults to 'CONTROL')
    # @return [ROI] the created ROI instance (including slice references from the associated binary images)
    #
    def to_roi(struct, options={})
      raise ArgumentError, "Invalid argument 'struct'. Expected StructureSet, got #{struct.class}." unless struct.is_a?(StructureSet)
      # Set values:
      algorithm = options[:algorithm]
      name = options[:name] || 'BinVolume'
      number = options[:number]
      interpreter = options[:interpreter]
      type = options[:type]
      # Create the ROI:
      roi = struct.create_roi(@series.frame, :algorithm => algorithm, :name => name, :number => number, :interpreter => interpreter, :type => type)
      # Create Slices:
      @bin_images.each do |bin_image|
        bin_image.to_slice(roi)
      end
      return roi
    end


    private


    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@bin_images, @dice, @narr, @sensitivity, @specificity]
    end

  end
end
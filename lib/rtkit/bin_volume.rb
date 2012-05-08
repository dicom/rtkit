module RTKIT

  # Contains the DICOM data and methods related to a binary volume.
  #
  # === Inheritance
  #
  # * As the BinVolume class inherits from the PixelData class, all PixelData methods are available to instances of BinVolume.
  #
  class BinVolume < PixelData

    # An array of BinImage references.
    attr_reader :bin_images
    # Dice's Coeffecient.
    attr_accessor :dice
    # A NArray associated with this BinVolume (NB! This is a cached copy. If you want to ensure to
    # extract an narray which corresponds to the BinVolume's Images, use the narray method instead.
    attr_accessor :narr
    # A score (fraction) of the segmented volume compared to a master volume, ranging from 0 (worst) to 1 (all true voxels segmented in this volume).
    attr_accessor :sensitivity
    # The BinVolume's series reference (e.g. ImageSeries or DoseVolume).
    attr_reader :series
    # A reference to the source of this BinaryVolume (ROI or Dose instance).
    attr_reader :source
    # A score (fraction) of the segmented volume compared to a master volume, ranging from 0 (worst) to 1 (none of the true remaining voxels are segmented in this volume).
    attr_accessor :specificity

    # Creates a new BinVolume instance from a DoseVolume.
    # The BinVolume is typically defined from a ROI delineation against an image series,
    # but it may also be applied to an rtdose 'image' series.
    # Returns the BinVolume instance.
    #
    # === Notes
    #
    # * Even though listed as optional parameters, at least one of the min and max
    #   options must be specified in order to construct a valid binary volume.
    #
    # === Parameters
    #
    # * <tt>image_volume</tt> -- The image volume which the binary volume will be based on (a DoseVolume or an ImageSeries).
    # * <tt>min</tt> -- Float. An optional lower dose limit from which to define the the binary volume.
    # * <tt>max</tt> -- Float. An optional upper dose limit from which to define the the binary volume.
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

    # Creates a new BinVolume instance from a ROI.
    # The BinVolume is typically defined from a ROI delineation against an image series,
    # but it may also be applied to an rtdose 'image' series.
    # Returns the BinVolume instance.
    #
    # === Parameters
    #
    # * <tt>roi</tt> -- A ROI from which to define the binary volume.
    # * <tt>image_volume</tt> -- The image volume which the binary volume will be based on (an ImageSeries or a DoseVolume).
    #
    def self.from_roi(roi, image_volume)
      raise ArgumentError, "Invalid argument 'roi'. Expected ROI, got #{roi.class}." unless roi.is_a?(ROI)
      raise ArgumentError, "Invalid argument 'image_volume'. Expected ImageSeries or DoseVolume, got #{image_volume.class}." unless [ImageSeries, DoseVolume].include?(image_volume.class)
      # Create the BinVolume instance:
      bv = self.new(roi.image_series, :source => roi)
      # Add BinImages for each of the ROIs slices:
      roi.slices.each do |slice|
        image = image_volume.image(slice.pos)
        BinImage.from_contours(slice.contours, image, bv)
        #bv.add(slice.bin_image)
      end
      return bv
    end

    # Creates a new BinVolume instance from an image series (i.e. ImageSeries or DoseVolume).
    # A BinVolume created this way specified the entire volume: i.e. the Binvolume
    # has the same dimensions as the image series, and all pixels are 1.
    # Returns the BinVolume instance.
    #
    # === Parameters
    #
    # * <tt>image_volume</tt> -- The image volume which the binary volume will be based on (an ImageSeries or a DoseVolume).
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
    # === Parameters
    #
    # * <tt>series</tt> -- The image series (e.g. ImageSeries or DoseVolume) which forms the reference data of the BinVolume.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:images</tt> -- An array of BinImage instances that is assigned to this BinVolume.
    # * <tt>:source</tt> -- The object which is the source of the binary (segmented) data (i.e. ROI or Dose/Hounsfield threshold).
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

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_bin_volume)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds a BinImage instance to the volume.
    #
    def add(bin_image)
      raise ArgumentError, "Invalid argument 'bin_image'. Expected BinImage, got #{bin_image.class}." unless bin_image.is_a?(BinImage)
      @bin_images << bin_image
    end

    # Returns the number of columns in the images of the volume.
    #
    def columns
      return @bin_images.first.columns if @bin_images.first
    end

    # Returns the number of frames (slices) in the set of images that makes up this volume.
    #
    def frames
      return @bin_images.length
    end

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Returns 3d volume array consisting of the 2d Narray images from the BinImage instances that makes up this volume.
    # Returns nil if no BinImage instances are connected to this BinVolume.
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

    def reorder_images(order)
      @bin_images = @bin_images.sort_by_order(order)
    end

    # Returns the number of rows in the images of the volume.
    #
    def rows
      return @bin_images.first.rows if @bin_images.first
    end

    # Returns self.
    #
    def to_bin_volume
      self
    end

    # Creates a ROI instance from the segmentation of this BinVolume.
    # Returns the ROI instance.
    #
    # === Parameters
    #
    # * <tt>struct</tt> -- A StructureSet instance which the ROI will be connected to.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:algorithm</tt> -- String. The ROI Generation Algorithm. Defaults to 'Automatic'.
    # * <tt>:name</tt> -- String. The ROI Name. Defaults to 'BinVolume'.
    # * <tt>:number</tt> -- Integer. The ROI Number. Defaults to the first available ROI Number in the StructureSet.
    # * <tt>:interpreter</tt> -- String. The ROI Interpreter. Defaults to 'RTKIT'.
    # * <tt>:type</tt> -- String. The ROI Interpreted Type. Defaults to 'CONTROL'.
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


    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@bin_images, @dice, @narr, @sensitivity, @specificity]
    end

  end
end
module RTKIT

  # Contains the DICOM data and methods related to the comparison of binary volumes (i.e. segmented volumes).
  #
  class BinMatcher

    # The reference (master) BinVolume.
    attr_reader :master
    # An array of BinVolumes.
    attr_reader :volumes

    # Creates a new BinMatcher instance.
    #
    # @param [Array<BinVolume>] volumes a collection of binary volumes to be matched
    # @param [BinVolume] master a reference binary volume which the other volumes will be compared against
    #
    def initialize(volumes=nil, master=nil)
      raise ArgumentError, "Invalid argument 'volumes'. Expected Array, got #{volumes.class}." if volumes && volumes.class != Array
      raise ArgumentError, "Invalid argument 'master'. Expected BinVolume, got #{master.class}." if master && master.class != BinVolume
      raise ArgumentError, "Invalid argument 'volumes'. Expected array to contain only BinVolume instances, got #{volumes.collect{|i| i.class}.uniq}." if volumes && volumes.collect{|i| i.class}.uniq != [BinVolume]
      @volumes = volumes || Array.new
      @master = master
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
      if other.respond_to?(:to_bin_matcher)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds a BinVolume instance to the matcher.
    #
    # @param [BinVolume] volume a binary volume to be associated with this BinMatcher instance
    #
    def add(volume)
      raise ArgumentError, "Invalid argument 'volume'. Expected BinVolume, got #{volume.class}." unless volume.is_a?(BinVolume)
      @volumes << volume
    end

    # Gives a sorted array of volumes, (reversely) sorted by their sensitivity
    # score. The volumes are sorted in such a way that the best scoring
    # volume (highest sensitivity) appears first. If no volumes are defined,
    # an empty array is returned.
    #
    # @return [Array<BinVolume>] a sorted array of binary volumes
    #
    def by_sensitivity
      return (@volumes.sort_by {|v| v.sensitivity}).reverse
    end

    # Gives a sorted array of volumes, (reversely) sorted by their specificity
    # score. The volumes are sorted in such a way that the best scoring
    # volume (highest specificity) appears first. If no volumes are defined,
    # an empty array is returned.
    #
    # @return [Array<BinVolume>] a sorted array of binary volumes
    #
    def by_specificity
      return (@volumes.sort_by {|v| v.specificity}).reverse
    end

    # Ensures that a valid comparison between volumes can be done, by making
    # sure that every volume has a BinImage for any image that is referenced
    # among the BinVolumes. If some BinVolumes are missing one or more
    # BinImages, empty BinImages will be created for these BinVolumes.
    #
    # @note The master volume (if present) is also processed by this method.
    #
    def fill_blanks
      if @volumes.length > 0
        # Register all unique images referenced by the various volumes:
        images = Set.new
        # Include the master volume (if it is present):
        [@volumes, @master].flatten.compact.each do |volume|
          volume.bin_images.each do |bin_image|
            images << bin_image.image unless images.include?(bin_image.image)
          end
        end
        # Check if any of the volumes have images missing, and if so, create empty images:
        images.each do |image|
          [@volumes, @master].flatten.compact.each do |volume|
            match = false
            volume.bin_images.each do |bin_image|
              match = true if bin_image.image == image
            end
            unless match
              # Create BinImage:
              bin_img = BinImage.new(NArray.byte(image.columns, image.rows), image)
              volume.add(bin_img)
            end
          end
        end
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

    # Sets the master (reference) BinVolume.
    #
    def master=(volume)
      raise ArgumentError, "Invalid argument 'volume'. Expected BinVolume, got #{volume.class}." unless volume.is_a?(BinVolume)
      @master = volume
    end

    # Creates an array of 3D NArrays from the binary volumes of this instance.
    # Note that the master volume (if present) is excluded, and if no volumes
    # associated, an empty array is returned.
    #
    # @return [Array<NArray>] an array of 3D NArray from the associated binary volumes
    #
    def narrays(sort_slices=true)
      n = Array.new
      @volumes.each do |volume|
        n << volume.narray(sort_slices)
      end
      return n
    end

=begin
    # Along each dimension of the input binary volume(s), removes any index (i.e. slice, column or row)
    # which is empty in all volumes (including the master volume, if specified). This method results
    # in reduced volumes, corresponding to a clipbox which tightly encloses the defined (positive) volume
    # (indices with pixel value 1 in at least one of the volumes). Such a reduced volume may yield e.g.
    # specificity scores with better contrast.
    #
    def remove_empty_indices
      # It only makes sense to run this volume reduction if the number of dimensions are 2 or more:
      volumes = [*@volumes, master].compact
      # For each volume the indices typically correspond to the following
      # descriptions: slice, column & row
      volumes.first.narray.shape.each_with_index do |size, dim_index|
        extract = Array.new(volumes.first.narray.dim, true)
        positive_indices = Array.new
        size.times do |i|
          extract[dim_index] = i
          positive = false
          volumes.each do |volume|
            positive = true if volume.narray[*extract].max > 0
          end
          positive_indices << i if positive
        end
        extract[dim_index] = positive_indices
        if positive_indices.length < size
          volumes.each do |volume|
            volume.narr = volume.narr[*extract]
          end
        end
      end
      volumes.each {|vol| puts vol.narr.inspect}
      volumes.each {|vol| puts vol.narr.shape}
      @volumes.each {|vol| puts vol.narr.shape}
    end
=end

    # Scores the volumes of the BinMatcher instance against the reference
    # (master) volume, by using Dice's coeffecient. The score is
    # stored in the 'dice' attribute of each binary volume instance.
    #
    # @see http://en.wikipedia.org/wiki/Dice%27s_coefficient
    #
    def score_dice
      if @master
        # Find the voxel-indices for the master where the decisions are 1 and 0:
        pos_indices_master = (@master.narray.eq 1).where
        @volumes.each do |bin_vol|
          pos_indices_vol = (bin_vol.narray.eq 1).where
          num_common = (@master.narray[pos_indices_vol].eq 1).where.length
          bin_vol.dice = 2 * num_common / (pos_indices_master.length + pos_indices_vol.length).to_f
        end
      end
    end

    # Scores the volumes of the BinMatcher instance against the reference
    # (master) volume, by using Sensitivity and Specificity. The scores are
    # stored in the 'sensitivity' and 'specificity' attribute of each binary
    # volume instance.
    #
    # @see http://en.wikipedia.org/wiki/Sensitivity_and_specificity
    #
    def score_ss
      if @master
        # Find the voxel-indices for the master where the decisions are 1 and 0:
        pos_indices, neg_indices = (@master.narray.eq 1).where2
        @volumes.each do |bin_vol|
          narr = bin_vol.narray
          bin_vol.sensitivity = (narr[pos_indices].eq 1).where.length / pos_indices.length.to_f
          bin_vol.specificity = (narr[neg_indices].eq 0).where.length / neg_indices.length.to_f
        end
      end
    end

    # Rearranges the binary images belonging to the associated binary volumes
    # (note that the master volume (if present) is excluded), by matching the
    # binary images by their image instance references. This is done to ensure
    # that the 3D NArrays which are extracted from these volumes are truly
    # comparable.
    #
    # @raise Raises an exception if there are any irregularities in the number
    #   of BinImage instances or Image references.
    #
    def sort_volumes
      # It only makes sense to sort if we have at least two volumes:
      if @volumes.length > 1
        raise "All volumes of the BinMatcher isntance must have the same number of BinImages (got lengths #{@volumes.collect {|v| v.bin_images.length}})." if @volumes.collect {|v| v.bin_images.length}.uniq.length > 1
        # Collect the Image references of the BinImage's of the first volume:
        desired_image_order = Array.new
        @volumes.first.bin_images.collect {|bin_image| desired_image_order << bin_image.image}
        raise "One (or more) Image references were nil in the first BinVolume instance of the BinMatcher. Unable to sort BinImages when they lack Image reference." if desired_image_order.compact.length != desired_image_order.length
        # Sort the BinImages of the remaining volumes so that their order of images are equal to that of the first volume:
        (1...@volumes.length).each do |i|
          current_image_order = Array.new
          @volumes[i].bin_images.collect {|bin_image| current_image_order << bin_image.image}
          sort_order = current_image_order.compare_with(desired_image_order)
          @volumes[i].bin_images.sort_by_order!(sort_order)
          #@volumes[i].reorder_images(sort_order)
        end
      end
    end

    # Returns self.
    #
    # @return [Beam] self
    #
    def to_bin_matcher
      self
    end


    private


    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@volumes, @master]
    end

  end
end
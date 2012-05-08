module RTKIT

  # Contains DICOM data and methods related to a DoseDistribution,
  # a collection of dose points extracted from a dose volume.
  #
  # === Relations
  #
  # * A DoseDistribution belongs to the DoseVolume from which it was created.
  # * A DoseDistribution contains various methods to return a Dose (point) instance.
  #
  class DoseDistribution

    # The doses values belonging to this distribution (array of floats).
    attr_reader :doses
    # The DoseVolume that the DoseDistribution is derived from.
    attr_reader :volume

    # Creates a new DoseDistribution instance from a BinVolume.
    # The BinVolume is typically defined from a ROI delineation against a DoseVolume.
    # Returns the DoseDistribution instance.
    #
    # === Parameters
    #
    # * <tt>bin_volume</tt> -- A BinVolume, referencing a DoseVolume, from which to extract a DoseDistribution.
    #
    def self.create(bin_volume)
      raise ArgumentError, "Invalid argument 'bin_volume'. Expected BinVolume, got #{bin_volume.class}." unless bin_volume.is_a?(BinVolume)
      raise ArgumentError, "Invalid argument 'bin_volume'. It must reference a DoseVolume, got #{bin_volume.bin_images.first.image.series.class}." unless bin_volume.bin_images.first.image.series.is_a?(DoseVolume)
      dose_volume = bin_volume.bin_images.first.image.series
      # Extract a selection of pixel values from the dose images based on the provided binary volume:
      dose_values = NArray.sfloat(0)
      bin_volume.bin_images.each do |bin_image|
        slice_pixel_values = bin_image.image.pixel_values(bin_image.selection)
        slice_dose_values = slice_pixel_values.to_type(4) * bin_image.image.series.scaling
        dose_values = NArray[*dose_values, *slice_dose_values]
      end
      # Create the DoseDistribution instance:
      dd = self.new(dose_values, dose_volume)
      return dd
    end

    # Creates a new DoseDistribution instance.
    #
    # === Parameters
    #
    # * <tt>doses</tt> -- An array/NArray of doses (floats).
    # * <tt>volume</tt> -- The DoseVolume which this DoseDistribution belongs to.
    #
    def initialize(doses, volume)
      #raise ArgumentError, "Invalid argument 'doses'. Expected Array, got #{doses.class}." unless doses.is_a?(Array)
      raise ArgumentError, "Invalid argument 'volume'. Expected DoseVolume, got #{volume.class}." unless volume.is_a?(DoseVolume)
      # Store doses as a sorted (float) NArray:
      @doses = NArray.to_na(doses).sort.to_type(4)
      # Set references:
      @volume = volume
    end

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_dose_distribution)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Calculates the dose that at least the specified
    # percentage of the volume receives.
    # Returns a dose (Float) in units of Gy.
    #
    # === Parameters
    #
    # * <tt>percent</tt> -- Integer/Float. The percent of the volume which receives a dose higher than the returned dose.
    #
    # === Examples
    #
    #   # Calculate the near minimum dose (e.g. up to 2 % of the volume receives a dose less than this):
    #   near_min = ptv_distribution.d(98)
    #   # Calculate the near maximum dose (e.g. at most 2 % of the volume receives a dose higher than this):
    #   near_max = ptv_distribution.d(2)
    #
    def d(percent)
      raise RangeError, "Argument 'percent' must be in the range [0-100]." if percent.to_f < 0 or percent.to_f > 100
      d_index = ((@doses.length - 1) * (1 - percent.to_f * 0.01)).round
      return @doses[d_index]
    end

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Calculates the homogeneity index of the dose distribution.
    # A low (near zero) value corresponds to high homogeneity (e.q. 0.1).
    # Returns the index value as a float.
    #
    # === Notes
    #
    # * The homogeneity index is defined as:
    #  HI = ( d(2) - d(98) ) / d(50)
    #  For more details, refer to ICRU Report No. 83, Chapter 3.7.1.
    #
    # === Examples
    #
    #   # Calculate the homogeneity index of the dose distribution of a PTV ROI for a given plan:
    #   homogeneity_index = ptv_distribution.hindex
    #
    def hindex
      return (d(2) - d(98)) / d(50).to_f
    end

    # Returns the number of dose values in the DoseDistribution.
    #
    def length
      @doses.length
    end

    alias_method :size, :length

    # Calculates the maximum dose.
    #
    def max
      @doses.max
    end

    # Calculates the arithmethic mean (average) dose.
    #
    def mean
      @doses.mean
    end

    # Calculates the median dose.
    #
    def median
      @doses.median
    end

    # Calculates the minimum dose.
    #
    def min
      @doses.min
    end

    # Calculates the root mean square deviation (the population standard deviation).
    #
    # === Notes
    #
    # * Uses N in the denominator for calculating the standard deviation of the sample.
    #
    def rmsdev
      @doses.rmsdev
    end

    # Calculates the sample standard deviation of the dose distribution.
    #
    # === Notes
    #
    # * Uses Bessel's correction (N-1 in the denominator).
    #
    def stddev
      @doses.stddev
    end

    # Returns self.
    #
    def to_dose_distribution
      self
    end

    # Calculates the percentage of the volume that receives
    # a dose higher than or equal to the specified dose.
    # Returns a percentage (Float).
    #
    # === Parameters
    #
    # * <tt>dose</tt> -- Integer/Float. The dose threshold value to apply to the dose distribution.
    #
    # === Examples
    #
    #   # Calculate the low dose spread (e.g. the percentage of the lung that receives a dose higher than 5 Gy):
    #   coverage_low = lung_distribution.v(5)
    #   # Calculate the high dose spread (e.g. the percentage of the lung that receives a dose higher than 20 Gy):
    #   coverage_high = lung_distribution.v(20)
    #
    def v(dose)
      raise RangeError, "Argument 'dose' cannot be negative." if dose.to_f < 0
      # How many dose values are higher than the threshold?
      num_above = (@doses.ge dose.to_f).where.length
      # Divide by total number of elements and convert to percentage:
      return num_above / @doses.length.to_f * 100
    end


    private


    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@doses.to_a, @volume]
    end

  end
end
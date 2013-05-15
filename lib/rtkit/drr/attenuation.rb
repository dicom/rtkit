module RTKIT

  # Handles the attenuation of a ray through a medium.
  #
  # === References
  #
  # Hounsfield scale:
  # * http://en.wikipedia.org/wiki/Hounsfield_scale
  #
  # Mass attenuation coefficients:
  # NIST (National Institute of Standards and Technology)
  # * http://physics.nist.gov/PhysRefData/XrayMassCoef/ComTab/water.html
  #
  class Attenuation

    # The linear attenuation coefficient in water for a photon of a given energy (in units of cm^-1).
    attr_reader :ac_water
    # The density of water (at standard pressure and temperature) (in units of g/cm^3).
    attr_reader :density
    # The photon energy used.
    attr_reader :energy

    # Creates an Attenuation instance.
    #
    # @param [Float] energy the photon energy to use for attenuation calculation
    #
    def initialize(energy=0.05)
      raise ArgumentError, "Invalid parameter energy. Expected a Float greater than zero, got #{energy.to_f}" unless energy.to_f > 0.0
      @energy = energy
      # Set the linear attenuation coefficient of water for a 50 keV photon:
      #@ac_water = 0.2269
      # Set the density of distilled water in standard pressure and temperature conditions:
      @density = 1.0
      # Determine the attenuation coefficient to use for the given energy:
      determine_coefficient
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
      if other.respond_to?(:to_attenuation)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Sets the linear attenuation coefficient attribute.
    #
    # @param [Float] coeff the linear attenuation coefficient in water of a photon of a particular energy
    #
    def ac_water=(coeff)
      @ac_water = coeff.to_f
    end

    # Calculates the attentuation through a voxel.
    #
    # @param [Integer] hu a Hounsfield unit
    # @param [Float] length the length of a ray's travel through a medium (units of mm)
    # @return [Float] the calculated attenuation of a ray through the given medium
    #
    def attenuation(hu, length)
      # Note that the length is converted to units of cm in the calculation.
      # The exponential gives transmission: To get attenuation we subtract from one:
      1 - Math.exp(-attenuation_coefficient(hu) * 0.1 * length.to_f)
    end

    # Gives the linear attenuation coefficient corresponding
    # to a given hounsfield unit.
    #
    # @param [Integer] hu a Hounsfield unit
    # @return [Float] the calculated attenuation coefficient for this hounsfield unit
    #
    def attenuation_coefficient(hu)
      coeff = hu * @ac_water / 1000.0 + @ac_water
    end

    # Gives the linear attenuation coefficients corresponding
    # to the given hounsfield units.
    #
    # @param [NArray<Integer>] h_units Hounsfield units
    # @return [NArray<Float>] the calculated attenuation coefficients for these hounsfield units
    #
    def attenuation_coefficients(h_units)
      coeff = h_units.to_type(NArray::FLOAT) * (@ac_water / 1000.0) + @ac_water
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

    # Returns self.
    #
    # @return [Attenuation] self
    #
    def to_attenuation
      self
    end

    # Calculates the attentuation for a vector pair of hounsfield units and lengths.
    #
    # @param [NArray<Integer>] h_units a vector of Hounsfield units
    # @param [NArray<Float>] lengths a vector of lengths (in units of mm)
    # @return [Float] the calculated attenuation of a ray through the given medium
    #
    def vector_attenuation(h_units, lengths)
      raise ArgumentError, "Incosistent arguments. Expected both NArrays to have the same length, go #{h_units.length} and #{lengths.length}" if h_units.length != lengths.length
      # Note that the lengths are converted to units of cm in the calculation.
      # The exponential gives transmission: To get attenuation we subtract from one:
      1 - Math.exp(-(attenuation_coefficients(h_units) * 0.1 * lengths).sum)
    end


    private


    # Determines the attenuation coefficient to use, based on the given energy.
    #
    def determine_coefficient
      # Array of photon energies (in units of MeV).
      @energies = [
        0.001,
        0.0015,
        0.002,
        0.003,
        0.004,
        0.005,
        0.006,
        0.008,
        0.01,
        0.015,
        0.02,
        0.03,
        0.04,
        0.05,
        0.06,
        0.08,
        0.1,
        0.15,
        0.2,
        0.3,
        0.4,
        0.5,
        0.6,
        0.8,
        1.0,
        1.25,
        1.5,
        2.0,
        3.0,
        4.0,
        5.0,
        6.0,
        8.0,
        10.0,
        15.0,
        20.0
      ]
      # Array of mass attenuation coefficients for the above energies, for liquid water (in units of cm^2/g):
      @att_coeffs = [
        4078,
        1376,
        617.3,
        192.9,
        82.78,
        42.58,
        24.64,
        10.37,
        5.329,
        1.673,
        0.8096,
        0.3756,
        0.2683,
        0.2269,
        0.2059,
        0.1837,
        0.1707,
        0.1505,
        0.137,
        0.1186,
        0.1061,
        0.09687,
        0.08956,
        0.07865,
        0.07072,
        0.06323,
        0.05754,
        0.04942,
        0.03969,
        0.03403,
        0.03031,
        0.0277,
        0.02429,
        0.02219,
        0.01941,
        0.01813
      ]
      # Determine the coefficient:
      if @energy >= 20.0
        # When the energy is above 20, we use the coefficient for 20 MeV:
        @ac_water = @att_coeffs.last
      else
        if i = @energies.index(@energy)
          # When it exactly matches one of the listed energies, use its corresponding coefficient:
          @ac_water = @att_coeffs[i]
        else
          # When the given energy is between two of the listed values, interpolate:
          i_after = @energies.index {|x| x > @energy}
          if i_after
            e_high = @energies[i_after]
            e_low = @energies[i_after - 1]
            ac_high = @att_coeffs[i_after]
            ac_low = @att_coeffs[i_after - 1]
            @ac_water = (ac_high - ac_low ) / (e_high - e_low) * (@energy - e_low)
          else
            raise "Unexpected behaviour with index in the energy interpolation logic."
          end
        end
      end
    end

    # Collects the attributes of this instance.
    #
    # @return [Array<String>] an array of attributes
    #
    def state
       [@energy, @ac_water]
    end

  end

end
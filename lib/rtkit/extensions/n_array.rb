class NArray

  # Expands a vector with another vector.
  #
  # @raise [ArgumentError] if other is not an NArray vector
  # @param [NArray] other a one-dimensional numerical array (vector)
  # @return [NArray] self expanded with other
  # @example Expand a given vector with another
  #   a = NArray[1, 2, 3]
  #   b = NArray[14, 15]
  #   a.expand_vector(b)
  #   => NArray.int(5):
  #   [1, 2, 3, 14, 15]
  #
  def expand_vector(other)
    raise ArgumentError, "Expected an NArray, got #{other.class}" unless other.is_a?(NArray)
    raise ArgumentError, "Expected a vector (1 dimension) for self and other, got #{self.dim} and #{other.dim} dimensions for self and other" if other.dim > 1 or self.dim > 1
    new = NArray.new(self.typecode, self.length + other.length)
    new[0..(self.length-1)] = self if self.length > 0
    new[(self.length)..-1] = other if other.length > 0
    return new
  end


  # Checks if an image array is segmented. Returns true if it is, and false if not.
  # We define the image to be segmented if it contains at least positive 3 pixel values.
  #
  def segmented?
    (self.gt 0).where.length > 2 ? true : false
  end

end
class String

  # Converts a string (containing a x,y,z coordinate triplet (floats)
  # separated by '\') to a Coordinate instance.
  #
  # @return [Coordinate] the created coordinate
  #
  def to_coordinate
    values = self.split("\\").collect {|str| str.to_f}
    raise ArgumentError, "Unable to create coordinate. Expected a string containing 3 values, got #{values.length}" unless values.length >= 3
    return RTKIT::Coordinate.new(values[0], values[1], values[2])
  end

end
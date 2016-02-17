module RTKIT

  # Contains DICOM data and methods related to a Selection of pixels (indices)
  # from the binary 2D NArray of a BinImage instance.
  #
  # === Relations
  #
  # * The Selection belongs to a BinImage.
  #
  class Selection

    # The BinImage that the Selection belongs to.
    attr_reader :bin_image
    # An array of (general) indices.
    attr_reader :indices
    # An NArray of (general) indices.
    #attr_reader :indices_narr

    # Creates a new Selection instance from an Array (or NArray) of (general)
    # indices.
    #
    # @param [Array, NArray] indices an Array/NArray of general indices (integer values)
    # @param [BinImage] bin_image the BinImage instance that this Selection is derived from
    # @return [Selection] the created Selection instance
    #
    def self.create_from_array(indices, bin_image)
      raise ArgumentError, "Invalid argument 'indices'. Expected Array/NArray, got #{indices.class}." unless [NArray, Array].include?(indices.class)
      raise ArgumentError, "Invalid argument 'bin_image'. Expected BinImage, got #{bin_image.class}." unless bin_image.is_a?(BinImage)
      raise ArgumentError, "Invalid argument 'indices'. Expected Array to contain only integers, got #{indices.collect{|i| i.class}.uniq}." if indices.is_a?(Array) and not indices.collect{|i| i.class}.uniq == [Fixnum]
      # Create the Selection:
      s = self.new(bin_image)
      # Set the indices:
      s.add_indices(indices)
      return s
    end

    # Creates a new Selection instance.
    #
    # @param [BinImage] bin_image the BinImage instance which this Selection is associated with
    #
    def initialize(bin_image)
      raise ArgumentError, "Invalid argument 'bin_image'. Expected BinImage, got #{bin_image.class}." unless bin_image.is_a?(BinImage)
      @bin_image = bin_image
      @indices = Array.new
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
      if other.respond_to?(:to_selection)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds an array of (general) indices to this Selection.
    #
    # @param [Array, NArray] indices general pixel indices to be added to the selection
    #
    def add_indices(indices)
      raise ArgumentError, "Invalid argument 'indices'. Expected Array/NArray, got #{indices.class}." unless [NArray, Array].include?(indices.class)
      raise ArgumentError, "Invalid argument 'indices'. Expected Array to contain only integers, got #{indices.collect{|i| i.class}.uniq}." if indices.is_a?(Array) and not indices.collect{|i| i.class}.uniq == [Fixnum]
      indices = indices.to_a if indices.is_a?(NArray)
      @indices += indices
    end

    # Determines specific column indices from general pixel indices.
    #
    # @return [Array] the column indices of this selection (empty array if the selection is empty)
    #
    def columns
      return @indices.collect {|index| index % @bin_image.columns}
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

    # Gives the length of this selection (the number of indices).
    #
    # @return [Fixnum] the index count
    #
    def length
      return @indices.length
    end

    # Determines specific row indices from general pixel indices.
    #
    # @return [Array] the row indices of this selection (empty array if the selection is empty)
    #
    def rows
      return @indices.collect {|index| index / @bin_image.columns}
    end

    # Shifts the indices of this selection by the specified number of columns
    # and rows. Positive arguments increment the column and row indices.
    #
    # @note No out of bounds check is performed for indices that are shifted
    #   past the image boundary!
    # @param [Integer] delta_col the desired column shift
    # @param [Integer] delta_row the desired row shift
    # @return [Array] the shifted indices
    #
    def shift(delta_col, delta_row)
      raise ArgumentError, "Invalid argument 'delta_col'. Expected Integer, got #{delta_col.class}." unless delta_col.is_a?(Integer)
      raise ArgumentError, "Invalid argument 'delta_row'. Expected Integer, got #{delta_row.class}." unless delta_row.is_a?(Integer)
      new_columns = @indices.collect {|index| index % @bin_image.columns + delta_col}
      new_rows = @indices.collect {|index| index / @bin_image.columns + delta_row}
      # Set new indices:
      @indices = Array.new(new_rows.length) {|i| new_columns[i] + new_rows[i] * @bin_image.columns}
    end

    # Shifts the indices of this selection by the specified number of columns
    # and rows, then virtually creates an image that is 'cropped' by 2*columns
    # and 2*rows, and adapts the indices of the selection to this virtually
    # cropped image.
    #
    # Negative arguments decrement the column and row indices and crops at the
    # end of the columns and rows.
    #
    # Positive arguments increment the column and row indices and crops at the
    # start of the columns and rows.
    #
    # @note No out of bounds check is performed for indices that are shifted
    #   past the image boundary!
    # @param [Integer] delta_col the desired column shift
    # @param [Integer] delta_row the desired row shift
    # @return [Array] the shifted indices
    #
    def shift_and_crop(delta_col, delta_row)
      raise ArgumentError, "Invalid argument 'delta_col'. Expected Integer, got #{delta_col.class}." unless delta_col.is_a?(Integer)
      raise ArgumentError, "Invalid argument 'delta_row'. Expected Integer, got #{delta_row.class}." unless delta_row.is_a?(Integer)
      new_columns = @indices.collect {|index| index % @bin_image.columns - delta_col.abs}
      new_rows = @indices.collect {|index| index / @bin_image.columns - delta_row.abs}
      # Set new indices:
      @indices = Array.new(new_rows.length) {|i| new_columns[i] + new_rows[i] * (@bin_image.columns - delta_col.abs * 2)}
    end

    # Shifts the indices of this selection by the specified number of columns.
    # A positive argument increment the column indices.
    #
    # @note No out of bounds check is performed for indices that are shifted
    #   past the image boundary.
    # @param [Integer] delta the desired column shift
    # @return [Array] the shifted indices
    #
    def shift_columns(delta)
      raise ArgumentError, "Invalid argument 'delta'. Expected Integer, got #{delta.class}." unless delta.is_a?(Integer)
      new_columns = @indices.collect {|index| index % @bin_image.columns + delta}
      new_rows = rows
      # Set new indices:
      @indices = Array.new(new_columns.length) {|i| new_columns[i] + new_rows[i] * @bin_image.columns}
    end

    # Shifts the indices of this selection by the specified number of rows.
    # A positive argument increment the row indices.
    #
    # @note No out of bounds check is performed for indices that are shifted
    #   past the image boundary.
    # @param [Integer] delta the desired row shift
    # @return [Array] the shifted indices
    #
    def shift_rows(delta)
      raise ArgumentError, "Invalid argument 'delta'. Expected Integer, got #{delta.class}." unless delta.is_a?(Integer)
      new_columns = columns
      new_rows = @indices.collect {|index| index / @bin_image.columns + delta}
      # Set new indices:
      @indices = Array.new(new_rows.length) {|i| new_columns[i] + new_rows[i] * @bin_image.columns}
    end

    # Returns self.
    #
    # @return [Selection] self
    #
    def to_selection
      self
    end


    private


    # Collects the attributes of this instance.
    #
    # @return [Array] an array of attributes
    #
    def state
       [@indices]
    end

  end

end
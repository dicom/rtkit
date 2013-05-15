module RTKIT

  # This is a mixin-module for the classes that are image 'parents',
  # i.e. they contain a reference to an array of image instances.
  #
  # This module is mixed in by the ImageSeries and DoseVolume classes.
  #
  module ImageParent

    # Gives the slice spacing (a float value in units of mm), which describes
    # the distance between two neighbouring images in this image series.
    #
    # @note If the image series contains a single (or zero) images,
    #   a slice spacing can not be determined and nil is returned.
    # @return [Float, NilClass] the distance between slices (or nil if undefined)
    #
    def slice_spacing
      if @slice_spacing
        # If the slice spacing has already been computed, return it instead of recomputing:
        return @slice_spacing
      else
        if @images.length > 1
          # Collect slice positions and sort them:
          slice_positions = NArray.to_na(@images.collect{|image| image.pos_slice}.sort)
          spacings = (slice_positions[1..-1] - slice_positions[0..-2]).abs
          @slice_spacing = spacings.to_a.most_common_value
        end
      end
    end

    # Creates a VoxelSpace instance from the image instances belonging
    # to this image series.
    #
    # @return [VoxelSpace] the created VoxelSpace instance
    #
    def to_voxel_space
      raise "This image series has no associated images. Unable to create a VoxelSpace." unless @images.length > 0
      img = @images.first
      # Create the voxel space:
      vs = VoxelSpace.create(img.columns, img.rows, @images.length, img.col_spacing, img.row_spacing, slice_spacing, Coordinate.new(img.pos_x, img.pos_y, img.pos_slice))
      # Fill it with pixel values:
      @images.each_with_index do |image, i|
        vs[true, true, i] = image.narray
      end
      vs
    end

    # Updates the position that is registered for the image instance for this series.
    #
    # @param [Image] image an instance belonging to this image series
    # @param [Float] new_pos a new slice position to be associated with the image instance
    #
    def update_image_position(image, new_pos)
      raise ArgumentError, "Invalid argument 'image'. Expected Image, got #{image.class}." unless image.is_a?(Image)
      # Remove old position key:
      @image_positions.delete(image.pos_slice)
      # Add the new position:
      @image_positions[new_pos] = image
    end

  end
end
module RTKIT

  # This is a mixin-module for the classes that are image 'parents',
  # i.e. they contain a reference to an array of image instances.
  #
  # This module is mixed in by the ImageSeries and DoseVolume classes.
  #
  module ImageParent

    # Returns the slice spacing (a float value in units of mm), which describes
    # the distance between two neighbouring images in this image series.
    # NB! If the image series contains 0 or 1 image, a slice spacing can not be
    # determined and nil is returned.
    #
    def slice_spacing
      if @slice_spacing
        # If the slice spacing has already been computed, return it instead of recomputing:
        return @slice_spacing
      else
        if @images.length > 1
          # Collect slice positions:
          slice_positions = NArray.to_na(@images.collect{|image| image.pos_slice})
          spacings = (slice_positions[1..-1] - slice_positions[0..-2]).abs
          @slice_spacing = spacings.to_a.most_common_value
        end
      end
    end

    # Updates the position that is registered for the image for this series.
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
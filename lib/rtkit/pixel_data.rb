module RTKIT

  # A collection of methods for dealing with pixel data in both 2D images and 3D volumes.
  #
  # === Inheritance
  #
  # These methods are available to instances of the following classes:
  # * Image
  # * Dose
  #
  class PixelData

    # Converts from two NArrays of image X & Y indices to physical coordinates X, Y & Z (in mm).
    # The X, Y & Z coordinates are returned in three NArrays of equal size as the input index NArrays.
    # The image coordinates are calculated using the direction cosines of the Image Orientation (Patient) element (0020,0037).
    #
    # === Notes
    #
    # * For details about Image orientation, refer to the DICOM standard: PS 3.3 C.7.6.2.1.1
    #
    def coordinates_from_indices(column_indices, row_indices)
      raise ArgumentError, "Invalid argument 'column_indices'. Expected NArray, got #{column_indices.class}." unless column_indices.is_a?(NArray)
      raise ArgumentError, "Invalid argument 'row_indices'. Expected NArray, got #{row_indices.class}." unless row_indices.is_a?(NArray)
      raise ArgumentError, "Invalid arguments. Expected NArrays of equal length, got #{column_indices.length} and #{row_indices.length}." unless column_indices.length == row_indices.length
      raise "Invalid attribute 'cosines'. Expected a 6 element Array, got #{cosines.class} #{cosines.length if cosines.is_a?(Array)}." unless cosines.is_a?(Array) && cosines.length == 6
      raise "Invalid attribute 'pos_x'. Expected Float, got #{pos_x.class}." unless pos_x.is_a?(Float)
      raise "Invalid attribute 'pos_y'. Expected Float, got #{pos_y.class}." unless pos_y.is_a?(Float)
      raise "Invalid attribute 'pos_slice'. Expected Float, got #{pos_slice.class}." unless pos_slice.is_a?(Float)
      raise "Invalid attribute 'col_spacing'. Expected Float, got #{col_spacing.class}." unless col_spacing.is_a?(Float)
      raise "Invalid attribute 'row_spacing'. Expected Float, got #{row_spacing.class}." unless row_spacing.is_a?(Float)
      # Convert indices integers to floats:
      column_indices = column_indices.to_f
      row_indices = row_indices.to_f
      # Calculate the coordinates by multiplying indices with the direction cosines and applying the image offset:
      x = pos_x + (column_indices * col_spacing * cosines[0]) + (row_indices * row_spacing * cosines[3])
      y = pos_y + (column_indices * col_spacing * cosines[1]) + (row_indices * row_spacing * cosines[4])
      z = pos_slice + (column_indices * col_spacing * cosines[2]) + (row_indices * row_spacing * cosines[5])
      return x, y, z
    end

    # Converts from three (float) NArrays of X, Y & Z physical coordinates (in mm) to image slice indices X & Y.
    # The X & Y indices are returned in two NArrays of equal size as the input coordinate NArrays.
    # The image indices are calculated using the direction cosines of the Image Orientation (Patient) element (0020,0037).
    #
    # === Notes
    #
    # * For details about Image orientation, refer to the DICOM standard: PS 3.3 C.7.6.2.1.1
    #
    def coordinates_to_indices(x, y, z)
      raise ArgumentError, "Invalid argument 'x'. Expected NArray, got #{x.class}." unless x.is_a?(NArray)
      raise ArgumentError, "Invalid argument 'y'. Expected NArray, got #{y.class}." unless y.is_a?(NArray)
      raise ArgumentError, "Invalid argument 'z'. Expected NArray, got #{z.class}." unless z.is_a?(NArray)
      raise ArgumentError, "Invalid arguments. Expected NArrays of equal length, got #{x.length}, #{y.length} and #{z.length}." unless [x.length, y.length, z.length].uniq.length == 1
      raise "Invalid attribute 'cosines'. Expected a 6 element Array, got #{cosines.class} #{cosines.length if cosines.is_a?(Array)}." unless cosines.is_a?(Array) && cosines.length == 6
      raise "Invalid attribute 'pos_x'. Expected Float, got #{pos_x.class}." unless pos_x.is_a?(Float)
      raise "Invalid attribute 'pos_y'. Expected Float, got #{pos_y.class}." unless pos_y.is_a?(Float)
      raise "Invalid attribute 'pos_slice'. Expected Float, got #{pos_slice.class}." unless pos_slice.is_a?(Float)
      raise "Invalid attribute 'col_spacing'. Expected Float, got #{col_spacing.class}." unless col_spacing.is_a?(Float)
      raise "Invalid attribute 'row_spacing'. Expected Float, got #{row_spacing.class}." unless row_spacing.is_a?(Float)
      # Calculate the indices by multiplying coordinates with the direction cosines and applying the image offset:
      column_indices = ((x-pos_x)/col_spacing*cosines[0] + (y-pos_y)/col_spacing*cosines[1] + (z-pos_slice)/col_spacing*cosines[2]).round
      row_indices = ((x-pos_x)/row_spacing*cosines[3] + (y-pos_y)/row_spacing*cosines[4] + (z-pos_slice)/row_spacing*cosines[5]).round
      return column_indices, row_indices
    end

    # Fills the provided image array with lines of a specified value, based on two vectors of column and row indices.
    # The image is expected to be a (two-dimensional) NArray.
    # Returns the processed image array.
    #
    def draw_lines(column_indices, row_indices, image, value)
      raise ArgumentError, "Invalid argument 'column_indices'. Expected Array, got #{column_indices.class}." unless column_indices.is_a?(Array)
      raise ArgumentError, "Invalid argument 'row_indices'. Expected Array, got #{row_indices.class}." unless row_indices.is_a?(Array)
      raise ArgumentError, "Invalid arguments. Expected Arrays of equal length, got #{column_indices.length}, #{row_indices.length}." unless column_indices.length == row_indices.length
      raise ArgumentError, "Invalid argument 'image'. Expected NArray, got #{image.class}." unless image.is_a?(NArray)
      raise ArgumentError, "Invalid number of dimensions for argument 'image'. Expected 2, got #{image.shape.length}." unless image.shape.length == 2
      raise ArgumentError, "Invalid argument 'value'. Expected Integer, got #{value.class}." unless value.is_a?(Integer)
      column_indices.each_index do |i|
        image = draw_line(column_indices[i-1], column_indices[i], row_indices[i-1], row_indices[i], image, value)
      end
      return image
    end

    # Iterative, queue based flood fill algorithm.
    # Replaces all pixels of a specific value that are contained by pixels of different value.
    # The replacement value along with the starting coordinates are passed as parameters to this method.
    # It seems a recursive method is not suited for Ruby due to its limited stack space (a problem in general for scripting languages).
    #
    def flood_fill(col, row, image, fill_value)
      existing_value = image[col, row]
      queue = Array.new
      queue.push([col, row])
      until queue.empty?
        col, row = queue.shift
        if image[col, row] == existing_value
          west_col, west_row = ff_find_border(col, row, existing_value, :west, image)
          east_col, east_row = ff_find_border(col, row, existing_value, :east, image)
          # Fill the line between the two border pixels (i.e. not touching the border pixels):
          image[west_col..east_col, row] = fill_value
          q = west_col
          while q <= east_col
            [:north, :south].each do |direction|
              same_col, next_row = ff_neighbour(q, row, direction)
              begin
                queue.push([q, next_row]) if image[q, next_row] == existing_value
              rescue
                # Out of bounds. Do nothing.
              end
            end
            q, same_row = ff_neighbour(q, row, :east)
          end
        end
      end
      return image
    end

    # Converts general image indices to specific column and row indices based on the
    # provided image indices and the number of columns in the image.
    #
    def indices_general_to_specific(indices, n_cols)
      if indices.is_a?(Array)
        row_indices = indices.collect{|i| i/n_cols}
        column_indices = [indices, row_indices].transpose.collect{|i| i[0] - i[1] * n_cols}
      else
        # Assume Fixnum or NArray:
        row_indices = indices/n_cols # Values are automatically rounded down.
        column_indices = indices-row_indices*n_cols
      end
      return column_indices, row_indices
    end

    # Converts specific x and y indices to general image indices based on the provided specific indices and x size of the NArray image.
    #
    def indices_specific_to_general(column_indices, row_indices, n_cols)
      if column_indices.is_a?(Array)
        indices = Array.new
        column_indices.each_index {|i| indices << column_indices[i] + row_indices[i] * n_cols}
        return indices
      else
        # Assume Fixnum or NArray:
        return column_indices + row_indices * n_cols
      end
    end

    # A convenience method for printing image information.
    # NB! This has been used only for debugging, and will soon be removed.
    #
    def print_img(narr=@narray)
      puts "Image dimensions: #{@columns}*#{@rows}"
      narr.shape[0].times do |i|
        puts narr[true, i].to_a.to_s
      end
    end


    private


    # Draws a single line in the (NArray) image matrix based on a start- and an end-point.
    # The method uses an iterative Bresenham Line Algorithm.
    # Returns the processed image array.
    #
    def draw_line(x0, x1, y0, y1, image, value)
      steep = ((y1-y0).abs) > ((x1-x0).abs)
      if steep
        x0,y0 = y0,x0
        x1,y1 = y1,x1
      end
      if x0 > x1
        x0,x1 = x1,x0
        y0,y1 = y1,y0
      end
      deltax = x1-x0
      deltay = (y1-y0).abs
      error = (deltax / 2).to_i
      y = y0
      ystep = nil
      if y0 < y1
        ystep = 1
      else
        ystep = -1
      end
      for x in x0..x1
        if steep
          begin
            image[y,x] = value # (switching variables)
          rescue
            # Our line has gone outside the image. Do nothing for now, but the proper thing to do would be to at least return some status boolean indicating that this has occured.
          end
        else
          begin
            image[x,y] = value
          rescue
            # Our line has gone outside the image.
          end
        end
        error -= deltay
        if error < 0
          y += ystep
          error += deltax
        end
      end
      return image
    end

    # Searches left and right to find the 'border' in a row of pixels the image array.
    # Returns a column and row index. Used by the flood_fill() method.
    #
    def ff_find_border(col, row, existing_value, direction, image)
      next_col, next_row = ff_neighbour(col, row, direction)
      begin
        while image[next_col, next_row] == existing_value
          col, row = next_col, next_row
          next_col, next_row = ff_neighbour(col, row, direction)
        end
      rescue
        # Out of bounds. Do nothing.
      end
      col = 0 if col < 1
      row = 0 if row < 1
      return col, row
    end

    # Returns the neighbour index based on the specified direction.
    # Used by the flood_fill() method and its dependency; the ff_find_border() method.
    # :east => to the right when looking at an array image printout on the screen
    #
    def ff_neighbour(col, row, direction)
      case direction
        when :north then return col, row-1
        when :south then return col, row+1
        when :east  then return col+1, row
        when :west  then return col-1, row
      end
    end

  end
end
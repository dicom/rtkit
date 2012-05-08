# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe BinImage do

    before :each do
      @sop = '1.245.123'
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.345.789', 'CT', @f, @st)
      @ss = StructureSet.new('1.765.12', @is)
      @roi = ROI.new("Brain", 1, @f, @ss)
      @slice = Slice.new(@sop, @roi)
      @image = Image.new(@sop, @is)
      @image.cosines = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0]
      @image.col_spacing = 0.5
      @image.row_spacing = 1.0
      @image.pos_slice = 99.9
      @image.pos_x = -15.5
      @image.pos_y = -25.5
      @columns = 10
      @rows = 8
      @narray = NArray.byte(@columns, @rows)
      @bin = BinImage.new(@narray, @image)
    end

    context "::new" do

      it "should raise an ArgumentError when a non-NArray is passed as a 'narray' argument" do
        expect {BinImage.new(Array.new, @image)}.to raise_error(ArgumentError, /narray/)
      end

      it "should raise an ArgumentError when a non-Image is passed as an 'image' argument" do
        expect {BinImage.new(@narray, 'not-an-image')}.to raise_error(ArgumentError, /image/)
      end

      it "should raise an ArgumentError when the 'narray' argument is not a two-dimensional NArray" do
        expect {BinImage.new(NArray.byte(10), @image)}.to raise_error(ArgumentError, /narray/)
        expect {BinImage.new(NArray.byte(5, 5, 5), @image)}.to raise_error(ArgumentError, /narray/)
      end

      it "should raise an ArgumentError when the 'narray' argument is not an NArray of type 'byte'" do
        expect {BinImage.new(NArray.int(10, 10), @image)}.to raise_error(ArgumentError, /narray/)
      end

      it "should raise an ArgumentError when the 'narray' argument is a non-binary NArray (contains value other than 0 and 1)" do
        expect {BinImage.new(NArray.byte(10,10).indgen!, @image)}.to raise_error(ArgumentError, /narray/)
      end

      it "should pass the 'narray' argument to the 'narray' attribute" do
        @bin.narray.should eql @narray
      end

      it "should pass the 'image' argument to the 'image' attribute" do
        @bin.image.should eql @image
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        bin_other = BinImage.new(@narray, @image)
        (@bin == bin_other).should be_true
      end

      it "should be false when comparing two instances having different attributes" do
        bin_other = BinImage.new(NArray.byte(@columns, @rows).fill(1), @image)
        (@bin == bin_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@bin == 42).should be_false
      end

    end


    context "#add" do

      it "should raise an ArgumentError when a non-NArray is passed as a 'pixels' argument" do
        expect {@bin.add(Array.new)}.to raise_error(ArgumentError, /pixels/)
      end

      it "should raise an ArgumentError when the 'pixels' argument is of a different shape than the instance narray" do
        expect {@bin.add(NArray.byte(6, 6))}.to raise_error(ArgumentError, /pixels/)
      end

      it "should raise an ArgumentError when the 'pixels' argument is not an NArray of type 'byte'" do
        expect {@bin.add(NArray.int(@columns, @rows))}.to raise_error(ArgumentError, /pixels/)
      end

      it "should raise an ArgumentError when the 'pixels' argument is a non-binary NArray (contains value other than 0 and 1)" do
        expect {@bin.add(NArray.byte(@columns, @rows).indgen!)}.to raise_error(ArgumentError, /pixels/)
      end

      it "should add the indices who's value equals 1 in the pixels array to the instance array" do
        original = NArray.byte(@columns, @rows)
        original_indices = [0,2,3,4,5]
        original[original_indices] = 1
        bin = BinImage.new(original, @image)
        pixels = NArray.byte(@columns, @rows)
        new_indices = [4,5,6,7,8,10]
        pixels[new_indices] = 1
        bin.add(pixels)
        (bin.narray.eq 1).where.to_a.should eql (original_indices + new_indices).uniq
        # Ensure the rest of the pixels are (still) zero:
        (bin.narray.eq 0).where.length.should eql (bin.narray.length - (bin.narray.eq 1).where.length)
      end

    end


    context "#col_spacing" do

      it "should return the 'col_spacing' attribute of the referenced Image instance" do
        @bin.col_spacing.should eql @image.col_spacing
      end

    end


    context "#columns" do

      it "should return the number of rows in the instance 'narray' attribute" do
        @bin.columns.should eql @narray.shape[0]
      end

    end


    context "#contour_image" do

      it "should return an empty image array (with shape equal to the shape of the instance narray) when called on a empty BinImage instance" do
        image = @bin.contour_image
        image.class.should eql NArray
        image.shape.should eql @bin.narray.shape
        (image.eq 0).where.length.should eql @bin.narray.length
      end

      it "should return an NArray image which is equal to instance narray, which features a compact 2x2 square" do
        image = NArray.byte(@columns, @rows)
        image[1..2, 1..2] = 1
        @bin.add(image)
        image = @bin.contour_image
        image.to_a.should eql @bin.narray.to_a
      end

      it "should return an NArray image with the 4 corners of the original square marked" do
        image = NArray.byte(@columns, @rows)
        image[1..3, 1..3] = 1
        @bin.add(image)
        image = @bin.contour_image
        (image.eq 1).where.to_a.should eql [11, 13, 31, 33]
      end

      it "should return the four corner coordinates of two 3x3 squares, marked by values of 1 and 2 respectively" do
        image = NArray.byte(@columns, @rows)
        image[1..3, 1..3] = 1
        image[5..7, 3..5] = 1
        @bin.add(image)
        img = @bin.contour_image
        (img.eq 1).where.to_a.should eql [11, 13, 31, 33]
        (img.eq 2).where.to_a.should eql [35, 37, 55, 57]
      end

    end


    context "#contour_indices" do

=begin
      before :each do
        image = NArray.byte(@columns, @rows)
        image[1..3, 1..3] = 1
        image[5..7, 3..5] = 1
        @bin.add(image)
      end
=end

      it "should return an empty array when called on a empty BinImage instance" do
        contours = @bin.contour_indices
        contours.class.should eql Array
        contours.length.should eql 0
      end

      it "should return a selection of the four corner indices of a compact 2x2 square, in a one-element array (with the corners appearing in a clockwise order, the top left coordinate first, the bottom left last)" do
        @bin.narray[1..2, 1..2] = 1
        contours = @bin.contour_indices
        contours.length.should eql 1
        contours.first.indices.should eql [11, 12, 22, 21]
      end

      it "should return a selection of the four corner indices of a 3x3 square, in a one-element array (with the corners appearing in a clockwise order, the top left coordinate first, the bottom left last)" do
        @bin.narray[1..3, 1..3] = 1
        contours = @bin.contour_indices
        contours.length.should eql 1
        contours.first.indices.should eql [11, 13, 33, 31]
      end

      it "should return the four corner indices of the completely filled image, in a one-element array (with the corners appearing in a clockwise order, the top left coordinate first, the bottom left last)" do
        @bin.narray.fill(1)
        contours = @bin.contour_indices
        contours.length.should eql 1
        contours.first.indices.should eql [0, 9, 79, 70]
      end

      it "should return the three corner indices of a compact triangle, in a one-element array (with the corners appearing in a clockwise order, the top left coordinate first, the bottom left last)" do
        @bin.narray[[1, 2, 11]] = 1
        contours = @bin.contour_indices
        contours.length.should eql 1
        contours.first.indices.should eql [1, 2, 11]
      end

      it "should return a selection of the three corner indices of a triangle, in a one-element array (with the corners appearing in a clockwise order, the top left coordinate first, the bottom left last)" do
        @bin.narray[[1, 2, 3, 4, 11, 12, 13, 21, 22, 31]] = 1
        contours = @bin.contour_indices
        contours.length.should eql 1
        contours.first.indices.should eql [1, 4, 31]
      end

      it "should return the corner indices of an irregular shape consisting of multiple rectangles, in a one-element array (with the corners appearing in a clockwise order, the top left coordinate first, the bottom left last)" do
        @bin.narray[1..8, 1..2] = 1
        @bin.narray[3..8, 5..6] = 1
        @bin.narray[7..8, 3..4] = 1
        contours = @bin.contour_indices
        contours.length.should eql 1
        contours.first.indices.should eql [11, 18, 68, 63, 53, 56, 47, 37, 26, 21]
      end

      it "should return indices for a single contour for the two compact squares which are 8-connected " do
        @bin.narray[0..1, 2..3] = 1
        @bin.narray[2..3, 0..1] = 1
        contours = @bin.contour_indices
        contours.length.should eql 1
        contours.first.indices.should eql [2, 3, 13, 12, 21, 31, 30, 20, 21, 12]
      end

      it "should return indices for a single contour for the two 8-connected squares spanning the length of the image" do
        @bin.narray[0..4, 4..7] = 1
        @bin.narray[5..9, 0..3] = 1
        contours = @bin.contour_indices
        contours.length.should eql 1
        contours.first.indices.should eql [5, 9, 39, 35, 44, 74, 70, 40, 44, 35]
      end

      it "should return indices for a single contour for the three compact 8-connected squares" do
        @bin.narray[0..1, 0..1] = 1
        @bin.narray[2..3, 2..3] = 1
        @bin.narray[4..5, 4..5] = 1
        contours = @bin.contour_indices
        contours.length.should eql 1
        contours.first.indices.should eql [0, 1, 11, 22, 23, 33, 44, 45, 55, 54, 44, 33, 32, 22, 11, 10]
      end

      it "should return indices for a single contour for the three 8-connected squares" do
        @bin.narray = NArray.byte(10, 9)
        @bin.narray[0..2, 0..2] = 1
        @bin.narray[3..5, 3..5] = 1
        @bin.narray[6..8, 6..8] = 1
        contours = @bin.contour_indices
        contours.length.should eql 1
        contours.first.indices.should eql [0, 2, 22, 33, 35, 55, 66, 68, 88, 86, 66, 55, 53, 33, 22, 20]
      end

      it "should return indices for a single contour for the three 8-connected squares" do
        @bin.narray = NArray.byte(10, 9)
        @bin.narray[0..2, 0..2] = 1
        @bin.narray[3..5, 3..5] = 1
        @bin.narray[0..2, 6..8] = 1
        contours = @bin.contour_indices
        contours.length.should eql 1
        contours.first.indices.should eql [0, 2, 22, 33, 35, 55, 53, 62, 82, 80, 60, 62, 53, 33, 22, 20]
      end

      it "should return two sets of four corner indices of two 3x3 squares, in a two-element array (with the corners of each contour appearing in a clockwise order, the top left coordinate first, the bottom left last)" do
        @bin.narray[1..3, 1..3] = 1
        @bin.narray[5..7, 5..7] = 1
        contours = @bin.contour_indices
        contours.length.should eql 2
        contours.first.indices.should eql [11, 13, 33, 31]
        contours.last.indices.should eql [55, 57, 77, 75]
      end

      it "should return the expected 16 corner indices from a rectangle with inward dents on each side" do
        # (This tests for the proper determination of pixels contained by the contour - which are 8-connected)
        @bin.narray[1..5, 1..5] = 1
        @bin.narray[3, 1] = 0
        @bin.narray[5, 3] = 0
        @bin.narray[2..3, 5] = 0
        @bin.narray[1, 2..3] = 0
        contours = @bin.contour_indices
        contours.length.should eql 1
        contours.first.length.should eql 16
        contours.first.indices.should eql [11, 12, 23, 14, 15, 25, 34, 45, 55, 54, 43, 42, 51, 41, 32, 22]
      end

      it "should return 7 corner indices for a rectangle with a single-width, dual-pixel 'appendix' in one corner" do
        # (This tests for a non-weak stopping criterion of the contour tracing algorithm)
        @bin.narray[1..4, 1..4] = 1
        @bin.narray[5, 4] = 1
        @bin.narray[6, 3] = 1
        contours = @bin.contour_indices
        contours.length.should eql 1
        contours.first.length.should eql 7
        contours.first.indices.should eql [11, 14, 34, 45, 36, 45, 41]
      end

    end


    context "#cosines" do

      it "should return the 'cosines' attribute of the referenced Image instance" do
        @bin.cosines.should eql @image.cosines
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        bin_other = BinImage.new(@narray, @image)
        @bin.eql?(bin_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        bin_other = BinImage.new(NArray.byte(@columns, @rows).fill(1), @image)
        @bin.eql?(bin_other).should be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        bin_other = BinImage.new(@narray, @image)
        @bin.hash.should be_a Fixnum
        @bin.hash.should eql bin_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        bin_other = BinImage.new(NArray.byte(@columns, @rows).fill(1), @image)
        @bin.hash.should_not eql bin_other.hash
      end

    end


    context "#narray=()" do

      it "should raise an ArgumentError when a non-NArray is passed as an image" do
        expect {@bin.narray = Array.new}.to raise_error(ArgumentError, /image/)
      end

      it "should raise an ArgumentError when the shape of the image is not two-dimensional" do
        expect {@bin.narray = NArray.byte(6)}.to raise_error(ArgumentError, /image/)
        expect {@bin.narray = NArray.byte(4, 4, 4)}.to raise_error(ArgumentError, /image/)
      end

      it "should raise an ArgumentError when the image is not an NArray of type 'byte'" do
        expect {@bin.narray = NArray.int(@columns, @rows)}.to raise_error(ArgumentError, /image/)
      end

      it "should raise an ArgumentError when the image is a non-binary NArray (contains value other than 0 and 1)" do
        expect {@bin.narray = NArray.byte(@columns, @rows).indgen!}.to raise_error(ArgumentError, /image/)
      end

      it "should replace the image array of the 'narray' attribute with the provided image array" do
        new_arr = NArray.byte(@columns, @rows)
        new_arr[12..16] = 1
        @bin.narray = new_arr
        @bin.narray.should_not eql @narray
        @bin.narray.should eql new_arr
      end

    end


    context "#pos_slice" do

      it "should return the 'pos_slice' attribute of the referenced Image instance" do
        @bin.pos_slice.should eql @image.pos_slice
      end

    end


    context "#pos_x" do

      it "should return the 'pos_x' attribute of the referenced Image instance" do
        @bin.pos_x.should eql @image.pos_x
      end

    end


    context "#pos_y" do

      it "should return the 'pos_y' attribute of the referenced Image instance" do
        @bin.pos_y.should eql @image.pos_y
      end

    end


    context "#row_spacing" do

      it "should return the 'row_spacing' attribute of the referenced Image instance" do
        @bin.row_spacing.should eql @image.row_spacing
      end

    end


    context "#rows" do

      it "should return the number of rows in the instance 'narray' attribute" do
        @bin.rows.should eql @narray.shape[1]
      end

    end


    context "#to_bin_image" do

      it "should return itself" do
        @bin.to_bin_image.equal?(@bin).should be_true
      end

    end


    context "#to_contours" do

      it "should raise an ArgumentError when a non-Slice is passed as a 'slice' argument" do
        expect {@bin.to_contours('not-a-slice')}.to raise_error(ArgumentError, /slice/)
      end

      it "should return an empty array when called on an empty BinImage instance" do
        contours = @bin.to_contours(@slice)
        contours.class.should eql Array
        contours.length.should eql 0
      end

      it "should return a one-element Array with a Contour instance holding 4 Coordinates with the expected values" do
        image = NArray.byte(@columns, @rows)
        image[1..3, 1..3] = 1
        @bin.add(image)
        contours = @bin.to_contours(@slice)
        contours.length.should eql 1
        contour = contours.first
        contour.coordinates.length.should eql 4
        x, y, z = contour.coords
        x.should eql [-15.0, -14.0, -14.0, -15.0]
        y.should eql [-24.5, -24.5, -22.5, -22.5]
        z.should eql [99.9, 99.9, 99.9, 99.9]
      end

      it "should return an array of two contours from an image with two separate 3x3 squares" do
        image = NArray.byte(@columns, @rows)
        image[1..3, 1..3] = 1
        image[5..7, 3..5] = 1
        @bin.add(image)
        contours = @bin.to_contours(@slice)
        contours.length.should eql 2
      end

    end


    context "#to_dcm" do

      before :each do
        @dcm = DICOM::DObject.read(FILE_IMAGE)
        @narr = NArray.byte(512, 171)
        @narr[1] = 1
        @image.stubs(:dcm).returns(@dcm)
        @b = BinImage.new(@narr, @image)
      end

      it "should return a proper DObject instance with equal number of elements as that of the source DObject" do
        b_dcm = @b.to_dcm
        b_dcm.class.should eql DICOM::DObject
        b_dcm.count.should >= 42
        b_dcm.value('0010,0010').should eql @dcm.value('0010,0010')
        b_dcm['0010,0010'].parent.should eql b_dcm
      end

      it "should insert the binary image to the pixel data of the DObject" do
        b_dcm = @b.to_dcm
        b_dcm.narray.shape.should eql @narr.shape
        b_dcm.narray[1].should be >= 1
        b_dcm.narray[0].should eql 0
      end

      it "should not make any changes to the original DObject instance when creating a DObject instance from the BinImage" do
        b_dcm = @b.to_dcm
        b_dcm['0010,0010'].value = 'DUPLICATE'
        @image.dcm.value('0010,0010').should_not eql 'DUPLICATE'
        @image.dcm.narray[1].should_not eql 1
      end

    end


    context "#to_slice" do

      it "should raise an ArgumentError when a non-ROI is passed as a 'roi' argument" do
        expect {@bin.to_slice('not-a-roi')}.to raise_error(ArgumentError, /roi/)
      end

      it "should return a Slice (which will have no contours added to it) when called on an empty BinImage instance" do
        Slice.any_instance.expects(:add_contour).never
        s = @bin.to_slice(@roi)
        s.class.should eql Slice
      end

      it "should return a Slice (with one Contour added to it)" do
        image = NArray.byte(@columns, @rows)
        image[1..3, 1..3] = 1
        @bin.add(image)
        s = @bin.to_slice(@roi)
        s.class.should eql Slice
        s.contours.length.should eql 1
        s.contours.first.class.should eql Contour
      end

      it "should return a Slice (with two Contour instances added to it)" do
        image = NArray.byte(@columns, @rows)
        image[1..3, 1..3] = 1
        image[5..7, 3..5] = 1
        @bin.add(image)
        s = @bin.to_slice(@roi)
        s.class.should eql Slice
        s.contours.length.should eql 2
        s.contours.last.class.should eql Contour
      end

    end


    context "#write" do

      it "should write a DICOM object to the specified path" do
        dcm = DICOM::DObject.read(FILE_IMAGE)
        narr = NArray.byte(512, 171)
        @image.stubs(:dcm).returns(dcm)
        b = BinImage.new(narr, @image)
        File.exists?(TMPDIR + 'bin_image.dcm').should be_false
        b.write(TMPDIR + 'bin_image.dcm')
        File.exists?(TMPDIR + 'bin_image.dcm').should be_true
      end

    end

  end

end
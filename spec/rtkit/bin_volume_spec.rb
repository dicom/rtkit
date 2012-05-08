# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe BinVolume do

    before :each do
      @sop1 = '1.245.123'
      @sop2 = '1.245.789'
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.345.789', 'CT', @f, @st)
      @ss = StructureSet.new('1.765.12', @is)
      @roi = ROI.new("Brain", 1, @f, @ss)
      @i1 = Image.new(@sop1, @is)
      @i2 = Image.new(@sop2, @is)
      @i1.cosines = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0]
      @i2.cosines = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0]
      @i1.col_spacing = 0.5
      @i2.col_spacing = 0.5
      @i1.row_spacing = 1.0
      @i2.row_spacing = 1.0
      @i1.pos_slice = 99.9
      @i2.pos_slice = 55.5
      @i1.pos_x = -15.5
      @i2.pos_x = -15.5
      @i1.pos_y = -25.5
      @i2.pos_y = -25.5
      @columns = 10
      @rows = 8
      @n1 = NArray.byte(@columns, @rows)
      @n1[1..3] = 1
      @n2 = NArray.byte(@columns, @rows)
      @n2[21..23] = 1
      @b1 = BinImage.new(@n1, @i1)
      @b2 = BinImage.new(@n2, @i2)
      @bin_images = Array.new
      @bin_images << @b1
      @bin_images << @b2
      @bv = BinVolume.new(@is, :images => @bin_images, :source => @roi)
    end

    context "::new" do

      it "should raise an ArgumentError when a non-image-series is passed as a 'series' argument" do
        expect {BinVolume.new('not-an-image-series')}.to raise_error(ArgumentError, /series/)
      end

      it "should raise an ArgumentError when a non-Array is passed as a 'images' option" do
        expect {BinVolume.new(@is, :images => 'not-an-array')}.to raise_error(ArgumentError, /images/)
      end

      it "should raise an ArgumentError when an invalid 'source' option is passed" do
        expect {BinVolume.new(@is, :source => 'not-a-roi')}.to raise_error(ArgumentError, /source/)
      end

      it "should raise an ArgumentError when the 'images' option contains one or more elements which are not BinImage instances" do
        expect {BinVolume.new(@is, :images => [@i1, 'not-an-image', @i2])}.to raise_error(ArgumentError, /images/)
      end

      it "should pass the 'series' argument to the 'series' attribute" do
        @bv.series.should eql @is
      end

      it "should pass the 'images' option to the 'images' attribute" do
        @bv.bin_images.should eql @bin_images
      end

      it "should pass the 'source' option to the 'source' attribute" do
        @bv.source.should eql @roi
      end

      it "should by default set the 'images' attribute to an empty array" do
        bv = BinVolume.new(@is)
        bv.bin_images.should eql Array.new
      end

      it "should by default set the 'source' attribute to nil" do
        bv = BinVolume.new(@is)
        bv.source.should be_nil
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        bv_other = BinVolume.new(@is, :images => @bin_images, :source => @roi)
        (@bv == bv_other).should be_true
      end

      it "should be false when comparing two instances having different attributes" do
        bv_other = BinVolume.new(@is)
        (@bv == bv_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@bv == 42).should be_false
      end

    end


    context "#add" do

      it "should raise an ArgumentError when a non-BinImage is passed" do
        expect {@bv.add('not-a-BinImage')}.to raise_error(ArgumentError, /bin_image/)
      end

      it "should add the BinImage instance to the empty BinVolume" do
        bv = BinVolume.new(@is)
        bv.add(@b1)
        bv.bin_images.should eql [@b1]
      end

      it "should add the BinImage to the BinVolume instance which already has one BinImage" do
        bv = BinVolume.new(@is, :images => [@b1])
        bv.add(@b2)
        bv.bin_images.should eql [@b1, @b2]
      end

    end


    context "#columns" do

      it "should return the number of columns in the images of the volume" do
        @bv.columns.should eql @columns
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        bv_other = BinVolume.new(@is, :images => @bin_images, :source => @roi)
        @bv.eql?(bv_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        bv_other = BinVolume.new(@is)
        @bv.eql?(bv_other).should be_false
      end

    end


    context "#frames" do

      it "should return the number of frames in the image series" do
        @bv.frames.should eql 2
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        bv_other = BinVolume.new(@is, :images => @bin_images, :source => @roi)
        @bv.hash.should be_a Fixnum
        @bv.hash.should eql bv_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        bv_other = BinVolume.new(@is)
        @bv.hash.should_not eql bv_other.hash
      end

    end


    context "#narray" do

      it "should return nil when there are no BinImage instance belonging to the BinVolume" do
        bv = BinVolume.new(@is)
        bv.narray.should be_nil
      end

      it "should return a three-dimensional byte NArray which matches the dimensions of the referenced BinImages" do
        vol_arr = @bv.narray
        vol_arr.element_size.should eql 1
        vol_arr.shape.should eql [2, @columns, @rows]
      end

      it "should return a 3d NArray where the order of the BinImage slices corresponds to the 'slice_pos' attribute of the referenced Images (when the order of the given BinImages already corresponds to the slice position order)" do
        bv = BinVolume.new(@is, :images => [@b2, @b1])
        vol_arr = @bv.narray
        @b2.pos_slice.should < @b1.pos_slice # just making sure that the slice position relationship is as expected
        (vol_arr[0, true, true].eq @b2.narray).where.length.should eql @b2.narray.length
        (vol_arr[1, true, true].eq @b1.narray).where.length.should eql @b1.narray.length
      end

      it "should return a 3d NArray where the order of the BinImage slices corresponds to the 'slice_pos' attribute of the referenced Images (when the order of the given BinImages do not correspond to the slice position order)" do
        bv = BinVolume.new(@is, :images => [@b1, @b2])
        vol_arr = @bv.narray
        @b2.pos_slice.should < @b1.pos_slice # just making sure that the slice position relationship is as expected
        (vol_arr[0, true, true].eq @b2.narray).where.length.should eql @b2.narray.length
        (vol_arr[1, true, true].eq @b1.narray).where.length.should eql @b1.narray.length
      end

    end


    context "#rows" do

      it "should return the number of rows in the images of the volume" do
        @bv.rows.should eql @rows
      end

    end


    context "#to_bin_volume" do

      it "should return itself" do
        @bv.to_bin_volume.equal?(@bv).should be_true
      end

    end


    context "#to_roi" do

      before :each do
        @is = ImageSeries.new('1.987.3', 'CT', @f, @st)
      end

      it "should raise an ArgumentError when a non-StructureSet is passed as the 'struct' argument" do
        expect {@bv.to_roi('not-a-struct')}.to raise_error(ArgumentError, /struct/)
      end

      it "should return a ROI with the expected default attribute values, containing two slices" do
        dcm = DICOM::DObject.read(FILE_STRUCT)
        struct = StructureSet.load(dcm, @st)
        roi = @bv.to_roi(struct)
        roi.algorithm.should eql 'Automatic'
        roi.name.should eql 'BinVolume'
        roi.number.should eql struct.rois.length
        roi.interpreter.should eql 'RTKIT'
        roi.type.should eql 'CONTROL'
        roi.slices.length.should eql 2
      end

      it "should return a ROI where the attributes are set by the specified optional values" do
        dcm = DICOM::DObject.read(FILE_STRUCT)
        struct = StructureSet.load(dcm, @st)
        algorithm = 'test-alg'
        name = 'Custom'
        number = 99
        interpreter = 'HUMAN'
        type = 'EXTERNAL'
        roi = @bv.to_roi(struct, :algorithm => algorithm, :name => name, :number => number, :interpreter => interpreter, :type => type)
        roi.algorithm.should eql algorithm
        roi.name.should eql name
        roi.number.should eql number
        roi.interpreter.should eql interpreter
        roi.type.should eql type
      end

    end


  end

end
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
      @i1 = SliceImage.new(@sop1, 99.9, @is)
      @i2 = SliceImage.new(@sop2, 55.5, @is)
      @i1.cosines = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0]
      @i2.cosines = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0]
      @i1.col_spacing = 0.5
      @i2.col_spacing = 0.5
      @i1.row_spacing = 1.0
      @i2.row_spacing = 1.0
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
        expect(@bv.series).to eql @is
      end

      it "should pass the 'images' option to the 'images' attribute" do
        expect(@bv.bin_images).to eql @bin_images
      end

      it "should pass the 'source' option to the 'source' attribute" do
        expect(@bv.source).to eql @roi
      end

      it "should by default set the 'images' attribute to an empty array" do
        bv = BinVolume.new(@is)
        expect(bv.bin_images).to eql Array.new
      end

      it "should by default set the 'source' attribute to nil" do
        bv = BinVolume.new(@is)
        expect(bv.source).to be_nil
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        bv_other = BinVolume.new(@is, :images => @bin_images, :source => @roi)
        expect(@bv == bv_other).to be true
      end

      it "should be false when comparing two instances having different attributes" do
        bv_other = BinVolume.new(@is)
        expect(@bv == bv_other).to be false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@bv == 42).to be_falsey
      end

    end


    context "#add" do

      it "should raise an ArgumentError when a non-BinImage is passed" do
        expect {@bv.add('not-a-BinImage')}.to raise_error(ArgumentError, /bin_image/)
      end

      it "should add the BinImage instance to the empty BinVolume" do
        bv = BinVolume.new(@is)
        bv.add(@b1)
        expect(bv.bin_images).to eql [@b1]
      end

      it "should add the BinImage to the BinVolume instance which already has one BinImage" do
        bv = BinVolume.new(@is, :images => [@b1])
        bv.add(@b2)
        expect(bv.bin_images).to eql [@b1, @b2]
      end

    end


    context "#columns" do

      it "should return the number of columns in the images of the volume" do
        expect(@bv.columns).to eql @columns
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        bv_other = BinVolume.new(@is, :images => @bin_images, :source => @roi)
        expect(@bv.eql?(bv_other)).to be true
      end

      it "should be false when comparing two instances having different attribute values" do
        bv_other = BinVolume.new(@is)
        expect(@bv.eql?(bv_other)).to be false
      end

    end


    context "#frames" do

      it "should return the number of frames in the image series" do
        expect(@bv.frames).to eql 2
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        bv_other = BinVolume.new(@is, :images => @bin_images, :source => @roi)
        expect(@bv.hash).to be_a Fixnum
        expect(@bv.hash).to eql bv_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        bv_other = BinVolume.new(@is)
        expect(@bv.hash).not_to eql bv_other.hash
      end

    end


    context "#narray" do

      it "should return nil when there are no BinImage instance belonging to the BinVolume" do
        bv = BinVolume.new(@is)
        expect(bv.narray).to be_nil
      end

      it "should return a three-dimensional byte NArray which matches the dimensions of the referenced BinImages" do
        vol_arr = @bv.narray
        expect(vol_arr.element_size).to eql 1
        expect(vol_arr.shape).to eql [2, @columns, @rows]
      end

      it "should return a 3d NArray where the order of the BinImage slices corresponds to the 'slice_pos' attribute of the referenced Images (when the order of the given BinImages already corresponds to the slice position order)" do
        bv = BinVolume.new(@is, :images => [@b2, @b1])
        vol_arr = @bv.narray
        expect(@b2.pos_slice).to be < @b1.pos_slice # just making sure that the slice position relationship is as expected
        expect((vol_arr[0, true, true].eq @b2.narray).where.length).to eql @b2.narray.length
        expect((vol_arr[1, true, true].eq @b1.narray).where.length).to eql @b1.narray.length
      end

      it "should return a 3d NArray where the order of the BinImage slices corresponds to the 'slice_pos' attribute of the referenced Images (when the order of the given BinImages do not correspond to the slice position order)" do
        bv = BinVolume.new(@is, :images => [@b1, @b2])
        vol_arr = @bv.narray
        expect(@b2.pos_slice).to be < @b1.pos_slice # just making sure that the slice position relationship is as expected
        expect((vol_arr[0, true, true].eq @b2.narray).where.length).to eql @b2.narray.length
        expect((vol_arr[1, true, true].eq @b1.narray).where.length).to eql @b1.narray.length
      end

    end


    context "#rows" do

      it "should return the number of rows in the images of the volume" do
        expect(@bv.rows).to eql @rows
      end

    end


    context "#to_bin_volume" do

      it "should return itself" do
        expect(@bv.to_bin_volume.equal?(@bv)).to be true
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
        expect(roi.algorithm).to eql 'Automatic'
        expect(roi.name).to eql 'BinVolume'
        expect(roi.number).to eql struct.structures.length
        expect(roi.interpreter).to eql 'RTKIT'
        expect(roi.type).to eql 'CONTROL'
        expect(roi.slices.length).to eql 2
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
        expect(roi.algorithm).to eql algorithm
        expect(roi.name).to eql name
        expect(roi.number).to eql number
        expect(roi.interpreter).to eql interpreter
        expect(roi.type).to eql type
      end

    end


  end

end
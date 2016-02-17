# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe Slice do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.345.789', 'CT', @f, @st)
      @ss = StructureSet.new('1.765.12', @is)
      @roi = ROI.new("Brain", 1, @f, @ss)
      @sop = '1.245.123'
      @s = Slice.new(@sop, @roi)
    end

    # FIXME: As of now we don't have a test for the case of multiple contour items for the same slice.
    context "::create_from_items" do

      before :each do
        dcm = DICOM::DObject.read(FILE_STRUCT)
        @item = dcm['3006,0039'][0]['3006,0040'][0]
        @sop = @item['3006,0016'][0].value('0008,1155')
        @items = Array.new(1, @item)
      end

      it "should raise an ArgumentError when a non-String is passed as the 'sop_uid' argument" do
        expect {Slice.create_from_items(42, @items, @roi)}.to raise_error(ArgumentError, /sop_uid/)
      end

      it "should raise an ArgumentError when a non-Array is passed as the 'contour_items' argument" do
        expect {Slice.create_from_items(@sop, 42, @roi)}.to raise_error(ArgumentError, /contour_items/)
      end

      it "should raise an ArgumentError when a non-ROI is passed as the 'roi' argument" do
        expect {Slice.create_from_items(@sop, @items, 'not-a-roi')}.to raise_error(ArgumentError, /roi/)
      end

      it "should fill the 'contours' array attribute with a Contour created from the (single element) 'contour_items' argument" do
        s = Slice.create_from_items(@sop, @items, @roi)
        expect(s.contours.length).to eql 1
        expect(s.contours.first.class).to eql Contour
      end

      it "should set the Slice's 'uid' attribute equal to the 'sop_uid' argument" do
        s = Slice.create_from_items(@sop, @items, @roi)
        expect(s.uid).to eql @sop
      end

      it "should set the Slice's 'roi' attribute equal to the 'roi' argument" do
        s = Slice.create_from_items(@sop, @items, @roi)
        expect(s.roi).to eql @roi
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-String is passed as a 'sop_uid' argument" do
        expect {Slice.new(42, @roi)}.to raise_error(ArgumentError, /sop_uid/)
      end

      it "should raise an ArgumentError when a non-ROI is passed as a 'roi' argument" do
        expect {Slice.new(@sop, 'not-a-roi')}.to raise_error(ArgumentError, /roi/)
      end

      it "should pass the 'sop_uid' argument to the 'uid' attribute" do
        s = Slice.new(@sop, @roi)
        expect(s.uid).to eql @sop
      end

      it "should pass the 'roi' argument to the 'roi' attribute" do
        s = Slice.new(@sop, @roi)
        expect(s.roi).to eql @roi
      end

      it "should by default set the 'contours' attribute to an empty array" do
        s = Slice.new(@sop, @roi)
        expect(s.contours).to eql Array.new
      end

      it "should by default set the 'image' attribute as nil (when the referenced image does not exist)" do
        s = Slice.new(@sop, @roi)
        expect(s.image).to be_nil
      end

      it "should add the Slice instance (once) to the referenced ROI" do
        s = Slice.new(@sop, @roi)
        expect(@roi.slices.length).to eql 1
        expect(@roi.slice(s.uid)).to eql s
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        s_other = Slice.new(@sop, @roi)
        expect(@s == s_other).to be_true
      end

      it "should be false when comparing two instances having different attributes" do
        s_other = Slice.new('1.2.99', @roi)
        expect(@s == s_other).to be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@s == 42).to be_false
      end

    end


    context "#add_contour" do

      it "should raise an ArgumentError when a non-Contour is passed as the 'contour' argument" do
        expect {@s.add_contour('not-a-contour')}.to raise_error(ArgumentError, /contour/)
      end

      it "should add the Contour to the empty Slice instance" do
        c = Contour.new(@s)
        expect(@s.contours.size).to eql 1
        expect(@s.contours.first).to eql c
      end

      it "should add the Contour to the Slice instance already containing a Contour" do
        s_other = Slice.new(@sop, @roi)
        c1 = Contour.new(@s)
        c2 = Contour.new(s_other, :type => "Custom")
        @s.add_contour(c2)
        expect(@s.contours.size).to eql 2
        expect(@s.contours.first).to eql c1
        expect(@s.contours.last).to eql c2
      end

      it "should not add multiple entries of the same Contour" do
        c = Contour.new(@s)
        @s.add_contour(c)
        expect(@s.contours.size).to eql 1
        expect(@s.contours.first).to eql c
      end

    end


    # The bevaviour of bin_image should probably be changed so that it fills in the image instead of just filling in the contour.
    context "#bin_image" do

      it "should raise an error when this method is called on a Slice, and its referenced Image instance (Sop UID) is missing from the dataset" do
        s = Slice.new(@sop, @roi)
        expect {s.bin_image}.to raise_error(RuntimeError, /Image/)
      end

      it "should return a BinImage instance, containing a 2d NArray binary byte segmented image, defined by the contours of the Slice" do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        img_series = d.patient.study.iseries
        roi = img_series.struct.structure('External')
        segmented_image = roi.slices.first.bin_image
        expect(segmented_image.class).to eql BinImage
        expect(segmented_image.narray.shape).to eql [512, 171]
      end

      # This example isn't very principal...
      it "should create a BinImage containing two separate filled squares, as defined by the two Contour's of the Slice" do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        img_series = d.patient.study.iseries
        roi = img_series.struct.structure('External')
        s = roi.slices.first
        c = Contour.create_from_coordinates([-20.2, -10.3, -10.3, -20.2], [-19.9, -19.9, -10.5, -10.5], [150.0, 150.0, 150.0, 150.0], s)
        expect(s.contours.length).to eql 2
        bin = s.bin_image
        # FIXME: This is an indirect test. Better would be to check the ones and zeros of the actual binary image array.
        contours = bin.to_contours(s)
        expect(contours.length).to eql 2
        x1, y1, z1 = contours.first.coords
        x2, y2, z2 = contours.last.coords
        expect(x1).to eql [-20.2, -10.3, -10.3, -20.2]
        expect(y1).to eql [-19.9, -19.9, -10.5, -10.5]
        expect(z1).to eql [150.0, 150.0, 150.0, 150.0]
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        s_other = Slice.new(@sop, @roi)
        expect(@s.eql?(s_other)).to be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        s_other = Slice.new('1.2.99', @roi)
        expect(@s.eql?(s_other)).to be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        s_other = Slice.new(@sop, @roi)
        expect(@s.hash).to be_a Fixnum
        expect(@s.hash).to eql s_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        s_other = Slice.new('1.2.99', @roi)
        expect(@s.hash).not_to eql s_other.hash
      end

    end


    context "#to_slice" do

      it "should return itself" do
        expect(@s.to_slice.equal?(@s)).to be_true
      end

    end


    context "#translate" do

      it "should call the translate method on all contours belonging to the slice, with the given offsets" do
        c1 = Contour.new(@s, :number => 1)
        c2 = Contour.new(@s, :number => 2)
        x_offset = -5
        y_offset = 10.4
        z_offset = -99.0
        c1.expects(:translate).with(x_offset, y_offset, z_offset)
        c2.expects(:translate).with(x_offset, y_offset, z_offset)
        @s.translate(x_offset, y_offset, z_offset)
      end

    end

  end

end
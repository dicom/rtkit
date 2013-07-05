# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe Image do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @s = CRSeries.new('1.345.789', @st)
      @uid = '1.234.876'
      @im = Image.new(@uid, @s)
    end

    describe "::load" do

      before :each do
        @dcm = DICOM::DObject.read(FILE_CR)
      end

      it "should raise an ArgumentError when a non-DObject is passed as the 'dcm' argument" do
        expect {Image.load(42, @s)}.to raise_error(ArgumentError, /'dcm'/)
      end

      it "should raise an ArgumentError when an non-Series is passed as the 'series' argument" do
        expect {Image.load(@dcm, 'not-a-series')}.to raise_error(ArgumentError, /series/)
      end

      it "should raise an ArgumentError when a DObject with a non-image type modality is passed with the 'dcm' argument" do
        expect {Image.load(DICOM::DObject.read(FILE_STRUCT), @s)}.to raise_error(ArgumentError, /'dcm'/)
      end

      it "should create an Image instance with attributes taken from the DICOM Object" do
        im = Image.load(@dcm, @s)
        im.uid.should eql @dcm.value('0008,0018')
        im.date.should eql @dcm.value('0008,0012')
        im.time.should eql @dcm.value('0008,0013')
        im.columns.should eql @dcm.value('0028,0011')
        im.rows.should eql @dcm.value('0028,0010')
        spacing = @dcm.value('0028,0030').split("\\").collect {|val| val.to_f}
        im.col_spacing.should eql spacing[1]
        im.row_spacing.should eql spacing[0]
      end

      it "should create an Image instance which is properly referenced to its series" do
        im = Image.load(@dcm, @s)
        im.series.should eql @s
      end

      it "should pass the 'dcm' argument to the 'dcm' attribute" do
        im = Image.load(@dcm, @s)
        im.dcm.should eql @dcm
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-string is passed as the 'sop_uid' argument" do
        expect {Image.new(42, @s)}.to raise_error(ArgumentError, /'sop_uid'/)
      end

      it "should raise an ArgumentError when a non-Series is passed as the 'series' argument" do
        expect {Image.new(@uid, 'not-a-series')}.to raise_error(ArgumentError, /'series'/)
      end

      it "should raise an ArgumentError when a non-CRSeries is passed as the 'series' argument" do
        expect {Image.new(@uid, ImageSeries.new('1.7891', 'MR', Frame.new('1.654.3', @p), @st))}.to raise_error(ArgumentError, /'series'/)
      end

      it "should by default set the 'date' attribute as an nil" do
        @im.date.should be_nil
      end

      it "should by default set the 'columns' attribute as an nil" do
        @im.columns.should be_nil
      end

      it "should by default set the 'rows' attribute as an nil" do
        @im.rows.should be_nil
      end

      it "should by default set the 'dcm' attribute as an nil" do
        @im.dcm.should be_nil
      end

      it "should by default set the 'pos_x' attribute as an nil" do
        @im.pos_x.should be_nil
      end

      it "should by default set the 'pos_y' attribute as an nil" do
        @im.pos_y.should be_nil
      end

      it "should by default set the 'col_spacing' attribute as an nil" do
        @im.col_spacing.should be_nil
      end

      it "should by default set the 'row_spacing' attribute as an nil" do
        @im.row_spacing.should be_nil
      end

      it "should by default set the 'time' attribute as an nil" do
        @im.time.should be_nil
      end

      it "should pass the 'uid' argument to the 'uid' attribute" do
        @im.uid.should eql @uid
      end

      it "should pass the 'series' argument to the 'series' attribute" do
        @im.series.should eql @s
      end

      it "should add the Image instance (once) to the referenced CRSeries" do
        @im.series.images.length.should eql 1
        @im.series.image(@im.uid).should eql @im
      end

    end


    context "#to_dcm" do

      it "should return a DICOM object (when called on an image instance created from scratch, i.e. non-dicom source)" do
        dcm = @im.to_dcm
        dcm.should be_a DICOM::DObject
      end

      it "should add series level attributes" do
        @im.series.expects(:add_attributes_to_dcm)
        dcm = @im.to_dcm
      end

      it "should create a DICOM object containing the attributes of the image instance" do
        @im.columns = 10
        @im.rows = 15
        @im.narray = NArray.int(10, 15).indgen!
        @im.row_spacing = 1.0
        @im.col_spacing = 2.0
        dcm = @im.to_dcm
        dcm.value('0008,0012').should eql @im.date
        dcm.value('0008,0013').should eql @im.time
        dcm.value('0008,0018').should eql @im.uid
        dcm.value('0028,0011').should eql @im.columns
        dcm.value('0028,0010').should eql @im.rows
        dcm.value('0028,0030').should eql [@im.row_spacing, @im.col_spacing].join("\\")
        dcm.narray.should eql @im.narray
      end

    end


    context "#to_image" do

      it "should return itself" do
        @im.to_image.equal?(@im).should be_true
      end

    end

  end

end
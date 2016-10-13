# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe Frame do

    before :each do
      @indicator = 'Cross'
      @uid = '1.234.5'
      @ds = DataSet.new
      @p = Patient.new('John', '666666', @ds)
      @f = Frame.new(@uid, @p)
      @st = Study.new('1.456.789', @p)
      @is = ImageSeries.new('1.345.789', 'CT', @f, @st)
      @img = SliceImage.new('1.234.876', 5.0, @is)
    end

    context "::new" do

      it "should raise an ArgumentError when a non-string is passed as the 'uid' argument" do
        expect {Frame.new(42, @p)}.to raise_error(ArgumentError, /'uid'/)
      end

      it "should raise an ArgumentError when a non-Patient is passed as the 'patient' argument" do
        expect {Frame.new(@uid, 'not-a-patient')}.to raise_error(ArgumentError, /'patient'/)
      end

      it "should by default set the 'image_series' attribute as an empty array" do
        f = Frame.new(@uid, @p)
        expect(f.image_series).to eql Array.new
      end

      it "should by default set the 'rois' attribute as an empty array" do
        expect(@f.structures).to eql Array.new
      end

      it "should by default set the 'indicator' attribute as nil" do
        expect(@f.indicator).to be_nil
      end

      it "should pass the 'uid' argument to the 'uid' attribute" do
        expect(@f.uid).to eql @uid
      end

      it "should pass the 'patient' argument to the 'patient' attribute" do
        expect(@f.patient).to eql @p
      end

      it "should pass the optional 'indicator' argument to the 'indicator' attribute" do
        f = Frame.new(@uid, @p, :indicator => @indicator)
        expect(f.indicator).to eql @indicator
      end

      it "should add the Frame instance (once) to the referenced Patient" do
        expect(@f.patient.frames.length).to eql 1
        expect(@f.patient.frame(@f.uid)).to eql @f
      end

      it "should add the Frame instance (once) to the DataSet which is referenced through the Patient reference" do
        expect(@f.patient.dataset.frames.length).to eql 1
        expect(@f.patient.dataset.frame(@f.uid)).to eql @f
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        f = Frame.new(@uid, @p)
        f_other = Frame.new(@uid, @p)
        expect(f == f_other).to be true
      end

      it "should be false when comparing two instances having different attributes" do
        f_other = Frame.new('1.2.99', @p)
        expect(@f == f_other).to be false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@f == 42).to be_falsey
      end

    end


    context "#add" do

      it "should raise an ArgumentError when a non-ImageSeries is passed as the 'series' argument" do
        expect {@f.add_series('not-an-image-series')}.to raise_error(ArgumentError, /series/)
      end

      it "should add the ImageSeries to the series-less Frame instance" do
        f = Frame.new('1.76.888', @p)
        f.add_series(@is)
        expect(f.image_series.size).to eql 1
        expect(f.image_series.first).to eql @is
      end

      it "should add the ImageSeries to the Frame instance already containing one or more ImageSeries" do
        ds = DataSet.read(DIR_IMAGE_ONLY)
        f = ds.frame
        previous_size = f.image_series.size
        f.add_series(@is)
        expect(f.image_series.size).to eql previous_size + 1
        expect(f.image_series.last).to eql @is
      end

    end


    context "#add_image" do

      it "should raise an ArgumentError when a non-Image is passed as the 'image' argument" do
        expect {@f.add_image('not-an-image')}.to raise_error(ArgumentError, /image/)
      end

      it "should add the Image to the image-less Frame instance" do
        f = Frame.new('1.76.888', @p)
        f.add_image(@img)
        expect(f.image(@img.uid)).to eql @img
      end

      it "should add the Image to the Frame instance already containing one or more images" do
        ds = DataSet.read(DIR_IMAGE_ONLY)
        f = ds.frame
        f.add_image(@img)
        expect(f.image(@img.uid)).to eql @img
      end

    end


    context "#add_roi" do

      before :each do
        @f = Frame.new('1.76.888', @p)
        @ss = StructureSet.new('1.234', @is)
      end

      it "should raise an ArgumentError when a non-ROI is passed as the 'roi' argument" do
        expect {@f.add_structure('not-a-roi')}.to raise_error(ArgumentError, /structure/)
      end

      it "should add the ROI to the ROI-less Frame instance" do
        f = Frame.new('1.76.888', @p)
        roi = ROI.new('Brain', 10, @f, @ss)
        f.add_structure(roi)
        expect(f.structures.size).to eql 1
        expect(f.structures.first).to eql roi
      end

      it "should add the ROI to the Frame instance already containing one or more ROIs" do
        ds = DataSet.read(DIR_STRUCT_ONLY)
        f = ds.frame
        roi = ROI.new('Brain', 10, @f, @ss)
        previous_size = f.structures.size
        f.add_structure(roi)
        expect(f.structures.size).to eql previous_size + 1
        expect(f.structures.last).to eql roi
      end

      it "should not add multiple entries of the same ROI" do
        roi = ROI.new('Brain', 10, @f, @ss)
        @f.add_structure(roi)
        expect(@f.structures.size).to eql 1
        expect(@f.structures.first).to eql roi
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        f = Frame.new(@uid, @p)
        f_other = Frame.new(@uid, @p)
        expect(f.eql?(f_other)).to be true
      end

      it "should be false when comparing two instances having different attribute values" do
        f_other = Frame.new('1.2.99', @p)
        expect(@f.eql?(f_other)).to be false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        f = Frame.new(@uid, @p)
        f_other = Frame.new(@uid, @p)
        expect(f.hash).to be_a Fixnum
        expect(f.hash).to eql f_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        f_other = Frame.new('1.2.99', @p)
        expect(@f.hash).not_to eql f_other.hash
      end

    end


    context "#image" do

      before :each do
        @f = Frame.new('1.56.77', @p)
        @is = ImageSeries.new('1.345.789', 'CT', @f, @st)
        @uid1 = '1.234'
        @uid2 = '1.678'
        @i1 = SliceImage.new(@uid1, 0.0, @is)
        @i2 = SliceImage.new(@uid2, 5.0, @is)
      end

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@f.image(42)}.to raise_error(ArgumentError, /String/)
      end

      it "should raise an ArgumentError if multiple arguments are passed" do
        expect {@f.image(@uid1, @uid2)}.to raise_error(ArgumentError, /one/)
      end

      it "should return the first Image of the Frame's first ImageSeries when no arguments are used" do
        expect(@f.image).to eql @f.image_series.first.images.first
      end

      it "should return the matching Image when a UID string is supplied" do
        image = @f.image(@uid2)
        expect(image.uid).to eql @uid2
      end

    end


    context "#series" do

      before :each do
        @f = Frame.new('1.56.77', @p)
        @uid1 = '1.234'
        @uid2 = '1.678'
        @is1 = ImageSeries.new(@uid1, 'CT', @f, @st)
        @is2 = ImageSeries.new(@uid2, 'CT', @f, @st)
      end

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@f.series(42)}.to raise_error(ArgumentError, /String/)
      end

      it "should raise an ArgumentError if multiple arguments are passed" do
        expect {@f.series(@uid1, @uid2)}.to raise_error(ArgumentError, /one/)
      end

      it "should return the first ImageSeries when no arguments are used" do
        expect(@f.series).to eql @f.image_series.first
      end

      it "should return the matching ImageSeries when a UID string is supplied" do
        series = @f.series(@uid2)
        expect(series.uid).to eql @uid2
      end

    end


    context "#to_frame" do

      it "should return itself" do
        expect(@f.to_frame.equal?(@f)).to be true
      end

    end

  end

end
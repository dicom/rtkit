# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe ImageSeries do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @uid = '1.345.789'
      @modality = 'CT'
      @class_uid = '1.2.840.10008.5.1.4.1.1.2'
      @date = '20050523'
      @time = '102219'
      @description = 'Pelvis'
      @is = ImageSeries.new(@uid, @modality, @f, @st)
    end

    describe "::load" do

      before :each do
        @dcm = DICOM::DObject.read(FILE_IMAGE)
      end

      it "should raise an ArgumentError when a non-DObject is passed as the 'dcm' argument" do
        expect {ImageSeries.load(42, @st)}.to raise_error(ArgumentError, /'dcm'/)
      end

      it "should raise an ArgumentError when an non-Study is passed as the 'study' argument" do
        expect {ImageSeries.load(@dcm, 'not-a-study')}.to raise_error(ArgumentError, /study/)
      end

      it "should raise an ArgumentError when a DObject with a non-image-series type modality is passed with the 'dcm' argument" do
        expect {ImageSeries.load(DICOM::DObject.read(FILE_STRUCT), @st)}.to raise_error(ArgumentError, /'dcm'/)
      end

      it "should create an ImageSeries instance with attributes taken from the DICOM Object" do
        is = ImageSeries.load(@dcm, @st)
        expect(is.uid).to eql @dcm.value('0020,000E')
        expect(is.modality).to eql @dcm.value('0008,0060')
        expect(is.class_uid).to eql @dcm.value('0008,0016')
        expect(is.date).to eql @dcm.value('0008,0021')
        expect(is.time).to eql @dcm.value('0008,0031')
        expect(is.description).to eql @dcm.value('0008,103E')
      end

      it "should create an ImageSeries instance which is properly referenced to its study" do
        is = ImageSeries.load(@dcm, @st)
        expect(is.study).to eql @st
      end

      it "should create an ImageSeries instance which is properly referenced to an Image created from the DICOM Object" do
        is = ImageSeries.load(@dcm, @st)
        expect(is.images.length).to eql 1
        expect(is.images.first.uid).to eql @dcm.value('0008,0018')
      end

      it "should add itself (once) to the referenced Study" do
        st = Study.new('1.456.777', @p)
        is = ImageSeries.load(@dcm, st)
        expect(is.study.image_series.length).to eql 1
        expect(is.study.iseries(is.uid)).to eql is
      end

      it "should add the single image instance to itself" do
        is = ImageSeries.load(@dcm, @st)
        expect(is.images.length).to eql 1
      end

      it "should set up the CT DICOM image as a SliceImage instance" do
        is = ImageSeries.load(@dcm, @st)
        expect(is.image).to be_a SliceImage
      end

      it "should add the slice position and uid from the dicom image to the image series' slices attribute hash" do
        is = ImageSeries.load(@dcm, @st)
        expect(is.slices[is.image.uid]).to eql is.image.pos_slice
      end

      it "should add the slice position and uid from the dicom image to the image series' sop_uids attribute hash" do
        is = ImageSeries.load(@dcm, @st)
        expect(is.sop_uids[is.image.pos_slice]).to eql is.image.uid
      end

      it "should register the image's slice position such that a query by slice position yields the image instance" do
        is = ImageSeries.load(@dcm, @st)
        pos_slice = is.images.first.pos_slice
        expect(is.image(pos_slice)).to eql is.images.first
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-string is passed as the 'series_uid' argument" do
        expect {ImageSeries.new(42, @modality, @f, @st)}.to raise_error(ArgumentError, /'series_uid'/)
      end

      it "should raise an ArgumentError when a non-string is passed as the 'modality' argument" do
        expect {ImageSeries.new(@uid, 42, @f, @st)}.to raise_error(ArgumentError, /'modality'/)
      end

      it "should raise an ArgumentError when a non-Frame is passed as the 'frame' argument" do
        expect {ImageSeries.new(@uid, @modality, 'not-a-frame', @st)}.to raise_error(ArgumentError, /'frame'/)
      end

      it "should raise an ArgumentError when a non-Study is passed as the 'study' argument" do
        expect {ImageSeries.new(@uid, @modality, @f, 'not-a-study')}.to raise_error(ArgumentError, /'study'/)
      end

      it "should raise an ArgumentError when a non-image-series type modality is passed as the 'modality' argument" do
        expect {ImageSeries.new(@uid, 'RTPLAN', @f, @st)}.to raise_error(ArgumentError, /'modality'/)
      end

      it "should by default set the 'images' attribute as an empty array" do
        expect(@is.images).to eql Array.new
      end

      it "should by default set the 'structs' attribute as an empty array" do
        expect(@is.structs).to eql Array.new
      end

      it "should by default set the 'class_uid' attribute as nil" do
        expect(@is.class_uid).to be_nil
      end

      it "should by default set the 'date' attribute as nil" do
        expect(@is.date).to be_nil
      end

      it "should by default set the 'time' attribute as nil" do
        expect(@is.time).to be_nil
      end

      it "should by default set the 'description' attribute as nil" do
        expect(@is.description).to be_nil
      end

      it "should pass the 'uid' argument to the 'uid' attribute" do
        expect(@is.uid).to eql @uid
      end

      it "should pass the 'modality' argument to the 'modality' attribute" do
        expect(@is.modality).to eql @modality
      end

      it "should pass the 'study' argument to the 'study' attribute" do
        expect(@is.study).to eql @st
      end

      it "should pass the optional 'class_uid' argument to the 'class_uid' attribute" do
        is = ImageSeries.new(@uid, @modality, @f, @st, :class_uid => @class_uid)
        expect(is.class_uid).to eql @class_uid
      end

      it "should pass the optional 'date' argument to the 'date' attribute" do
        is = ImageSeries.new(@uid, @modality, @f, @st, :date => @date)
        expect(is.date).to eql @date
      end

      it "should pass the optional 'time' argument to the 'time' attribute" do
        is = ImageSeries.new(@uid, @modality, @f, @st, :time => @time)
        expect(is.time).to eql @time
      end

      it "should pass the optional 'description' argument to the 'description' attribute" do
        is = ImageSeries.new(@uid, @modality, @f, @st, :description => @description)
        expect(is.description).to eql @description
      end

      it "should add the ImageSeries instance (once) to the referenced Study" do
        expect(@is.study.image_series.length).to eql 1
        expect(@is.study.iseries(@is.uid)).to eql @is
      end

      it "should add the ImageSeries instance (once) to the referenced Frame" do
        expect(@is.frame.image_series.length).to eql 1
        expect(@is.frame.series(@is.uid)).to eql @is
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        is_other = ImageSeries.new(@uid, @modality, @f, @st)
        expect(@is == is_other).to be true
      end

      it "should be false when comparing two instances having different attributes" do
        is_other = ImageSeries.new('1.7.99', @modality, @f, @st)
        expect(@is == is_other).to be false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@is == 42).to be_falsey
      end

    end


    context "#add_image" do

      it "should raise an ArgumentError when a non-Image is passed as the 'image' argument" do
        expect {@is.add_image('not-an-image')}.to raise_error(ArgumentError, /image/)
      end

      it "should add the Image to the image-less ImageSeries instance" do
        f2 = Frame.new('1.4321', @p)
        is_other = ImageSeries.new('1.678', 'MR', f2, @st)
        image = SliceImage.new('1.234', 5.0, is_other)
        @is.add_image(image)
        expect(@is.images.size).to eql 1
        expect(@is.images.first).to eql image
      end

      it "should add the Image to the ImageSeries instance already containing one or more images" do
        ds = DataSet.read(DIR_IMAGE_ONLY)
        is = ds.patient.study.iseries
        previous_size = is.images.size
        image = SliceImage.new('1.234', 5.0, @is)
        is.add_image(image)
        expect(is.images.size).to eql previous_size + 1
        expect(is.images.last).to eql image
      end

      it "should not add multiple entries of the same Image" do
        image =SliceImage.new('1.234', 5.0, @is)
        @is.add_image(image)
        expect(@is.images.size).to eql 1
        expect(@is.images.first).to eql image
      end

      it "should register an image's slice position in such a way that it can be matched later on even though the original slice position is somewhat deviant (to address typical float inaccuracy issues)" do
        im1 = SliceImage.new('1.234', -0.0007, @is)
        im2 = SliceImage.new('1.678', 5.0037, @is)
        im3 = SliceImage.new('1.987', 9.9989, @is)
        image = @is.image(5.0)
        expect(image.uid).to eql '1.678'
      end

    end


    context "#add_struct" do

      it "should raise an ArgumentError when a non-StructureSet is passed as the 'struct' argument" do
        expect {@is.add_struct('not-a-struct')}.to raise_error(ArgumentError, /struct/)
      end

      it "should add the StructureSet to the StructureSet-less ImageSeries instance" do
        is_other = ImageSeries.new('1.678', 'MR', @f, @st)
        struct = StructureSet.new('1.234', is_other)
        @is.add_struct(struct)
        expect(@is.structs.size).to eql 1
        expect(@is.structs.first).to eql struct
      end

      it "should add the StructureSet to the ImageSeries instance already containing one or more structure sets" do
        ds = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        is = ds.patient.study.image_series.first
        previous_size = is.structs.size
        struct = StructureSet.new('1.234', @is)
        is.add_struct(struct)
        expect(is.structs.size).to eql previous_size + 1
        expect(is.structs.last).to eql struct
      end

      it "should not add multiple entries of the same StructureSet" do
        struct = StructureSet.new('1.234', @is)
        @is.add_struct(struct)
        expect(@is.structs.size).to eql 1
        expect(@is.structs.first).to eql struct
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        is_other = ImageSeries.new(@uid, @modality, @f, @st)
        expect(@is.eql?(is_other)).to be true
      end

      it "should be false when comparing two instances having different attribute values" do
        is_other = ImageSeries.new('1.7.99', @modality, @f, @st)
        expect(@is.eql?(is_other)).to be false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        is_other = ImageSeries.new(@uid, @modality, @f, @st)
        expect(@is.hash).to be_a Fixnum
        expect(@is.hash).to eql is_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        is_other = ImageSeries.new('1.7.99', @modality, @f, @st)
        expect(@is.hash).not_to eql is_other.hash
      end

    end


    context "#image" do

      before :each do
        @uid1 = '1.234'
        @im1 = SliceImage.new(@uid1, 0.0, @is)
        @uid2 = '1.678'
        @im2 = SliceImage.new(@uid2, 5.0, @is)
      end

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@is.image(42)}.to raise_error(ArgumentError, /String/)
      end

      it "should raise an ArgumentError if multiple arguments are passed" do
        expect {@is.image(@uid1, @uid2)}.to raise_error(ArgumentError, /one/)
      end

      it "should return the first Image when no arguments are used" do
        expect(@is.image).to eql @is.images.first
      end

      it "should return the matching Image when a UID string is supplied" do
        image = @is.image(@uid2)
        expect(image.uid).to eql @uid2
      end

      it "should return the matching Image when a slice position float is supplied" do
        image = @is.image(5.0)
        expect(image.pos_slice).to eql 5.0
      end

      it "should return the matching Image when a minimally deviant slice position is supplied (to address typical float inaccuracy issues)" do
        image = @is.image(5.0045)
        expect(image.pos_slice).to eql 5.0
      end

    end


    context "#image_modality?" do

      it "should return true when called on a ImageSeries (with modality CT)" do
        expect(@is.image_modality?).to be true
      end

    end


    context "#struct" do

      before :each do
        @uid1 = '1.234'
        @ss1 = StructureSet.new(@uid1, @is)
        @uid2 = '1.678'
        @ss2 = StructureSet.new(@uid2, @is)
      end

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@is.struct(42)}.to raise_error(ArgumentError, /String/)
      end

      it "should raise an ArgumentError if multiple arguments are passed" do
        expect {@is.struct(@uid1, @uid2)}.to raise_error(ArgumentError, /one/)
      end

      it "should return the first StructureSet when no arguments are used" do
        expect(@is.struct).to eql @is.structs.first
      end

      it "should return the matching StructureSet when a UID string is supplied" do
        struct = @is.struct(@uid2)
        expect(struct.uid).to eql @uid2
      end

    end


    context "#to_image_series" do

      it "should return itself" do
        expect(@is.to_image_series.equal?(@is)).to be true
      end

    end

  end

end
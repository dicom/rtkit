# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe DataSet do

    before :each do
      @ds = DataSet.new
    end

    describe "::load" do

      it "should raise an ArgumentError when a non-Array is passed as an argument" do
        expect {DataSet.load(42)}.to raise_error(ArgumentError, /objects/)
      end

      it "should raise an ArgumentError when an Array containing non-DObjects is passed as an argument" do
        non_objects = Array.new(1, 'Invalid')
        expect {DataSet.load(non_objects)}.to raise_error(ArgumentError, /objects/)
      end

      it "should properly connect a image series and a structure set when the image series is loaded first" do
        objects = Array.new
        [FILE_IMAGE, FILE_STRUCT].collect {|f| objects << DICOM::DObject.read(f)}
        ds = DataSet.load(objects)
        is = ds.patient.study.iseries
        is.class.should eql ImageSeries
        is.structs.class.should eql Array
        is.structs.first.class.should eql StructureSet
        is.structs.first.image_series.class.should eql Array
        is.structs.first.image_series.first.class.should eql ImageSeries
      end

      it "should properly connect a image series and a structure set when the structure set series is loaded first" do
        objects = Array.new
        [FILE_STRUCT, FILE_IMAGE].collect {|f| objects << DICOM::DObject.read(f)}
        ds = DataSet.load(objects)
        is = ds.patient.study.iseries
        is.class.should eql ImageSeries
        is.structs.class.should eql Array
        is.structs.first.class.should eql StructureSet
        is.structs.first.image_series.class.should eql Array
        is.structs.first.image_series.first.class.should eql ImageSeries
      end

    end


    context "::new" do

      it "should by default set the 'frames' attribute as an empty array" do
        @ds.frames.should eql Array.new
      end

      it "should by default set the 'patients' attribute as an empty array" do
        @ds.patients.should eql Array.new
      end

    end


    describe "::read" do

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {DataSet.read(42)}.to raise_error(ArgumentError, /path/)
      end

      it "should raise an ArgumentError when an empty folder is passed as an argument" do
        empty = TMPDIR + "empty/"
        FileUtils.mkdir(empty)
        expect {DataSet.read(empty)}.to raise_error(ArgumentError, /No files/)
      end

      it "should raise an ArgumentError when a folder with no DICOM files is passed as an argument" do
        nodicom = TMPDIR + "nodicom/"
        FileUtils.mkdir(nodicom)
        File.open(nodicom + "text.txt", 'w') {|f| f.write("test"*50) }
        expect {DataSet.read(nodicom)}.to raise_error(ArgumentError, /No DICOM/)
      end

      it "should successfully load a folder containing only an image" do
        ds = DataSet.read(DIR_IMAGE_ONLY)
        ds.should be_a DataSet
      end

      it "should successfully load a folder containing only a Structure Set" do
        ds = DataSet.read(DIR_STRUCT_ONLY)
        ds.should be_a DataSet
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        ds_other = DataSet.new
        (@ds == ds_other).should be_true
      end

      it "should be false when comparing two instances having different attributes" do
        ds_other = DataSet.new
        Patient.new('John', '12345', ds_other)
        (@ds == ds_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@ds == 42).should be_false
      end

    end


    context "#add_frame" do

      it "should raise an ArgumentError when a non-Frame is passed as the 'frame' argument" do
        expect {@ds.add_frame('not-a-frame')}.to raise_error(ArgumentError, /frame/)
      end

      it "should add the Frame to the frame-less DataSet instance" do
        p = Patient.new('John', '12345', @ds)
        frame = Frame.new('1.234', p)
        @ds.add_frame(frame)
        @ds.frames.size.should eql 1
        @ds.frames.should eql [frame]
      end

      it "should add the Frame to the DataSet instance already containing frame(s)" do
        ds = DataSet.read(DIR_IMAGE_ONLY)
        p = Patient.new('John', '12345', ds)
        previous_size = ds.frames.size
        frame = Frame.new('1.234', p)
        ds.add_frame(frame)
        ds.frames.size.should eql previous_size + 1
        ds.frames.last.should eql frame
      end

    end


    context "#add_patient" do

      it "should raise an ArgumentError when a non-Patient is passed as the 'patient' argument" do
        expect {@ds.add_patient('not-a-patient')}.to raise_error(ArgumentError, /patient/)
      end

      it "should add the Patient to the patient-less DataSet instance" do
        ds_other = DataSet.new
        pat = Patient.new('John', '12345', ds_other)
        @ds.add_patient(pat)
        @ds.patients.size.should eql 1
        @ds.patient(pat.id).should eql pat
      end

      it "should add the Patient to the DataSet instance already containing patient(s)" do
        ds = DataSet.read(DIR_IMAGE_ONLY)
        previous_size = ds.patients.size
        pat = Patient.new('John', '12345', ds)
        ds.add_patient(pat)
        ds.patients.size.should eql previous_size + 1
        ds.patients.last.should eql pat
      end

      it "should not add multiple entries of the same Patient" do
        pat = Patient.new('John', '12345', @ds) # added once
        @ds.add_patient(pat) # trying to add second time
        @ds.patients.size.should eql 1
        @ds.patient(pat.id).should eql pat
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        ds_other = DataSet.new
        @ds.eql?(ds_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        ds_other = DataSet.new
        Patient.new('John', '12345', ds_other)
        @ds.eql?(ds_other).should be_false
      end

    end


    context "#frame" do

      before :each do
        @p = Patient.new('John', '12345', @ds)
        @uid1 = '1.234'
        @f1 = Frame.new(@uid1, @p)
        @uid2 = '1.678'
        @f2 = Frame.new(@uid2, @p)
      end

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@ds.frame(42)}.to raise_error(ArgumentError, /String/)
      end

      it "should raise an ArgumentError if multiple arguments are passed" do
        expect {@ds.frame(@uid1, @uid2)}.to raise_error(ArgumentError, /one/)
      end

      it "should return the first Frame when no arguments are used" do
        @ds.frame.should eql @ds.frames.first
      end

      it "should return the the matching Frame when a UID string is supplied" do
        frame = @ds.frame(@uid2)
        frame.uid.should eql @uid2
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        ds_other = DataSet.new
        @ds.hash.should be_a Fixnum
        @ds.hash.should eql ds_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        ds_other = DataSet.new
        Patient.new('John', '12345', ds_other)
        @ds.hash.should_not eql ds_other.hash
      end

    end


    context "#patient" do

      before :each do
        @id1 = '12345'
        @p1 = Patient.new('John', @id1, @ds)
        @id2 = '67890'
        @p2 = Patient.new('Jack', @id2, @ds)
      end

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@ds.patient(42)}.to raise_error(ArgumentError, /String/)
      end

      it "should raise an ArgumentError if multiple arguments are passed" do
        expect {@ds.patient(@id1, @id2)}.to raise_error(ArgumentError, /one/)
      end

      it "should return the first Patient when no arguments are used" do
        @ds.patient.should eql @ds.patients.first
      end

      it "should return the the matching Patient when an ID string is supplied" do
        patient = @ds.patient(@id2)
        patient.id.should eql @id2
      end

    end


    context "#to_data_set" do

      it "should return itself" do
        @ds.to_data_set.equal?(@ds).should be_true
      end

    end

  end

end
# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe Patient do

    before :each do
      @name = 'John'
      @id = '12345'
      @ds = DataSet.new
      @p = Patient.new(@name, @id, @ds)
      @birth_date = '20050523'
      @sex = 'M'
    end

    describe "::load" do

      before :each do
        @dcm = DICOM::DObject.read(FILE_IMAGE)
      end

      it "should raise an ArgumentError when a non-DObject is passed as the 'dcm' argument" do
        expect {Patient.load(42, @ds)}.to raise_error(ArgumentError, /'dcm'/)
      end

      it "should raise an ArgumentError when an non-DataSet is passed as the 'dataset' argument" do
        expect {Patient.load(@dcm, 'not-a-dataset')}.to raise_error(ArgumentError, /dataset/)
      end

      it "should create a Patient instance with attributes taken from the DICOM Object" do
        p = Patient.load(@dcm, @ds)
        p.name.should eql @dcm.value('0010,0010')
        p.id.should eql @dcm.value('0010,0020')
        p.birth_date.should eql @dcm.value('0010,0030')
        p.sex.should eql @dcm.value('0010,0040')
      end

      it "should create a Patient instance which is properly referenced to its dataset" do
        p = Patient.load(@dcm, @ds)
        p.dataset.should eql @ds
      end

      it "should create a Patient instance which adds itself (once) to the referenced DataSet" do
        previous_count = @ds.patients.length
        p = Patient.load(@dcm, @ds)
        @ds.patient(p.id).should eql p
        @ds.patients.length.should eql previous_count + 1
      end

      it "should create a Patient instance which is properly referenced to a Study created from the DICOM Object" do
        p = Patient.load(@dcm, @ds)
        p.studies.length.should eql 1
        p.studies.first.uid.should eql @dcm.value('0020,000D')
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-string is passed as the 'name' argument" do
        expect {Patient.new(42, @id, @ds)}.to raise_error(ArgumentError, /'name'/)
      end

      it "should raise an ArgumentError when a non-string is passed as the 'id' argument" do
        expect {Patient.new(@name, 42.0, @ds)}.to raise_error(ArgumentError, /'id'/)
      end

      it "should raise an ArgumentError when a non-DataSet is passed as the 'dataset' argument" do
        expect {Patient.new(@name, @id, 'not-a-dataset')}.to raise_error(ArgumentError, /'dataset'/)
      end

      it "should by default set the 'frames' attribute as an empty array" do
        @p.frames.should eql Array.new
      end

      it "should by default set the 'studies' attribute as an empty array" do
        @p.studies.should eql Array.new
      end

      it "should by default set the 'birth_date' attribute as nil" do
        @p.birth_date.should be_nil
      end

      it "should by default set the 'sex' attribute as nil" do
        @p.sex.should be_nil
      end

      it "should pass the 'name' argument to the 'name' attribute" do
        @p.name.should eql @name
      end

      it "should pass the 'id' argument to the 'id' attribute" do
        @p.id.should eql @id
      end

      it "should pass the 'dataset' argument to the 'dataset' attribute" do
        @p.dataset.should eql @ds
      end

      it "should pass the optional 'birth_date' argument to the 'birth_date' attribute" do
        p = Patient.new(@name, @id, @ds, :birth_date => @birth_date)
        p.birth_date.should eql @birth_date
      end

      it "should pass the optional 'sex' argument to the 'sex' attribute" do
        p = Patient.new(@name, @id, @ds, :sex => @sex)
        p.sex.should eql @sex
      end

      it "should add the Patient instance (once) to the referenced DataSet" do
        p = Patient.new(@name, @id, @ds)
        @ds.patient(p.id).should eql p
        @ds.patients.length.should eql 1
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        p_other = Patient.new(@name, @id, @ds)
        (@p == p_other).should be_true
      end

      it "should be false when comparing two instances having different attributes" do
        p_other = Patient.new("Other Patient", @id, @ds)
        (@p == p_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@p == 42).should be_false
      end

    end


    context "#add_frame" do

      it "should raise an ArgumentError when a non-Frame is passed as the 'frame' argument" do
        expect {@p.add_frame('not-a-frame')}.to raise_error(ArgumentError, /frame/)
      end

      it "should add the Frame to the frame-less Patient instance" do
        p_other = Patient.new("Jack", "54321", @ds)
        frame = Frame.new('1.234', p_other)
        @p.add_frame(frame)
        @p.frames.size.should eql 1
        @p.frames.first.should eql frame
      end

      it "should add the Frame to the Patient instance already containing one or more frame" do
        ds = DataSet.read(DIR_IMAGE_ONLY)
        p = ds.patient
        previous_size = p.studies.size
        frame = Frame.new('1.234', @p)
        p.add_frame(frame)
        p.frames.size.should eql previous_size + 1
        p.frames.last.should eql frame
      end

      it "should not add multiple entries of the same Frame" do
        f = Frame.new('1.234', @p) # added once
        @p.add_frame(f) # trying to add second time
        @p.frames.size.should eql 1
        @p.frame(f.uid).should eql f
      end

    end


    context "#add_study" do

      it "should raise an ArgumentError when a non-Study is passed as the 'study' argument" do
        expect {@p.add_study('not-a-study')}.to raise_error(ArgumentError, /study/)
      end

      it "should add the Study to the study-less Patient instance" do
        p_other = Patient.new("Jack", "54321", @ds)
        study = Study.new('1.234', p_other)
        @p.add_study(study)
        @p.studies.size.should eql 1
        @p.studies.first.should eql study
      end

      it "should add the Study to the Patient instance already containing one or more studies" do
        ds = DataSet.read(DIR_IMAGE_ONLY)
        p = ds.patient
        previous_size = p.studies.size
        study = Study.new('1.234', @p)
        p.add_study(study)
        p.studies.size.should eql previous_size + 1
        p.studies.last.should eql study
      end

      it "should not add multiple entries of the same Study" do
        study = Study.new('1.234', @p) # added once
        @p.add_study(study) # trying to add second time
        @p.studies.size.should eql 1
        @p.study(study.uid).should eql study
      end

    end


    context "#create_frame" do

      before :each do
        @uid1 = '1.234'
        @uid2 = '1.678'
        @indicator = 'cross'
      end

      it "should raise an ArgumentError when a non-String is passed as the 'uid' argument" do
        expect {@p.create_frame(42)}.to raise_error(ArgumentError, /'uid'/)
      end

      it "should raise an ArgumentError when a non-String is passed as the 'indicator' argument" do
        expect {@p.create_frame(@uid1, 42)}.to raise_error(ArgumentError, /indicator/)
      end

      it "should pass the arguments to the Frame's attributes" do
        frame = @p.create_frame(@uid1, @indicator)
        frame.uid.should eql @uid1
        frame.indicator.should eql @indicator
      end

      it "should add the Frame to the frame-less Patient instance" do
        frame = @p.create_frame(@uid1)
        @p.frames.size.should eql 1
        @p.frames.first.should eql frame
      end

      it "should add the Frame to the Patient instance already containing frame(s)" do
        ds = DataSet.read(DIR_IMAGE_ONLY)
        p = ds.patient
        previous_size = p.frames.size
        frame = p.create_frame(@uid2)
        p.frames.size.should eql previous_size + 1
        p.frames.last.should eql frame
      end

      it "should add the newly created Frame to the Patient's DataSet instance" do
        previous_size = @p.dataset.frames.size
        frame = @p.create_frame(@uid1)
        @p.dataset.frames.size.should eql previous_size + 1
        @p.dataset.frames.last.should eql frame
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        p_other = Patient.new(@name, @id, @ds)
        @p.eql?(p_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        p_other = Patient.new("Other Patient", @id, @ds)
        @p.eql?(p_other).should be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        p_other = Patient.new(@name, @id, @ds)
        @p.hash.should be_a Fixnum
        @p.hash.should eql p_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        p_other = Patient.new("Other Patient", @id, @ds)
        @p.hash.should_not eql p_other.hash
      end

    end


    context "#to_patient" do

      it "should return itself" do
        @p.to_patient.equal?(@p).should be_true
      end

    end


    context "#study" do

      before :each do
        @uid1 = '1.234'
        @s1 = Study.new(@uid1, @p)
        @uid2 = '1.678'
        @s2 = Study.new(@uid2, @p)
      end

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@p.study(42)}.to raise_error(ArgumentError, /String/)
      end

      it "should raise an ArgumentError if multiple arguments are passed" do
        expect {@p.study(@uid1, @uid2)}.to raise_error(ArgumentError, /one/)
      end

      it "should return the first Study when no arguments are used" do
        @p.study.should eql @p.studies.first
      end

      it "should return the matching Study when a UID string is supplied" do
        study = @p.study(@uid2)
        study.uid.should eql @uid2
      end

    end

  end

end
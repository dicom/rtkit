# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe Study do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @f = Frame.new('1.567.8', @p)
      @uid = '1.234.56'
      @date = '20050523'
      @time = '102219'
      @description = 'Pelvis'
      @id = '1'
      @s = Study.new(@uid, @p)
    end

    describe "::load" do

      before :each do
        @dcm = DICOM::DObject.read(FILE_IMAGE)
      end

      it "should raise an ArgumentError when a non-DObject is passed as the 'dcm' argument" do
        expect {Study.load(42, @p)}.to raise_error(ArgumentError, /'dcm'/)
      end

      it "should raise an ArgumentError when an non-Patient is passed as the 'patient' argument" do
        expect {Study.load(@dcm, 'not-a-patient')}.to raise_error(ArgumentError, /patient/)
      end

      it "should create a Study instance with attributes taken from the DICOM Object" do
        s = Study.load(@dcm, @p)
        s.uid.should eql @dcm.value('0020,000D')
        s.date.should eql @dcm.value('0008,0020')
        s.time.should eql @dcm.value('0008,0030')
        s.description.should eql @dcm.value('0008,1030')
        s.id.should eql @dcm.value('0020,0010')
      end

      it "should create a Study instance which is properly referenced to its Patient" do
        s = Study.load(@dcm, @p)
        s.patient.should eql @p
      end

      it "should create a Study instance which is properly referenced to a Series created from the DICOM Object" do
        s = Study.load(@dcm, @p)
        s.series.length.should eql 1
        s.series.first.uid.should eql @dcm.value('0020,000E')
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-string is passed as the 'study_uid' argument" do
        expect {Study.new(42, @p)}.to raise_error(ArgumentError, /'study_uid'/)
      end

      it "should raise an ArgumentError when a non-Patient is passed as the 'patient' argument" do
        expect {Study.new(@uid, 'not-a-patient')}.to raise_error(ArgumentError, /'patient'/)
      end

      it "should by default set the 'image_series' attribute as an empty array" do
        @s.image_series.should eql Array.new
      end

      it "should by default set the 'series' attribute as an empty array" do
        @s.series.should eql Array.new
      end

      it "should by default set the 'date' attribute as nil" do
        @s.date.should be_nil
      end

      it "should by default set the 'time' attribute as nil" do
        @s.time.should be_nil
      end

      it "should by default set the 'description' attribute as nil" do
        @s.description.should be_nil
      end

      it "should by default set the 'id' attribute as nil" do
        @s.id.should be_nil
      end

      it "should pass the 'uid' argument to the 'uid' attribute" do
        @s.uid.should eql @uid
      end

      it "should pass the 'patient' argument to the 'patient' attribute" do
        @s.patient.should eql @p
      end

      it "should pass the optional 'date' argument to the 'date' attribute" do
        s = Study.new(@uid, @p, :date => @date)
        s.date.should eql @date
      end

      it "should pass the optional 'time' argument to the 'time' attribute" do
        s = Study.new(@uid, @p, :time => @time)
        s.time.should eql @time
      end

      it "should pass the optional 'description' argument to the 'description' attribute" do
        s = Study.new(@uid, @p, :description => @description)
        s.description.should eql @description
      end

      it "should pass the optional 'id' argument to the 'id' attribute" do
        s = Study.new(@uid, @p, :id => @id)
        s.id.should eql @id
      end

      it "should add the Study instance (once) to the referenced Patient" do
        s = Study.new(@uid, @p)
        s.patient.studies.length.should eql 1
        s.patient.study(s.uid).should eql s
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        s_other = Study.new(@uid, @p)
        (@s == s_other).should be_true
      end

      it "should be false when comparing two instances having different attributes" do
        s_other = Study.new('1.4.99', @p)
        (@s == s_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@s == 42).should be_false
      end

    end


    context "#add_series" do

      it "should raise an ArgumentError when a non-Series is passed as the 'series' argument" do
        expect {@s.add_series('not-a-series')}.to raise_error(ArgumentError, /series/)
      end

      it "should add the ImageSeries to the series-less Study instance" do
        st_other = Study.new('1.2468', @p)
        is = ImageSeries.new('1.678', 'MR', @f, st_other)
        @s.add_series(is)
        @s.image_series.size.should eql 1
        @s.image_series.first.should eql is
      end

      it "should add the ImageSeries to the Study instance already containing one or more ImageSeries" do
        ds = DataSet.read(DIR_IMAGE_ONLY)
        s = ds.patient.study
        previous_size = s.image_series.size
        is = ImageSeries.new('1.678', 'MR', @f, @s)
        s.add_series(is)
        s.image_series.size.should eql previous_size + 1
        s.image_series.last.should eql is
      end

      it "should add (one instance of) the ImageSeries to the Study" do
        is = ImageSeries.new('1.678', 'MR', @f, @s)
        @s.add_series(is)
        @s.image_series.size.should eql 1
        @s.image_series.first.should eql is
      end

      it "should not add multiple entries of the same ImageSeries if it is attempted added more than once" do
        is = ImageSeries.new('1.678', 'MR', @f, @s)
        @s.add_series(is)
        @s.add_series(is)
        @s.image_series.size.should eql 1
        @s.image_series.first.should eql is
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        s_other = Study.new(@uid, @p)
        @s.eql?(s_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        s_other = Study.new('1.4.99', @p)
        @s.eql?(s_other).should be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        s_other = Study.new(@uid, @p)
        @s.hash.should be_a Fixnum
        @s.hash.should eql s_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        s_other = Study.new('1.4.99', @p)
        @s.hash.should_not eql s_other.hash
      end

    end


    context "#iseries" do

      before :each do
        @uid1 = '1.432'
        @se1 = ImageSeries.new(@uid1, 'CT', @f, @s)
        @uid2 = '1.678'
        @se2 = ImageSeries.new(@uid2, 'MR', @f, @s)
      end

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@s.iseries(42)}.to raise_error(ArgumentError, /String/)
      end

      it "should raise an ArgumentError if multiple arguments are passed" do
        expect {@s.iseries(@uid1, @uid2)}.to raise_error(ArgumentError, /one/)
      end

      it "should return the first ImageSeries when no arguments are used" do
        @s.iseries.should eql @s.image_series.first
      end

      it "should return the matching ImageSeries when a UID string is supplied" do
        series = @s.iseries(@uid2)
        series.uid.should eql @uid2
      end

    end


    context "#to_study" do

      it "should return itself" do
        @s.to_study.equal?(@s).should be_true
      end

    end

  end

end
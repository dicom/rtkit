# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe StructureSet do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.987.3', 'CT', @f, @st)
      @uid = '1.345.789'
      @date = '20050523'
      @time = '102219'
      @description = 'Pelvis'
      @ss = StructureSet.new(@uid, @is)
    end

    describe "::load" do

      before :each do
        @dcm = DICOM::DObject.read(FILE_STRUCT)
      end

      it "should raise an ArgumentError when a non-DObject is passed as the 'dcm' argument" do
        expect {StructureSet.load(42, @st)}.to raise_error(ArgumentError, /'dcm'/)
      end

      it "should raise an ArgumentError when an non-Study is passed as the 'study' argument" do
        expect {StructureSet.load(@dcm, 'not-a-study')}.to raise_error(ArgumentError, /study/)
      end

      it "should raise an ArgumentError when a DObject with a non-structure-set modality is passed with the 'dcm' argument" do
        expect {StructureSet.load(DICOM::DObject.read(FILE_IMAGE), @st)}.to raise_error(ArgumentError, /'dcm'/)
      end

      it "should create a StructureSet instance with attributes taken from the DICOM Object" do
        ss = StructureSet.load(@dcm, @st)
        ss.sop_uid.should eql @dcm.value('0008,0018')
        ss.series_uid.should eql @dcm.value('0020,000E')
        ss.modality.should eql @dcm.value('0008,0060')
        ss.class_uid.should eql @dcm.value('0008,0016')
        ss.date.should eql @dcm.value('0008,0021')
        ss.time.should eql @dcm.value('0008,0031')
        ss.description.should eql @dcm.value('0008,103E')
      end

      it "should create a StructureSet instance which is properly referenced to its study" do
        ss = StructureSet.load(@dcm, @st)
        ss.study.should eql @st
      end

      it "should set up an ImageSeries reference when no corresponding image slices have been loaded" do
        ss = StructureSet.load(@dcm, @st)
        ss.image_series.length.should eql 1
      end

      it "should create a StructureSet containing 2 ROIs (as defined in this DICOM object)" do
        dcm = DICOM::DObject.read(FILE_STRUCT)
        struct = StructureSet.load(dcm, @st)
        struct.rois.length.should eql 2
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-string is passed as the 'sop_uid' argument" do
        expect {StructureSet.new(42, @is)}.to raise_error(ArgumentError, /'sop_uid'/)
      end

      it "should raise an ArgumentError when a non-ImageSeries is passed as the 'image_series' argument" do
        expect {StructureSet.new(@uid, 'not-a-series')}.to raise_error(ArgumentError, /'image_series'/)
      end

      it "should by default set the 'rois' attribute as an empty array" do
        @ss.rois.should eql Array.new
      end

      it "should by default set the 'plans' attribute as an empty array" do
        @ss.plans.should eql Array.new
      end

      it "should by default set the 'modality' attribute equal as 'RTSTRUCT'" do
        @ss.modality.should eql 'RTSTRUCT'
      end

      it "should by default set the 'class_uid' attribute equal to the RT Structure Set Storage Class UID" do
        @ss.class_uid.should eql '1.2.840.10008.5.1.4.1.1.481.3'
      end

      it "should by default set the 'date' attribute as nil" do
        @ss.date.should be_nil
      end

      it "should by default set the 'time' attribute as nil" do
        @ss.time.should be_nil
      end

      it "should by default set the 'description' attribute as nil" do
        @ss.description.should be_nil
      end

      it "should pass the 'uid' argument to the 'uid' attribute" do
        @ss.uid.should eql @uid
      end

      it "should pass the 'image_series' argument to the 'image_series' attribute" do
        @ss.image_series.length.should eql 1
        @ss.image_series.include?(@is).should be_true
      end

      it "should pass the optional 'date' argument to the 'date' attribute" do
        ss = StructureSet.new(@uid, @is, :date => @date)
        ss.date.should eql @date
      end

      it "should pass the optional 'time' argument to the 'time' attribute" do
        ss = StructureSet.new(@uid, @is, :time => @time)
        ss.time.should eql @time
      end

      it "should pass the optional 'description' argument to the 'description' attribute" do
        ss = StructureSet.new(@uid, @is, :description => @description)
        ss.description.should eql @description
      end

      it "should pass the ImageSeries' study  to the 'study' attribute" do
        @ss.study.should eql @is.study
      end

      it "should add the StructureSet instance (once) to the referenced ImageSeries" do
        @ss.image_series.first.structs.length.should eql 1
        @ss.image_series.first.struct(@ss.uid).should eql @ss
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        ss_other = StructureSet.new(@uid, @is)
        (@ss == ss_other).should be_true
      end

      it "should be false when comparing two instances having different attributes" do
        ss_other = StructureSet.new('1.8.99', @is)
        (@ss == ss_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@ss == 42).should be_false
      end

    end


    context "#add_plan" do

      it "should raise an ArgumentError when a non-Plan is passed as the 'plan' argument" do
        expect {@ss.add_plan('not-a-plan')}.to raise_error(ArgumentError, /'plan'/)
      end

      it "should add the Plan to the plan-less StructureSet instance" do
        ss_other = StructureSet.new('1.23.787', @is)
        plan = Plan.new('1.45.876', ss_other)
        @ss.add_plan(plan)
        @ss.plans.size.should eql 1
        @ss.plans.first.should eql plan
      end

      it "should add the Plan to the StructureSet instance already containing one or more plans" do
        ds = DataSet.read(DIR_PLAN_ONLY)
        ss = ds.patient.study.iseries.struct
        previous_size = ss.plans.size
        plan = Plan.new('1.45.876', @ss)
        ss.add_plan(plan)
        ss.plans.size.should eql previous_size + 1
        ss.plans.last.should eql plan
      end

      it "should not add multiple entries of the same Plan" do
        plan = Plan.new('1.45.876', @ss)
        @ss.add_plan(plan)
        @ss.plans.size.should eql 1
        @ss.plans.first.should eql plan
      end

    end


    context "#add_roi" do

      it "should raise an ArgumentError when a non-ROI is passed as the 'roi' argument" do
        expect {@ss.add_roi('not-a-roi')}.to raise_error(ArgumentError, /'roi'/)
      end

      it "should add the ROI to the roi-less StructureSet instance" do
        ss_other = StructureSet.new("1.23.787", @is)
        roi = ROI.new('Brain', 10, @f, ss_other)
        @ss.add_roi(roi)
        @ss.rois.size.should eql 1
        @ss.rois.first.should eql roi
      end

      it "should add the ROI to the StructureSet instance already containing one or more rois" do
        ds = DataSet.read(DIR_STRUCT_ONLY)
        ss = ds.patient.study.iseries.struct
        previous_size = ss.rois.size
        roi = ROI.new('Brain', 10, @f, @ss)
        ss.add_roi(roi)
        ss.rois.size.should eql previous_size + 1
        ss.rois.last.should eql roi
      end

      it "should not add multiple entries of the same ROI" do
        roi = ROI.new('Brain', 10, @f, @ss)
        @ss.add_roi(roi)
        @ss.rois.size.should eql 1
        @ss.rois.first.should eql roi
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        ss_other = StructureSet.new(@uid, @is)
        @ss.eql?(ss_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        ss_other = StructureSet.new('1.8.99', @is)
        @ss.eql?(ss_other).should be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        ss_other = StructureSet.new(@uid, @is)
        @ss.hash.should be_a Fixnum
        @ss.hash.should eql ss_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        ss_other = StructureSet.new('1.8.99', @is)
        @ss.hash.should_not eql ss_other.hash
      end

    end


    context "#plan" do

      before :each do
        @uid1 = '1.23.787'
        @uid2 = '1.45.876'
        @plan1 = Plan.new(@uid1, @ss)
        @plan2 = Plan.new(@uid2, @ss)
      end

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@ss.plan(42)}.to raise_error(ArgumentError, /String/)
      end

      it "should raise an ArgumentError if multiple arguments are passed" do
        expect {@ss.plan(@uid1, @uid2)}.to raise_error(ArgumentError, /one/)
      end

      it "should return the first Plan when no arguments are used" do
        @ss.plan.should eql @ss.plans.first
      end

      it "should return the matching Plan when a UID string is supplied" do
        plan = @ss.plan(@uid2)
        plan.uid.should eql @uid2
      end

    end


    context "#roi" do

      before :each do
        @name1 = 'External'
        @name2 = 'Brain'
        @number1 = 1
        @number2 = 2
        @roi1 = ROI.new(@name1, @number1, @f, @ss)
        @roi2 = ROI.new(@name2, @number2, @f, @ss)
      end

      it "should raise an ArgumentError when the argument is neither a String nor Integer" do
        expect {@ss.roi(42.0)}.to raise_error(ArgumentError, /String/)
      end

      it "should raise an ArgumentError if no arguments are passed" do
        expect {@ss.roi}.to raise_error(ArgumentError, /wrong number/)
      end

      it "should return the matching ROI when queried by it's name" do
        roi = @ss.roi(@name2)
        roi.name.should eql @name2
      end

      it "should return the matching ROI when queried by it's number" do
        roi = @ss.roi(@number2)
        roi.number.should eql @number2
      end

    end


    context "#to_structure_set" do

      it "should return itself" do
        @ss.to_structure_set.equal?(@ss).should be_true
      end

    end

  end

end
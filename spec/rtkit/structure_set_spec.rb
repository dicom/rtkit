# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe StructureSet do

    before :all do
      RTKIT.logger.level = Logger::ERROR
    end

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
        expect(ss.sop_uid).to eql @dcm.value('0008,0018')
        expect(ss.series_uid).to eql @dcm.value('0020,000E')
        expect(ss.modality).to eql @dcm.value('0008,0060')
        expect(ss.class_uid).to eql @dcm.value('0008,0016')
        expect(ss.date).to eql @dcm.value('0008,0021')
        expect(ss.time).to eql @dcm.value('0008,0031')
        expect(ss.description).to eql @dcm.value('0008,103E')
      end

      it "should create a StructureSet instance which is properly referenced to its study" do
        ss = StructureSet.load(@dcm, @st)
        expect(ss.study).to eql @st
      end

      it "should set up an ImageSeries reference when no corresponding image slices have been loaded" do
        ss = StructureSet.load(@dcm, @st)
        expect(ss.image_series.length).to eql 1
      end

      it "should identify and set up an ImageSeries reference when the first referenced frame doesn't contain a proper study/series/instance hierarchy (with no corresponding image slices having been loaded)" do
        # Set up a Structure Set DICOM object to use:
        dcm = DICOM::DObject.new
        dcm.add_element(SOP_UID, RTKIT.sop_uid)
        dcm.add_element(MODALITY, 'RTSTRUCT')
        s = dcm.add_sequence(REF_FRAME_OF_REF_SQ)
        i = s.add_item
        i.add_element(FRAME_OF_REF, RTKIT.frame_uid)
        i = s.add_item
        i.add_element(FRAME_OF_REF, RTKIT.frame_uid)
        s = i.add_sequence(RT_REF_STUDY_SQ)
        i = s.add_item
        i.add_element(REF_SOP_CLASS_UID, '1.2.840.10008.3.1.2.3.2')
        i.add_element(REF_SOP_UID, RTKIT.study_uid)
        s = i.add_sequence(RT_REF_SERIES_SQ)
        i = s.add_item
        i.add_element(SERIES_UID, RTKIT.series_uid)
        s = i.add_sequence(CONTOUR_IMAGE_SQ)
        sop_uids = RTKIT.sop_uids(2)
        i = s.add_item
        i.add_element(REF_SOP_CLASS_UID, '1.2.840.10008.5.1.4.1.1.2')
        i.add_element(REF_SOP_UID, sop_uids.first)
        i = s.add_item
        i.add_element(REF_SOP_CLASS_UID, '1.2.840.10008.5.1.4.1.1.2')
        i.add_element(REF_SOP_UID, sop_uids.last)
        # Execute test:
        ss = StructureSet.load(dcm, @st)
        expect(ss.image_series.length).to eql 1
      end

      it "should create a StructureSet containing 4 structures (2 ROIs, 2 POIs) (as defined in this DICOM object)" do
        dcm = DICOM::DObject.read(FILE_STRUCT)
        struct = StructureSet.load(dcm, @st)
        expect(struct.structures.length).to eql 4
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-string is passed as the 'sop_uid' argument" do
        expect {StructureSet.new(42, @is)}.to raise_error(ArgumentError, /'sop_uid'/)
      end

      it "should raise an ArgumentError when a non-ImageSeries is passed as the 'image_series' argument" do
        expect {StructureSet.new(@uid, 'not-a-series')}.to raise_error(ArgumentError, /'image_series'/)
      end

      it "should by default set the 'structures' attribute as an empty array" do
        expect(@ss.structures).to eql Array.new
      end

      it "should by default set the 'plans' attribute as an empty array" do
        expect(@ss.plans).to eql Array.new
      end

      it "should by default set the 'modality' attribute equal as 'RTSTRUCT'" do
        expect(@ss.modality).to eql 'RTSTRUCT'
      end

      it "should by default set the 'class_uid' attribute equal to the RT Structure Set Storage Class UID" do
        expect(@ss.class_uid).to eql '1.2.840.10008.5.1.4.1.1.481.3'
      end

      it "should by default set the 'date' attribute as nil" do
        expect(@ss.date).to be_nil
      end

      it "should by default set the 'time' attribute as nil" do
        expect(@ss.time).to be_nil
      end

      it "should by default set the 'description' attribute as nil" do
        expect(@ss.description).to be_nil
      end

      it "should pass the 'uid' argument to the 'uid' attribute" do
        expect(@ss.uid).to eql @uid
      end

      it "should pass the 'image_series' argument to the 'image_series' attribute" do
        expect(@ss.image_series.length).to eql 1
        expect(@ss.image_series.include?(@is)).to be true
      end

      it "should pass the optional 'date' argument to the 'date' attribute" do
        ss = StructureSet.new(@uid, @is, :date => @date)
        expect(ss.date).to eql @date
      end

      it "should pass the optional 'time' argument to the 'time' attribute" do
        ss = StructureSet.new(@uid, @is, :time => @time)
        expect(ss.time).to eql @time
      end

      it "should pass the optional 'description' argument to the 'description' attribute" do
        ss = StructureSet.new(@uid, @is, :description => @description)
        expect(ss.description).to eql @description
      end

      it "should pass the ImageSeries' study  to the 'study' attribute" do
        expect(@ss.study).to eql @is.study
      end

      it "should add the StructureSet instance (once) to the referenced ImageSeries" do
        expect(@ss.image_series.first.structs.length).to eql 1
        expect(@ss.image_series.first.struct(@ss.uid)).to eql @ss
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        ss_other = StructureSet.new(@uid, @is)
        expect(@ss == ss_other).to be true
      end

      it "should be false when comparing two instances having different attributes" do
        ss_other = StructureSet.new('1.8.99', @is)
        expect(@ss == ss_other).to be false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@ss == 42).to be_falsey
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
        expect(@ss.plans.size).to eql 1
        expect(@ss.plans.first).to eql plan
      end

      it "should add the Plan to the StructureSet instance already containing one or more plans" do
        ds = DataSet.read(DIR_PLAN_ONLY)
        ss = ds.patient.study.iseries.struct
        previous_size = ss.plans.size
        plan = Plan.new('1.45.876', @ss)
        ss.add_plan(plan)
        expect(ss.plans.size).to eql previous_size + 1
        expect(ss.plans.last).to eql plan
      end

      it "should not add multiple entries of the same Plan" do
        plan = Plan.new('1.45.876', @ss)
        @ss.add_plan(plan)
        expect(@ss.plans.size).to eql 1
        expect(@ss.plans.first).to eql plan
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
        expect(@ss.structures.size).to eql 1
        expect(@ss.structures.first).to eql roi
      end

      it "should add the ROI to the StructureSet instance already containing one or more rois" do
        ds = DataSet.read(DIR_STRUCT_ONLY)
        ss = ds.patient.study.iseries.struct
        previous_size = ss.structures.size
        roi = ROI.new('Brain', 10, @f, @ss)
        ss.add_roi(roi)
        expect(ss.structures.size).to eql previous_size + 1
        expect(ss.structures.last).to eql roi
      end

      it "should not add multiple entries of the same ROI" do
        roi = ROI.new('Brain', 10, @f, @ss)
        @ss.add_roi(roi)
        expect(@ss.structures.size).to eql 1
        expect(@ss.structures.first).to eql roi
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        ss_other = StructureSet.new(@uid, @is)
        expect(@ss.eql?(ss_other)).to be true
      end

      it "should be false when comparing two instances having different attribute values" do
        ss_other = StructureSet.new('1.8.99', @is)
        expect(@ss.eql?(ss_other)).to be false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        ss_other = StructureSet.new(@uid, @is)
        expect(@ss.hash).to be_a Fixnum
        expect(@ss.hash).to eql ss_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        ss_other = StructureSet.new('1.8.99', @is)
        expect(@ss.hash).not_to eql ss_other.hash
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
        expect(@ss.plan).to eql @ss.plans.first
      end

      it "should return the matching Plan when a UID string is supplied" do
        plan = @ss.plan(@uid2)
        expect(plan.uid).to eql @uid2
      end

    end


    context "#pois" do

      it "should give an array of POI structures associated to the structure set" do
        @roi = ROI.new('CTV', 1, @f, @ss)
        @poi1 = POI.new('REF', 2, @f, @ss)
        @poi2 = POI.new('ISO', 3, @f, @ss)
        expect(@ss.pois.length).to eql 2
        expect(@ss.pois).to eql [@poi1, @poi2]
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
        expect {@ss.structure(42.0)}.to raise_error(ArgumentError, /String/)
      end

      it "should raise an ArgumentError if no arguments are passed" do
        expect {@ss.structure}.to raise_error(ArgumentError, /wrong number/)
      end

      it "should return the matching ROI when queried by it's name" do
        roi = @ss.structure(@name2)
        expect(roi.name).to eql @name2
      end

      it "should return the matching ROI when queried by its number" do
        roi = @ss.structure(@number2)
        expect(roi.number).to eql @number2
      end

    end


    context "#rois" do

      it "should give an array of ROI structures associated to the structure set" do
        @roi1 = ROI.new('CTV', 1, @f, @ss)
        @poi = POI.new('REF', 2, @f, @ss)
        @roi2 = ROI.new('PTV', 3, @f, @ss)
        expect(@ss.rois.length).to eql 2
        expect(@ss.rois).to eql [@roi1, @roi2]
      end

    end


    context "#structures" do

      it "should give an array of structures associated to the structure set" do
        @roi = ROI.new('CTV', 1, @f, @ss)
        @poi = POI.new('REF', 2, @f, @ss)
        expect(@ss.structures.length).to eql 2
        expect(@ss.structures).to eql [@roi, @poi]
      end

    end


    context "#to_structure_set" do

      it "should return itself" do
        expect(@ss.to_structure_set.equal?(@ss)).to be true
      end

    end

  end

end
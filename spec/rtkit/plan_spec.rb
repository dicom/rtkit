# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe Plan do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.987.3', 'CT', @f, @st)
      @ss = StructureSet.new('1.765.354', @is)
      @uid = '1.345.789'
      @date = '20050523'
      @time = '102219'
      @description = '5-field'
      @label = 'Boost'
      @name = 'Prost:70-78:2'
      @plan_description = 'IMRT'
      @plan = Plan.new(@uid, @ss)
    end

    describe "::load" do

      before :each do
        @dcm = DICOM::DObject.read(FILE_PLAN)
      end

      it "should raise an ArgumentError when a non-DObject is passed as the 'dcm' argument" do
        expect {Plan.load(42, @st)}.to raise_error(ArgumentError, /'dcm'/)
      end

      it "should raise an ArgumentError when an non-Study is passed as the 'study' argument" do
        expect {Plan.load(@dcm, 'not-a-study')}.to raise_error(ArgumentError, /study/)
      end

      it "should raise an ArgumentError when a DObject with a non-plan modality is passed with the 'dcm' argument" do
        expect {Plan.load(DICOM::DObject.read(FILE_IMAGE), @st)}.to raise_error(ArgumentError, /'dcm'/)
      end

      it "should create a Plan instance with attributes taken from the DICOM Object" do
        plan = Plan.load(@dcm, @st)
        expect(plan.sop_uid).to eql @dcm.value('0008,0018')
        expect(plan.series_uid).to eql @dcm.value('0020,000E')
        expect(plan.modality).to eql @dcm.value('0008,0060')
        expect(plan.class_uid).to eql @dcm.value('0008,0016')
        expect(plan.date).to eql @dcm.value('0008,0021')
        expect(plan.time).to eql @dcm.value('0008,0031')
        expect(plan.description).to eql @dcm.value('0008,103E')
        expect(plan.label).to eql @dcm.value('300A,0002')
        expect(plan.name).to eql @dcm.value('300A,0003')
        expect(plan.plan_description).to eql @dcm.value('300A,0004')
      end

      it "should create a Plan instance which is properly referenced to its study" do
        plan = Plan.load(@dcm, @st)
        expect(plan.study).to eql @st
      end

      it "should create and reference a Setup instance based on the Patient Setup Sequence Item" do
        plan = Plan.load(@dcm, @st)
        expect(plan.setup.class).to eql Setup
      end

      it "should set up a StructureSet reference when no corresponding StructureSet have been loaded" do
        plan = Plan.load(@dcm, @st)
        expect(plan.struct).to be_a StructureSet
      end

=begin
      it "should create a Plan containing 2 Beams (as defined in this DICOM object)" do
        plan = Plan.load(@dcm, @st)
        plan.beams.length.should eql 2
      end
=end

      it "should create a Plan instance when given a Brachy DICOM RTPlan" do
        # Note: Brachy support is rudimentary: No beams/control points are created,
        # we only get a simple Plan instance with some basic attributes.
        dcm = DICOM::DObject.read(FILE_BRACHY_PLAN)
        plan = Plan.load(dcm, @st)
        expect(plan.sop_uid).to eql dcm.value('0008,0018')
        expect(plan.series_uid).to eql dcm.value('0020,000E')
        expect(plan.modality).to eql dcm.value('0008,0060')
        expect(plan.class_uid).to eql dcm.value('0008,0016')
        expect(plan.date).to eql dcm.value('0008,0021')
        expect(plan.time).to eql dcm.value('0008,0031')
        expect(plan.description).to eql dcm.value('0008,103E')
        expect(plan.label).to eql dcm.value('300A,0002')
        expect(plan.name).to eql dcm.value('300A,0003')
        expect(plan.plan_description).to eql dcm.value('300A,0004')
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-string is passed as the 'sop_uid' argument" do
        expect {Plan.new(42, @ss)}.to raise_error(ArgumentError, /'sop_uid'/)
      end

      it "should raise an ArgumentError when a non-StructureSet is passed as the 'struct' argument" do
        expect {Plan.new(@uid, 'not-a-struct')}.to raise_error(ArgumentError, /'struct'/)
      end

      it "should by default set the 'beams' attribute as an empty array" do
        expect(@plan.beams).to eql Array.new
      end

      it "should by default set the 'doses' attribute as an empty array" do
        expect(@plan.rt_doses).to eql Array.new
      end

      it "should by default set the 'modality' attribute equal as 'RTPLAN'" do
        expect(@plan.modality).to eql 'RTPLAN'
      end

      it "should by default set the 'class_uid' attribute equal to the RT Plan Storage Class UID" do
        expect(@plan.class_uid).to eql '1.2.840.10008.5.1.4.1.1.481.5'
      end

      it "should by default set the 'date' attribute as nil" do
        expect(@plan.date).to be_nil
      end

      it "should by default set the 'time' attribute as nil" do
        expect(@plan.time).to be_nil
      end

      it "should by default set the 'description' attribute as nil" do
        expect(@plan.description).to be_nil
      end

      it "should by default set the 'label' attribute as nil" do
        expect(@plan.label).to be_nil
      end

      it "should by default set the 'name' attribute as nil" do
        expect(@plan.name).to be_nil
      end

      it "should by default set the 'plan_description' attribute as nil" do
        expect(@plan.plan_description).to be_nil
      end

      it "should pass the 'sop_uid' argument to the 'sop_uid' attribute" do
        expect(@plan.sop_uid).to eql @uid
      end


      it "should pass the 'struct' argument to the 'struct' attribute" do
        expect(@plan.struct).to eql @ss
      end

      it "should pass the optional 'date' argument to the 'date' attribute" do
        plan = Plan.new(@uid, @ss, :date => @date)
        expect(plan.date).to eql @date
      end

      it "should pass the optional 'time' argument to the 'time' attribute" do
        plan = Plan.new(@uid, @ss, :time => @time)
        expect(plan.time).to eql @time
      end

      it "should pass the optional 'description' argument to the 'description' attribute" do
        plan = Plan.new(@uid, @ss, :description => @description)
        expect(plan.description).to eql @description
      end

      it "should pass the optional 'label' argument to the 'label' attribute" do
        plan = Plan.new(@uid, @ss, :label => @label)
        expect(plan.label).to eql @label
      end

      it "should pass the optional 'name' argument to the 'name' attribute" do
        plan = Plan.new(@uid, @ss, :name => @name)
        expect(plan.name).to eql @name
      end

      it "should pass the optional 'plan_description' argument to the 'plan_description' attribute" do
        plan = Plan.new(@uid, @ss, :plan_description => @plan_description)
        expect(plan.plan_description).to eql @plan_description
      end

      it "should add the Plan instance (once) to the referenced StructureSet" do
        expect(@plan.struct.plans.length).to eql 1
        expect(@plan.struct.plans.first).to eql @plan
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        plan_other = Plan.new(@uid, @ss)
        expect(@plan == plan_other).to be_true
      end

      it "should be false when comparing two instances having different attributes" do
        plan_other = Plan.new('1.5.99', @ss)
        expect(@plan == plan_other).to be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@plan == 42).to be_false
      end

    end


    context "#add_rt_dose" do

      it "should raise an ArgumentError when a non-RTDose is passed as the 'rt_dose' argument" do
        expect {@plan.add_rt_dose('not-a-rtdose')}.to raise_error(ArgumentError, /'rt_dose'/)
      end

      it "should add the RTDose to the dose-less Plan instance" do
        plan_other = Plan.new('1.23.787', @ss)
        dose = RTDose.new('1.45.876', plan_other)
        @plan.add_rt_dose(dose)
        expect(@plan.rt_doses.size).to eql 1
        expect(@plan.rt_doses.first).to eql dose
      end

      it "should add the RTDose to the Plan instance already containing one or more dose series" do
        ds = DataSet.read(DIR_DOSE_ONLY)
        plan = ds.patient.study.iseries.struct.plan
        previous_size = plan.rt_doses.size
        dose = RTDose.new('1.45.876', @plan)
        plan.add_rt_dose(dose)
        expect(plan.rt_doses.size).to eql previous_size + 1
        expect(plan.rt_doses.last).to eql dose
      end

      it "should not add multiple entries of the same RTDose" do
        dose = RTDose.new('1.45.876', @plan)
        @plan.add_rt_dose(dose)
        expect(@plan.rt_doses.size).to eql 1
        expect(@plan.rt_doses.first).to eql dose
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        plan_other = Plan.new(@uid, @ss)
        expect(@plan.eql?(plan_other)).to be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        plan_other = Plan.new('1.5.99', @ss)
        expect(@plan.eql?(plan_other)).to be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        plan_other = Plan.new(@uid, @ss)
        expect(@plan.hash).to be_a Fixnum
        expect(@plan.hash).to eql plan_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        plan_other = Plan.new('1.5.99', @ss)
        expect(@plan.hash).not_to eql plan_other.hash
      end

    end


    context "#rt_dose" do

      before :each do
        @uid1 = '1.23.787'
        @uid2 = '1.45.876'
        @dose1 = RTDose.new(@uid1, @plan)
        @dose2 = RTDose.new(@uid2, @plan)
      end

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@plan.rt_dose(42)}.to raise_error(ArgumentError, /String/)
      end

      it "should raise an ArgumentError if multiple arguments are passed" do
        expect {@plan.rt_dose(@uid1, @uid2)}.to raise_error(ArgumentError, /one/)
      end

      it "should return the first RTDose when no arguments are used" do
        expect(@plan.rt_dose).to eql @plan.rt_doses.first
      end

      it "should return the matching RTDose when a UID string is supplied" do
        dose = @plan.rt_dose(@uid2)
        expect(dose.uid).to eql @uid2
      end

    end


    context "#to_plan" do

      it "should return itself" do
        expect(@plan.to_plan.equal?(@plan)).to be_true
      end

    end

  end

end
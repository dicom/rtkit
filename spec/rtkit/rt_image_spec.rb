# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe RTImage do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.987.3', 'CT', @f, @st)
      @ss = StructureSet.new('1.765.354', @is)
      @plan = Plan.new('1.456.654', @ss)
      @uid = '1.345.789'
      @date = '20050523'
      @time = '102219'
      @description = 'MC'
      @rt = RTImage.new(@uid, @plan)
    end

    describe "::load" do

      before :each do
        @dcm = DICOM::DObject.read(FILE_RTIMAGE)
      end

      it "should raise an ArgumentError when a non-DObject is passed as the 'dcm' argument" do
        expect {RTImage.load(42, @st)}.to raise_error(ArgumentError, /'dcm'/)
      end

      it "should raise an ArgumentError when an non-Study is passed as the 'study' argument" do
        expect {RTImage.load(@dcm, 'not-a-study')}.to raise_error(ArgumentError, /study/)
      end

      it "should raise an ArgumentError when a DObject with a non-plan modality is passed with the 'dcm' argument" do
        expect {RTImage.load(DICOM::DObject.read(FILE_IMAGE), @st)}.to raise_error(ArgumentError, /'dcm'/)
      end

      it "should create an RTImage instance with attributes taken from the DICOM Object" do
        rt = RTImage.load(@dcm, @st)
        expect(rt.series_uid).to eql @dcm.value('0020,000E')
        expect(rt.modality).to eql @dcm.value('0008,0060')
        expect(rt.class_uid).to eql @dcm.value('0008,0016')
        expect(rt.date).to eql @dcm.value('0008,0021')
        expect(rt.time).to eql @dcm.value('0008,0031')
        expect(rt.description).to eql @dcm.value('0008,103E')
      end

      it "should set up the DICOM RTIMAGE object as a ProjectionImage instance belonging to the RTImage series" do
        rt = RTImage.load(@dcm, @st)
        expect(rt.images.first).to be_a ProjectionImage
      end

      it "should create an RTImage instance which is properly referenced to its study" do
        rt = RTImage.load(@dcm, @st)
        expect(rt.study).to eql @st
      end

      it "should set up a Plan reference when no corresponding Plan have been loaded" do
        rt = RTImage.load(@dcm, @st)
        expect(rt.plan).to be_a Plan
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-string is passed as the 'series_uid' argument" do
        expect {RTImage.new(42, @plan)}.to raise_error(ArgumentError, /'series_uid'/)
      end

      it "should raise an ArgumentError when a non-Plan is passed as the 'plan' argument" do
        expect {RTImage.new(@uid, 'not-a-plan')}.to raise_error(ArgumentError, /'plan'/)
      end

      it "should by default set the 'images' attribute as an empty array" do
        expect(@rt.images).to eql Array.new
      end

      it "should by default set the 'modality' attribute equal as 'RTIMAGE'" do
        expect(@rt.modality).to eql 'RTIMAGE'
      end

      it "should by default set the 'class_uid' attribute equal to the RT Image Storage Class UID" do
        expect(@rt.class_uid).to eql '1.2.840.10008.5.1.4.1.1.481.1'
      end

      it "should by default set the 'date' attribute as nil" do
        expect(@rt.date).to be_nil
      end

      it "should by default set the 'time' attribute as nil" do
        expect(@rt.time).to be_nil
      end

      it "should by default set the 'description' attribute as nil" do
        expect(@rt.description).to be_nil
      end

      it "should pass the 'series_uid' argument to the 'series_uid' attribute" do
        expect(@rt.series_uid).to eql @uid
      end

      it "should pass the 'plan' argument to the 'plan' attribute" do
        expect(@rt.plan).to eql @plan
      end

      it "should pass the optional 'date' argument to the 'date' attribute" do
        rt = RTImage.new(@uid, @plan, :date => @date)
        expect(rt.date).to eql @date
      end

      it "should pass the optional 'time' argument to the 'time' attribute" do
        rt = RTImage.new(@uid, @plan, :time => @time)
        expect(rt.time).to eql @time
      end

      it "should pass the optional 'description' argument to the 'description' attribute" do
        rt = RTImage.new(@uid, @plan, :description => @description)
        expect(rt.description).to eql @description
      end

      it "should add the RTImage instance (once) to the referenced Plan" do
        expect(@rt.plan.rt_images.length).to eql 1
        expect(@rt.plan.rt_images.first).to eql @rt
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        rt_other = RTImage.new(@uid, @plan)
        expect(@rt == rt_other).to be true
      end

      it "should be false when comparing two instances having different attributes" do
        rt_other = RTImage.new('1.6.99', @plan)
        expect(@rt == rt_other).to be false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@rt == 42).to be_falsey
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        rt_other = RTImage.new(@uid, @plan)
        expect(@rt.eql?(rt_other)).to be true
      end

      it "should be false when comparing two instances having different attribute values" do
        rt_other = RTImage.new('1.6.99', @plan)
        expect(@rt.eql?(rt_other)).to be false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        rt_other = RTImage.new(@uid, @plan)
        expect(@rt.hash).to be_a Fixnum
        expect(@rt.hash).to eql rt_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        rt_other = RTImage.new('1.6.99', @plan)
        expect(@rt.hash).not_to eql rt_other.hash
      end

    end


    context "#to_rt_image" do

      it "should return itself" do
        expect(@rt.to_rt_image.equal?(@rt)).to be true
      end

    end

  end

end
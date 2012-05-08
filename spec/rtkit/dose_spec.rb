# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe Dose do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.987.3', 'CT', @f, @st)
      @ss = StructureSet.new('1.765.354', @is)
      @plan = Plan.new('1.456.654', @ss)
      @rt_dose = RTDose.new('1.987.55', @plan)
      @uid = '1.345.789'
      @dvol = DoseVolume.new(@uid, @f, @rt_dose)
      @doses = [6.0, 1.0, 1.0, 3.0, 6.0]
      @mean = 3.4
      @median = 3.0
      @min = 1.0
      @max = 6.0
      @stddev_rounded = 2.510
      @rmsdev_rounded = 2.245
      @dist = DoseDistribution.new(@doses, @dvol)
      @value = 1.8
      @dose = Dose.new(@value, @dist)
    end

    context "::new" do

      it "should raise an error when a non-Float-compatible argument is passed as the value" do
        expect {Dose.new(@ds, @distribution)}.to raise_error
      end

      it "should raise an ArgumentError when a non-DoseDistribution is passed as the 'distribution' argument" do
        expect {Dose.new(@value, 'not-a-distribution')}.to raise_error(ArgumentError, /'distribution'/)
      end

      it "should register the float value" do
        @dose.to_f.should eql @value
      end

      it "should pass the 'distribution' argument to the 'distribution' attribute" do
        @dose.distribution.should eql @dist
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        dose_other = Dose.new(@value, @dist)
        (@dose == dose_other).should be_true
      end

      it "should be false when comparing two instances having different attributes (different dose, same distribution)" do
        dose_other = Dose.new(99.99, @dist)
        (@dose == dose_other).should be_false
      end

      it "should be false when comparing two instances having different attributes (same dose, different distribution)" do
        dose_other = Dose.new(@value, DoseDistribution.new([1.3, 8.8, 5.5], @dvol))
        (@dose == dose_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@dose == 42.0).should be_false
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        dose_other = Dose.new(@value, @dist)
        @dose.eql?(dose_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        dose_other = Dose.new(99.99, @dist)
        @dose.eql?(dose_other).should be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        dose_other = Dose.new(@value, @dist)
        @dose.hash.should be_a Fixnum
        @dose.hash.should eql dose_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        dose_other = Dose.new(99.99, @dist)
        @dose.hash.should_not eql dose_other.hash
      end

    end


    context "#to_dose" do

      it "should return itself" do
        @dose.to_dose.equal?(@dose).should be_true
      end

    end

  end

end
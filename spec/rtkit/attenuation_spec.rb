# encoding: UTF-8

require 'spec_helper'


module RTKIT

  describe Attenuation do

    before :each do
      @energy = 0.1
      @a = Attenuation.new(@energy)
    end

    context "::new" do

      it "should raise an ArgumentError when a non-Float is passed as 'energy' argument" do
        expect {Attenuation.new('energy')}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a negative float is passed as 'energy' argument" do
        expect {Attenuation.new(-0.05)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a zero float value is passed as 'energy' argument" do
        expect {Attenuation.new(0.0)}.to raise_error(ArgumentError)
      end

      it "should pass the 'energy' argument to the 'energy' attribute" do
        @a.energy.should eql @energy
      end

      it "should set a mass attenuation coefficient that we expect for the given energy value" do
        @a.ac_water.should eql 0.1707
      end

      it "should use 0.05 (keV) as a default value for the energy attribute if none is given" do
        a = Attenuation.new
        a.energy.should eql 0.05
      end

      it "should set a mass attenuation coefficient that we expect for the default energy value" do
        a = Attenuation.new
        a.ac_water.should eql 0.2269
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        a_other = Attenuation.new(@energy)
        (@a == a_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        a_other = Attenuation.new(1.23)
        (@a == a_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@a == 42).should be_false
      end

    end


    context "#ac_water=()" do

      it "should raise an error when a non-Float compatible type is passed as argument" do
        expect {@a.ac_water = ['42.0']}.to raise_error
      end

      it "should pass the coeff argument to the 'ac_water' attribute" do
        value = 0.0765
        @a.ac_water = value
        @a.ac_water.should eql value
      end

    end


    context "#attenuation" do

      it "should give the expected attenuation fraction for these input values" do
        att = @a.attenuation(hu=-1000, length=100.0)
        att.should eql 0.0
      end

      it "should give the expected attenuation fraction for these input values" do
        att = @a.attenuation(hu=0, length=10.0)
        att.round(4).should eql (1 - 0.8431).round(4)
      end

      it "should give the expected attenuation fraction for these input values" do
        att = @a.attenuation(hu=3000, length=10.0)
        att.round(4).should eql 1 - 0.5052
      end

    end


    context "#attenuation_coefficient" do

      it "should give the expected attenuation coefficient for this hounsfield unit" do
        coeff = @a.attenuation_coefficient(hu=-1000)
        coeff.should eql 0.0
      end

      it "should give the expected attenuation coefficient for this hounsfield unit" do
        coeff = @a.attenuation_coefficient(hu=0)
        coeff.should eql 0.1707
      end

      it "should give the expected attenuation coefficient for this hounsfield unit" do
        coeff = @a.attenuation_coefficient(hu=3000)
        coeff.should eql 0.6828
      end

    end


    context "#attenuation_coefficients" do

      it "should give the expected attenuation coefficients for these hounsfield units" do
        coeff = @a.attenuation_coefficients(NArray[3000, 0, -1000])
        coeff.should eql NArray[0.6828, 0.1707, 0.0]#.to_type(NArray::FLOAT)
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        a_other = Attenuation.new(@energy)
        @a.eql?(a_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        a_other = Attenuation.new(0.78)
        @a.eql?(a_other).should be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        a_other = Attenuation.new(@energy)
        @a.hash.should be_a Fixnum
        @a.hash.should eql a_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        a_other = Attenuation.new(2.45)
        @a.hash.should_not eql a_other.hash
      end

    end


    context "#to_attenuation" do

      it "should return itself" do
        @a.to_attenuation.equal?(@a).should be_true
      end

    end


    context "#vector_attenuation" do

      it "should give the expected attenuation for this collection of hounsfield units and lengths" do
        att = @a.vector_attenuation(NArray[3000, 0, -1000], NArray[10.0, 10.0, 100.0])
        att.round(4).should eql 1 - 0.4259
      end

    end

  end

end
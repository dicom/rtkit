# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe DoseDistribution do

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
    end

    context "::new" do

      it "should raise an ArgumentError when a non-array is passed as the 'doses' argument" do
        expect {DoseDistribution.new(42, @dvol)}.to raise_error
      end

      it "should raise an ArgumentError when a non-DoseVolume is passed as the 'volume' argument" do
        expect {DoseDistribution.new(@doses, 'not-a-dose-volume')}.to raise_error(ArgumentError, /'volume'/)
      end

      it "should pass the 'doses' argument to the 'doses' attribute" do
        @dist.doses.to_a.should eql @doses.sort
      end

      it "should pass the 'volume' argument to the 'volume' attribute" do
        @dist.volume.should eql @dvol
      end

      it "should pass the convert a 'doses' Array argument to an NArray (with type float single) when storing the 'doses' attribute" do
        @dist.doses.class.should eql NArray
        @dist.doses.typecode.should eql 4 # float single is 4, float double is 5
        (@dist.doses == NArray.to_na(@doses.sort)).should be_true
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        dist_other = DoseDistribution.new(@doses, @dvol)
        (@dist == dist_other).should be_true
      end

      it "should be false when comparing two instances having different attributes" do
        dist_other = DoseDistribution.new([99.9], @dvol)
        (@dist == dist_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@dist == 42).should be_false
      end

    end


    context "#d" do

      it "should raise a RangeError when a negative percentage argument is given" do
        expect {@dist.d(-5)}.to raise_error(RangeError)
      end

      it "should raise a RangeError when a 100+ percentage argument is given" do
        expect {@dist.d(100.4)}.to raise_error(RangeError)
      end

      it "should return the populated dose for a perfectly uniform dose distribution" do
        doses = NArray.float(100).fill(2.0)
        dist = DoseDistribution.new(doses, @dvol)
        dist.d(100).should eql 2.0
        dist.d(98).should eql 2.0
        dist.d(2).should eql 2.0
        dist.d(0).should eql 2.0
      end

      it "should return the expected dose which a given percentage of the distribution has a higher or equal dose than" do
        doses = NArray.float(100).indgen
        dist = DoseDistribution.new(doses, @dvol)
        dist.d(100).should eql 0.0
        dist.d(98).should eql 2.0
        dist.d(2).should eql 97.0
        dist.d(0).should eql 99.0
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        dist_other = DoseDistribution.new(@doses, @dvol)
        @dist.eql?(dist_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        dist_other = DoseDistribution.new([99.9], @dvol)
        @dist.eql?(dist_other).should be_false
      end

    end


    context "#eud" do

      it "should raise an error when a zero valued alpha factor is used" do
        expect {@dist.eud(0.0)}.to raise_error(ArgumentError)
      end

      it "should give an EUD equal to the mean, when using an alpha factor of 1" do
        dist = DoseDistribution.new([1.0, 2.0, 0.0], @dvol)
        dist.eud(1).should eql 1.0
        dist.eud(1).should eql dist.mean
      end

      it "should give the expected EUD with an alpha factor > 1" do
        dist = DoseDistribution.new([4.0, 2.0, 1.0, 1.0, 1.0, 1.0], @dvol)
        dist.eud(2).should eql 2.0
      end

      it "should give the expected EUD with an alpha factor of -1" do
        dist = DoseDistribution.new([4.0, 4.0, 2.0, 2.0, 2.0, 1.0], @dvol)
        dist.eud(-1).should eql 2.0
      end

      it "should give the expected EUD with an alpha factor < -1" do
        dist = DoseDistribution.new([4, 4, 1, 4, 4], @dvol)
        dist.eud(-2).should eql 2.0
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        dist_other = DoseDistribution.new(@doses, @dvol)
        @dist.hash.should be_a Fixnum
        @dist.hash.should eql dist_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        dist_other = DoseDistribution.new([99.9], @dvol)
        @dist.hash.should_not eql dist_other.hash
      end

    end


    context "#hindex" do

      it "should return 0.0 for a perfectly homogeneous dose distribution" do
        doses = NArray.float(100).fill(2.0)
        dist = DoseDistribution.new(doses, @dvol)
        dist.hindex.should eql 0.0
      end

      it "should return 0.1 for this quite homogeneous dose distribution" do
        doses = NArray.float(20)
        doses[0] = 57.0
        doses[1] = 63.0
        doses[2..19] = 60.0
        dist = DoseDistribution.new(doses, @dvol)
        dist.hindex.should eql 0.1
      end

      it "should return 2.0 for this very inhomogeneous dose distribution" do
        doses = NArray.float(9)
        doses[0..3] = 1
        doses[4] = 20
        doses[5..8] = 41
        dist = DoseDistribution.new(doses, @dvol)
        dist.hindex.should eql 2.0
      end

    end


    context "#max" do

      it "should return the maximum dose of the dose distribution" do
        @dist.max.should eql @max
      end

    end


    context "#mean" do

      it "should return the mean dose of the dose distribution" do
        @dist.mean.should eql @mean
      end

    end


    context "#median" do

      it "should return the median dose of the dose distribution" do
        @dist.median.should eql @median
      end

    end


    context "#min" do

      it "should return the minimum dose of the dose distribution" do
        @dist.min.should eql @min
      end

    end


    context "#rmsdev" do

      it "should return the root mean square deviation (population standard deviation) (using N) of the dose distribution" do
        @dist.rmsdev.round(3).should eql @rmsdev_rounded
      end

    end


    context "#stddev" do

      it "should return the sample standard deviation (using N-1) of the dose distribution" do
        @dist.stddev.round(3).should eql @stddev_rounded
      end

    end


    context "#to_dose_distribution" do

      it "should return itself" do
        @dist.to_dose_distribution.equal?(@dist).should be_true
      end

    end


    context "#v" do

      it "should raise a RangeError when a negative dose argument is given" do
        expect {@dist.v(-5)}.to raise_error(RangeError)
      end

      it "should return 0.0 when the specified dose is higher than that of the distribution's max" do
        doses = NArray.float(100).fill(2.0)
        dist = DoseDistribution.new(doses, @dvol)
        dist.v(3.0).should eql 0.0
      end

      it "should return 100.0 when the specified dose is lower than that of the distribution's min" do
        doses = NArray.float(100).fill(2.0)
        dist = DoseDistribution.new(doses, @dvol)
        dist.v(1.0).should eql 100.0
      end

      it "should return the expected percentage of the distribution having a dose higher or equal to the given" do
        doses = NArray.float(100).indgen
        dist = DoseDistribution.new(doses, @dvol)
        dist.v(5).should eql 95.0
        dist.v(95).should eql 5.0
        dist.v(100).should eql 0.0
        dist.v(0).should eql 100.0
      end

    end

  end

end
# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe Coordinate do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.345.789', 'CT', @f, @st)
      @ss = StructureSet.new('1.765.12', @is)
      @roi = ROI.new("Brain", 1, @f, @ss)
      @s = Slice.new("1.567.898", @roi)
      @c = Contour.new(@s)
      @x = 2.0
      @y = 4.4
      @z = -42.0
      @coord = Coordinate.new(@x, @y, @z, @c)
    end

    context "::new" do

      it "should raise an ArgumentError when a non-Float is passed as 'x' argument" do
        expect {Coordinate.new('42.0', @y, @z, @c)}.to raise_error(ArgumentError, /x/)
      end

      it "should raise an ArgumentError when a non-Float is passed as 'y' argument" do
        expect {Coordinate.new(@x, 42, @z, @c)}.to raise_error(ArgumentError, /y/)
      end

      it "should raise an ArgumentError when a non-Float is passed as 'z' argument" do
        expect {Coordinate.new(@x, @y, 0, @c)}.to raise_error(ArgumentError, /z/)
      end

      it "should raise an ArgumentError when a non-Contour is passed as 'contour' argument" do
        expect {Coordinate.new(@x, @y, @z, 'not-a-Contour')}.to raise_error(ArgumentError, /contour/)
      end

      it "should pass the 'x' argument to the 'x' attribute" do
        @coord.x.should eql @x
      end

      it "should pass the 'y' argument to the 'y' attribute" do
        @coord.y.should eql @y
      end

      it "should pass the 'z' argument to the 'z' attribute" do
        @coord.z.should eql @z
      end

      it "should pass the 'contour' argument to the 'contour' attribute" do
        @coord.contour.should eql @c
      end

      it "should add the Coordinate instance (once) to the referenced Contour" do
        @c.coordinates.length.should eql 1
        @c.coordinates.first.should eql @coord
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        coord_other = Coordinate.new(@x, @y, @z)
        (@coord == coord_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        coord_other = Coordinate.new(@x, @y*3, @z)
        (@coord == coord_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@coord == 42).should be_false
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        coord_other = Coordinate.new(@x, @y, @z)
        @coord.eql?(coord_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        coord_other = Coordinate.new(@x, @y*3, @z)
        @coord.eql?(coord_other).should be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        coord_other = Coordinate.new(@x, @y, @z)
        @coord.hash.should be_a Fixnum
        @coord.hash.should eql coord_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        coord_other = Coordinate.new(@x, @y*3, @z)
        @coord.hash.should_not eql coord_other.hash
      end

    end


    context "#to_coordinate" do

      it "should return itself" do
        @coord.to_coordinate.equal?(@coord).should be_true
      end

    end


    context "#to_s" do

      it "should create a string containing the coordinate triplet (x,y,z) separated by '\'" do
        @coord.to_s.should eql [@coord.x, @coord.y, @coord.z].join("\\")
      end

    end

  end

end
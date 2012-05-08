# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe Plane do

    before :each do
      # Three coordinates in the same plane (z=10):
      @x1 = 2.0
      @y1 = 4.0
      @z1 = 10.0
      @x2 = 0.0
      @y2 = -4.0
      @z2 = 10.0
      @x3 = -6.0
      @y3 = 8.0
      @z3 = 10.0
      @c1 = Coordinate.new(@x1, @y1, @z1)
      @c2 = Coordinate.new(@x2, @y2, @z2)
      @c3 = Coordinate.new(@x3, @y3, @z3)
      @a = 2.0
      @b = 4.0
      @c = 10.0
      @p = Plane.new(@a, @b, @c)
    end

    context "::calculate" do

      it "should raise an ArgumentError when a non-Coordinate is passed as 'c1' argument" do
        expect {Plane.calculate('not-a-Coordinate', @c2, @c3)}.to raise_error(ArgumentError, /c1/)
      end

      it "should raise an ArgumentError when a non-Coordinate is passed as 'c1' argument" do
        expect {Plane.calculate(@c1, 'not-a-Coordinate', @c3)}.to raise_error(ArgumentError, /c2/)
      end

      it "should raise an ArgumentError when a non-Coordinate is passed as 'c1' argument" do
        expect {Plane.calculate(@c1, @c2, 'not-a-Coordinate')}.to raise_error(ArgumentError, /c3/)
      end

      it "should raise an ArgumentError when two of the Coordinates passed as arguments are equal" do
        expect {Plane.calculate(@c1, @c2, @c1)}.to raise_error(ArgumentError, /unique/)
      end

      it "should raise an ArgumentError when all of the Coordinates passed as arguments are equal" do
        expect {Plane.calculate(@c1, @c1, @c1)}.to raise_error(ArgumentError, /unique/)
      end

      it "should create a Plane with the expected (Float) attribute values" do
        p = Plane.calculate(@c1, @c2, @c3)
        p.a.should eql 0.0
        p.b.should eql 0.0
        p.c.should eql -50.0
        p.d.should eql 500.0
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-Float is passed as the 'a' argument" do
        expect {Plane.new('not-a-Float', @b, @c)}.to raise_error(ArgumentError, /'a'/)
      end

      it "should raise an ArgumentError when a non-Float is passed as the 'b' argument" do
        expect {Plane.new(@a, 'not-a-Float', @c)}.to raise_error(ArgumentError, /'b'/)
      end

      it "should raise an ArgumentError when a non-Float is passed as the 'c' argument" do
        expect {Plane.new(@a, @b, 'not-a-Float')}.to raise_error(ArgumentError, /'c'/)
      end


      it "should pass the 'a' argument to the 'a' attribute" do
        @p.a.should eql @a
      end

      it "should pass the 'b' argument to the 'b' attribute" do
        @p.b.should eql @b
      end

      it "should pass the 'c' argument to the 'c' attribute" do
        @p.c.should eql @c
      end

      it "should use the default 'd' value as set by the Plane class" do
        @p.d.should eql Plane.d
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        p_other = Plane.new(@a, @b, @c)
        (@p == p_other).should be_true
      end

      it "should be false when comparing two instances having different attributes" do
        p_other = Plane.new(99.9, @b, @c)
        (@p == p_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@p == 42).should be_false
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        p_other = Plane.new(@a, @b, @c)
        @p.eql?(p_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        p_other = Plane.new(99.9, @b, @c)
        @p.eql?(p_other).should be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        p_other = Plane.new(@a, @b, @c)
        @p.hash.should be_a Fixnum
        @p.hash.should eql p_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        p_other = Plane.new(99.9, @b, @c)
        @p.hash.should_not eql p_other.hash
      end

    end


    context "#match" do

      before :each do
        @p = Plane.calculate(@c1, @c2, @c3)
        # Create a plane equal to the one above (although using other x and y coordinates):
        mc1 = Coordinate.new(10.3, -5.6, @z1)
        mc2 = Coordinate.new(15.5, 7.7, @z2)
        mc3 = Coordinate.new(-11.1, -3.3, @z3)
        @plane_equal = Plane.calculate(mc1, mc2, mc3)
        # Create a plane which is parallel to the original plane:
        pc1 = Coordinate.new(10.3, -5.6, @z1+2)
        pc2 = Coordinate.new(15.5, 7.7, @z2+2)
        pc3 = Coordinate.new(-11.1, -3.3, @z3+2)
        @plane_dev_parallel = Plane.calculate(pc1, pc2, pc3)
        # Create a plane which intersects our original plane:
        ic1 = Coordinate.new(@x1, @y1, @z1)
        ic2 = Coordinate.new(@x2, @y2, @z2+2.0)
        ic3 = Coordinate.new(@x3, @y3, @z3-2.0)
        @plane_dev_intersect = Plane.calculate(ic1, ic2, ic3)
      end

      it "should raise an ArgumentError when a non-Array is passed as the 'planes' argument" do
        expect {@p.match(Plane.new(-2.0, 4.0, -10.0))}.to raise_error(ArgumentError, /'planes'/)
      end

      it "should raise an ArgumentError when a non-Array is passed as the 'planes' argument" do
        expect {@p.match([@p, 'not-a-plane'])}.to raise_error(ArgumentError, /'planes'/)
      end

      it "should produce a match when the planes array contains only one element, which is a plane equal to the one we compare against" do
        @p.match([@plane_equal]).should eql 0
      end

      it "should produce a match (with the expected index) when the planes array contains a plane equal to the one we compare against" do
        @p.match([@plane_equal, @plane_dev_parallel]).should eql 0
      end

      it "should produce a match (with the expected index) when the planes array contains a plane equal to the one we compare against" do
        @p.match([@plane_dev_parallel, @plane_equal]).should eql 1
      end

      it "should not produce a match when the planes array contains only one element, which is a plane parallel to itself" do
        @p.match([@plane_dev_parallel]).should be_nil
      end

      it "should not produce a match when the planes array contains only one element, which is a plane intersecting itself" do
        @p.match([@plane_dev_intersect]).should be_nil
      end

      it "should not produce a match when compared against planes that are parallel to and/or intersecting itself" do
        @p.match([@plane_dev_parallel, @plane_dev_intersect]).should be_nil
      end

    end


    context "#to_plane" do

      it "should return itself" do
        @p.to_plane.equal?(@p).should be_true
      end

    end

  end

end
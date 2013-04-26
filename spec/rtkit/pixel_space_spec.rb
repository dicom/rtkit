# encoding: UTF-8

require 'spec_helper'


module RTKIT

  describe PixelSpace do

    before :each do
      @columns = 3
      @rows = 4
      @delta_col = 3.0
      @delta_row = 1.0
      @pos = Coordinate.new(10.0, -5.0, 2.0)
      @cosines = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0]
      @ps = PixelSpace.create(@columns, @rows, @delta_col, @delta_row, @pos, @cosines)
    end


    context "::create" do

      it "should raise an error when a non-Coordinate is passed as 'pos' argument" do
        expect {PixelSpace.create(@columns, @rows, @delta_col, @delta_row, '42', @cosines)}.to raise_error
      end

      it "should raise an ArgumentError when an invalid cosines array is passed as 'cosines' argument" do
        expect {PixelSpace.create(@columns, @rows, @delta_col, @delta_row, '42', [1, 0])}.to raise_error(ArgumentError)
      end

      it "should pass the 'delta_col' argument to the 'delta_col' attribute" do
        @ps.delta_col.should eql @delta_col
      end

      it "should pass the 'delta_row' argument to the 'delta_row' attribute" do
        @ps.delta_row.should eql @delta_row
      end

      it "should pass the 'pos' argument to the 'pos' attribute" do
        @ps.pos.should eql @pos
      end

      it "should pass the 'columns' argument to the 'columns' attribute" do
        @ps.columns.should eql @columns
      end

      it "should pass the 'rows' argument to the 'rows' attribute" do
        @ps.rows.should eql @rows
      end

      it "should alias 'nx' to the 'columns' attribute" do
        @ps.nx.should eql @columns
      end

      it "should alias 'ny' to the 'rows' attribute" do
        @ps.ny.should eql @rows
      end

      it "should alias 'delta_x' to the 'delta_col' attribute" do
        @ps.delta_x.should eql @delta_col
      end

      it "should alias 'delta_y' to the 'delta_row' attribute" do
        @ps.delta_y.should eql @delta_row
      end

    end


    context "::setup" do

      it "should raise an ArgumentError when a negative source detector distance is passed" do
        expect {PixelSpace.setup(@columns, @rows, @delta_col, @delta_row, 42, -50, @pos)}.to raise_error(ArgumentError, /'sdd'/)
      end

      it "should raise an ArgumentError when a zero source detector distance is passed" do
        expect {PixelSpace.setup(@columns, @rows, @delta_col, @delta_row, 42, 0, @pos)}.to raise_error(ArgumentError, /'sdd'/)
      end

      it "should give the expected 'pos' and 'cosines' attributes for this setup" do
        iso = Coordinate.new(0, 0, 0)
        sdd = 50
        angle = 0
        ps = PixelSpace.setup(cols=3, rows=4, @delta_col, @delta_row, angle, sdd, iso)
        ps.cosines.should eql [1.0, 0.0, 0.0, 0.0, 0.0, -1.0]
        ps.pos.should eql Coordinate.new(-3, 25, 1.5)
      end

      it "should give the expected 'pos' and 'cosines' attributes for this setup" do
        iso = Coordinate.new(0, -5.0, -10.0)
        sdd = 100.0
        angle = 180.0
        ps = PixelSpace.setup(cols=4, rows=3, @delta_col, @delta_row, angle, sdd, iso)
        ps.cosines.should eql [-1.0, 0.0, 0.0, 0.0, 0.0, -1.0]
        ps.pos.should eql Coordinate.new(4.5, -55, -9)
      end

      it "should give the expected 'pos' and 'cosines' attributes for this setup" do
        iso = Coordinate.new(5, 0, 10)
        sdd = 500.0
        angle = 90.0
        ps = PixelSpace.setup(cols=5, rows=3, @delta_col, @delta_row, angle, sdd, iso)
        ps.cosines.should eql [0.0, 1.0, 0.0, 0.0, 0.0, -1.0]
        ps.pos.should eql Coordinate.new(-245, -6, 11)
      end

      it "should give the expected 'pos' and 'cosines' attributes for this setup" do
        iso = Coordinate.new(5, 0, 10)
        sdd = 1000
        angle = 270
        ps = PixelSpace.setup(cols=3, rows=5, @delta_col, @delta_row, angle, sdd, iso)
        ps.cosines.should eql [0.0, -1.0, 0.0, 0.0, 0.0, -1.0]
        ps.pos.should eql Coordinate.new(505, 3, 12)
      end

      it "should give the expected 'pos' and 'cosines' attributes for this setup" do
        iso = Coordinate.new(0, 0, 0)
        sdd = 2 * 3.0 / Math.tan(Math::PI/6.0) # 10.39
        angle = 60
        ps = PixelSpace.setup(cols=3, rows=3, @delta_col, @delta_row, angle, sdd, iso)
        ps.cosines.should eql [0.5, 0.866025403784439, 0.0, 0.0, 0.0, -1.0]
        ps.pos.should eql Coordinate.new(-6, 0, 1)
      end

      it "should give the expected 'pos' and 'cosines' attributes for this setup" do
        iso = Coordinate.new(0, 0, 0)
        sdd = 12.0
        angle = 225.0
        ps = PixelSpace.setup(cols=5, rows=5, @delta_col, @delta_row, angle, sdd, iso)
        ps.cosines.should eql [-0.707106781186548, -0.707106781186548, 0.0, 0.0, 0.0, -1.0]
        ps.pos.x.round(13).should eql Math.sqrt(2*6**2).round(13)
        ps.pos.y.should eql 0.0
        ps.pos.z.should eql 2.0
      end

      it "should pass the 'columns' argument to the 'columns' attribute" do
        ps = PixelSpace.setup(@columns, @rows, @delta_col, @delta_row, 0, 100, @pos)
        ps.columns.should eql @columns
      end

      it "should pass the 'rows' argument to the 'rows' attribute" do
        ps = PixelSpace.setup(@columns, @rows, @delta_col, @delta_row, 0, 100, @pos)
        ps.rows.should eql @rows
      end

      it "should pass the 'delta_x' argument to the 'delta_x' attribute" do
        ps = PixelSpace.setup(@columns, @rows, @delta_col, @delta_row, 0, 100, @pos)
        ps.delta_x.should eql @delta_col
      end

      it "should pass the 'delta_y' argument to the 'delta_y' attribute" do
        ps = PixelSpace.setup(@columns, @rows, @delta_col, @delta_row, 0, 100, @pos)
        ps.delta_y.should eql @delta_row
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        ps_other = PixelSpace.create(@columns, @rows, @delta_col, @delta_row, @pos, @cosines)
        (@ps == ps_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        ps_other = PixelSpace.create(3, 3, 1, 1, Coordinate.new(0, 0, 0), @cosines)
        (@ps == ps_other).should be_false
      end

      it "should be false when comparing two instances with the same attributes, but different pixel values" do
        ps_other = PixelSpace.create(@columns, @rows, @delta_col, @delta_row, @pos, @cosines)
        ps_other[0] = 1
        (@ps == ps_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@ps == 42).should be_false
      end

    end


    context "#cosines=()" do

      it "should raise an error when a non-Array is passed as argument" do
        expect {@ps.cosines = '42.0'}.to raise_error
      end

      it "should raise an ArgumentError when an array with other than 6 elements is passed as argument" do
        expect {@ps.cosines = [1, 0, 1, 0, 1,]}.to raise_error
        expect {@ps.cosines = [1, 0, 1, 0, 1, 0, 1]}.to raise_error
      end

      it "should pass the cosines argument to the 'cosines' attribute" do
        n = 4
        ps = PixelSpace.new(3, n, n)
        ps.cosines = @cosines
        ps.cosines.should eql @cosines
      end

    end


    context "#delta_col=()" do

      it "should raise an error when a non-Float compatible type is passed" do
        expect {@ps.delta_col = Array.new}.to raise_error
      end

      it "should raise an ArgumentError when a negative value is passed" do
        expect {@ps.delta_col = -2}.to raise_error(ArgumentError, /'distance'/)
      end

      it "should raise an ArgumentError when a zero value is passed" do
        expect {@ps.delta_col = 0.0}.to raise_error(ArgumentError, /'distance'/)
      end

      it "should pass the delta_col argument to the 'delta_col' attribute" do
        n = 4
        ps = PixelSpace.new(3, n, n)
        ps.delta_col = @delta_col
        ps.delta_col.should eql @delta_col
      end

    end


    context "#delta_row=()" do

      it "should raise an error when a non-Float compatible type is passed" do
        expect {@ps.delta_row = Array.new}.to raise_error
      end

      it "should raise an ArgumentError when a negative value is passed" do
        expect {@ps.delta_row = -2.0}.to raise_error(ArgumentError, /'distance'/)
      end

      it "should raise an ArgumentError when a zero value is passed" do
        expect {@ps.delta_row = 0}.to raise_error(ArgumentError, /'distance'/)
      end

      it "should pass the delta_row argument to the 'delta_row' attribute" do
        n = 4
        ps = PixelSpace.new(3, n, n)
        ps.delta_row = @delta_row
        ps.delta_row.should eql @delta_row
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        ps_other = PixelSpace.create(@columns, @rows, @delta_col, @delta_row, @pos, @cosines)
        @ps.eql?(ps_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        ps_other = PixelSpace.create(3, 3, 1, 1, Coordinate.new(0, 0, 0), @cosines)
        @ps.eql?(ps_other).should be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        ps_other = PixelSpace.create(@columns, @rows, @delta_col, @delta_row, @pos, @cosines)
        @ps.hash.should be_a Fixnum
        @ps.hash.should eql ps_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        ps_other = PixelSpace.create(3, 3, 1, 1, Coordinate.new(0, 0, 0), @cosines)
        @ps.hash.should_not eql ps_other.hash
      end

    end


    context "#pos=()" do

      it "should raise an error when a non-Coordinate is passed as argument" do
        expect {@ps.pos = '42.0'}.to raise_error
      end

      it "should pass the pos argument to the 'pos' attribute" do
        n = 4
        ps = PixelSpace.new(3, n, n)
        ps.pos = @pos
        ps.pos.should eql @pos
      end

    end


    context "#to_pixel_space" do

      it "should return itself" do
        @ps.to_pixel_space.equal?(@ps).should be_true
      end

    end

  end

end
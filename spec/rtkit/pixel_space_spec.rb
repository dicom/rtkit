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
        expect {PixelSpace.create(@columns, @rows, @delta_col, @delta_row, '42', @cosines)}.to raise_error(/coordinate/)
      end

      it "should raise an ArgumentError when an invalid cosines array is passed as 'cosines' argument" do
        expect {PixelSpace.create(@columns, @rows, @delta_col, @delta_row, '42', [1, 0])}.to raise_error(ArgumentError)
      end

      it "should pass the 'delta_col' argument to the 'delta_col' attribute" do
        expect(@ps.delta_col).to eql @delta_col
      end

      it "should pass the 'delta_row' argument to the 'delta_row' attribute" do
        expect(@ps.delta_row).to eql @delta_row
      end

      it "should pass the 'pos' argument to the 'pos' attribute" do
        expect(@ps.pos).to eql @pos
      end

      it "should pass the 'columns' argument to the 'columns' attribute" do
        expect(@ps.columns).to eql @columns
      end

      it "should pass the 'rows' argument to the 'rows' attribute" do
        expect(@ps.rows).to eql @rows
      end

      it "should alias 'nx' to the 'columns' attribute" do
        expect(@ps.nx).to eql @columns
      end

      it "should alias 'ny' to the 'rows' attribute" do
        expect(@ps.ny).to eql @rows
      end

      it "should alias 'delta_x' to the 'delta_col' attribute" do
        expect(@ps.delta_x).to eql @delta_col
      end

      it "should alias 'delta_y' to the 'delta_row' attribute" do
        expect(@ps.delta_y).to eql @delta_row
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
        expect(ps.cosines).to eql [1.0, 0.0, 0.0, 0.0, 0.0, -1.0]
        expect(ps.pos).to eql Coordinate.new(-3, 25, 1.5)
      end

      it "should give the expected 'pos' and 'cosines' attributes for this setup" do
        iso = Coordinate.new(0, -5.0, -10.0)
        sdd = 100.0
        angle = 180.0
        ps = PixelSpace.setup(cols=4, rows=3, @delta_col, @delta_row, angle, sdd, iso)
        expect(ps.cosines).to eql [-1.0, 0.0, 0.0, 0.0, 0.0, -1.0]
        expect(ps.pos).to eql Coordinate.new(4.5, -55, -9)
      end

      it "should give the expected 'pos' and 'cosines' attributes for this setup" do
        iso = Coordinate.new(5, 0, 10)
        sdd = 500.0
        angle = 90.0
        ps = PixelSpace.setup(cols=5, rows=3, @delta_col, @delta_row, angle, sdd, iso)
        expect(ps.cosines).to eql [0.0, 1.0, 0.0, 0.0, 0.0, -1.0]
        expect(ps.pos).to eql Coordinate.new(-245, -6, 11)
      end

      it "should give the expected 'pos' and 'cosines' attributes for this setup" do
        iso = Coordinate.new(5, 0, 10)
        sdd = 1000
        angle = 270
        ps = PixelSpace.setup(cols=3, rows=5, @delta_col, @delta_row, angle, sdd, iso)
        expect(ps.cosines).to eql [0.0, -1.0, 0.0, 0.0, 0.0, -1.0]
        expect(ps.pos).to eql Coordinate.new(505, 3, 12)
      end

      it "should give the expected 'pos' and 'cosines' attributes for this setup" do
        iso = Coordinate.new(0, 0, 0)
        sdd = 2 * 3.0 / Math.tan(Math::PI/6.0) # 10.39
        angle = 60
        ps = PixelSpace.setup(cols=3, rows=3, @delta_col, @delta_row, angle, sdd, iso)
        expect(ps.cosines).to eql [0.5, 0.866025403784439, 0.0, 0.0, 0.0, -1.0]
        expect(ps.pos).to eql Coordinate.new(-6, 0, 1)
      end

      it "should give the expected 'pos' and 'cosines' attributes for this setup" do
        iso = Coordinate.new(0, 0, 0)
        sdd = 12.0
        angle = 225.0
        ps = PixelSpace.setup(cols=5, rows=5, @delta_col, @delta_row, angle, sdd, iso)
        expect(ps.cosines).to eql [-0.707106781186548, -0.707106781186548, 0.0, 0.0, 0.0, -1.0]
        expect(ps.pos.x.round(13)).to eql Math.sqrt(2*6**2).round(13)
        expect(ps.pos.y).to eql 0.0
        expect(ps.pos.z).to eql 2.0
      end

      it "should pass the 'columns' argument to the 'columns' attribute" do
        ps = PixelSpace.setup(@columns, @rows, @delta_col, @delta_row, 0, 100, @pos)
        expect(ps.columns).to eql @columns
      end

      it "should pass the 'rows' argument to the 'rows' attribute" do
        ps = PixelSpace.setup(@columns, @rows, @delta_col, @delta_row, 0, 100, @pos)
        expect(ps.rows).to eql @rows
      end

      it "should pass the 'delta_x' argument to the 'delta_x' attribute" do
        ps = PixelSpace.setup(@columns, @rows, @delta_col, @delta_row, 0, 100, @pos)
        expect(ps.delta_x).to eql @delta_col
      end

      it "should pass the 'delta_y' argument to the 'delta_y' attribute" do
        ps = PixelSpace.setup(@columns, @rows, @delta_col, @delta_row, 0, 100, @pos)
        expect(ps.delta_y).to eql @delta_row
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        ps_other = PixelSpace.create(@columns, @rows, @delta_col, @delta_row, @pos, @cosines)
        expect(@ps == ps_other).to be true
      end

      it "should be false when comparing two instances having different attribute values" do
        ps_other = PixelSpace.create(3, 3, 1, 1, Coordinate.new(0, 0, 0), @cosines)
        expect(@ps == ps_other).to be false
      end

      it "should be false when comparing two instances with the same attributes, but different pixel values" do
        ps_other = PixelSpace.create(@columns, @rows, @delta_col, @delta_row, @pos, @cosines)
        ps_other[0] = 1
        expect(@ps == ps_other).to be false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@ps == 42).to be_falsey
      end

    end


    context "#cosines=()" do

      it "should raise an error when a non-Array is passed as argument" do
        expect {@ps.cosines = '42.0'}.to raise_error(/array/)
      end

      it "should raise an ArgumentError when an array with other than 6 elements is passed as argument" do
        expect {@ps.cosines = [1, 0, 1, 0, 1,]}.to raise_error(/array/)
        expect {@ps.cosines = [1, 0, 1, 0, 1, 0, 1]}.to raise_error(/array/)
      end

      it "should pass the cosines argument to the 'cosines' attribute" do
        n = 4
        ps = PixelSpace.new(3, n, n)
        ps.cosines = @cosines
        expect(ps.cosines).to eql @cosines
      end

    end


    context "#delta_col=()" do

      it "should raise an error when a non-Float compatible type is passed" do
        expect {@ps.delta_col = Array.new}.to raise_error(/to_f/)
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
        expect(ps.delta_col).to eql @delta_col
      end

    end


    context "#delta_row=()" do

      it "should raise an error when a non-Float compatible type is passed" do
        expect {@ps.delta_row = Array.new}.to raise_error(/to_f/)
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
        expect(ps.delta_row).to eql @delta_row
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        ps_other = PixelSpace.create(@columns, @rows, @delta_col, @delta_row, @pos, @cosines)
        expect(@ps.eql?(ps_other)).to be true
      end

      it "should be false when comparing two instances having different attribute values" do
        ps_other = PixelSpace.create(3, 3, 1, 1, Coordinate.new(0, 0, 0), @cosines)
        expect(@ps.eql?(ps_other)).to be false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        ps_other = PixelSpace.create(@columns, @rows, @delta_col, @delta_row, @pos, @cosines)
        expect(@ps.hash).to be_a Fixnum
        expect(@ps.hash).to eql ps_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        ps_other = PixelSpace.create(3, 3, 1, 1, Coordinate.new(0, 0, 0), @cosines)
        expect(@ps.hash).not_to eql ps_other.hash
      end

    end


    context "#pos=()" do

      it "should raise an error when a non-Coordinate is passed as argument" do
        expect {@ps.pos = '42.0'}.to raise_error(/coordinate/)
      end

      it "should pass the pos argument to the 'pos' attribute" do
        n = 4
        ps = PixelSpace.new(3, n, n)
        ps.pos = @pos
        expect(ps.pos).to eql @pos
      end

    end


    context "#to_pixel_space" do

      it "should return itself" do
        expect(@ps.to_pixel_space.equal?(@ps)).to be true
      end

    end

  end

end
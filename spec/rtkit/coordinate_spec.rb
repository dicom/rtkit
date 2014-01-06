# encoding: UTF-8

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
        expect {Coordinate.new(['42.0'], @y, @z, @c)}.to raise_error
      end

      it "should raise an ArgumentError when a non-Float is passed as 'y' argument" do
        expect {Coordinate.new(@x, [42], @z, @c)}.to raise_error
      end

      it "should raise an ArgumentError when a non-Float is passed as 'z' argument" do
        expect {Coordinate.new(@x, @y, [0], @c)}.to raise_error
      end

      it "should raise an ArgumentError when a non-Contour is passed as 'contour' argument" do
        expect {Coordinate.new(@x, @y, @z, 'not-a-Contour')}.to raise_error(ArgumentError, /contour/)
      end

      it "should pass the 'x' argument to the 'x' attribute" do
        expect(@coord.x).to eql @x
      end

      it "should pass the 'y' argument to the 'y' attribute" do
        expect(@coord.y).to eql @y
      end

      it "should pass the 'z' argument to the 'z' attribute" do
        expect(@coord.z).to eql @z
      end

      it "should convert the 'x' argument to a float when storing the attribute" do
        c = Coordinate.new(1, -2, 3)
        expect(c.x).to eql 1.0
      end

      it "should convert the 'y' argument to a float when storing the attribute" do
        c = Coordinate.new(1, -2, 3)
        expect(c.y).to eql -2.0
      end

      it "should convert the 'z' argument to a float when storing the attribute" do
        c = Coordinate.new(1, -2, 3)
        expect(c.z).to eql 3.0
      end

      it "should pass the 'contour' argument to the 'contour' attribute" do
        expect(@coord.contour).to eql @c
      end

      it "should add the Coordinate instance (once) to the referenced Contour" do
        expect(@c.coordinates.length).to eql 1
        expect(@c.coordinates.first).to eql @coord
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        coord_other = Coordinate.new(@x, @y, @z)
        expect(@coord == coord_other).to be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        coord_other = Coordinate.new(@x, @y*3, @z)
        expect(@coord == coord_other).to be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@coord == 42).to be_false
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        coord_other = Coordinate.new(@x, @y, @z)
        expect(@coord.eql?(coord_other)).to be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        coord_other = Coordinate.new(@x, @y*3, @z)
        expect(@coord.eql?(coord_other)).to be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        coord_other = Coordinate.new(@x, @y, @z)
        expect(@coord.hash).to be_a Fixnum
        expect(@coord.hash).to eql coord_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        coord_other = Coordinate.new(@x, @y*3, @z)
        expect(@coord.hash).not_to eql coord_other.hash
      end

    end


    context "#to_coordinate" do

      it "should return itself" do
        expect(@coord.to_coordinate.equal?(@coord)).to be_true
      end

    end


    context "#to_s" do

      it "should create a string containing the coordinate triplet (x,y,z) separated by '\'" do
        expect(@coord.to_s).to eql [@coord.x, @coord.y, @coord.z].join("\\")
      end

    end


    context "#translate" do

      it "should retain its original x, y & z values when given offsets of zero" do
        x_original = @coord.x
        y_original = @coord.y
        z_original = @coord.z
        @coord.translate(0, 0.0, -0)
        expect(@coord.x).to eql x_original
        expect(@coord.y).to eql y_original
        expect(@coord.z).to eql z_original
      end

      it "should modify its original x, y & z values according to the negative and positive offsets given" do
        x_original = @coord.x
        y_original = @coord.y
        z_original = @coord.z
        x_offset = -5
        y_offset = 10.4
        z_offset = -99.0
        @coord.translate(x_offset, y_offset, z_offset)
        expect(@coord.x).to eql x_original + x_offset
        expect(@coord.y).to eql y_original + y_offset
        expect(@coord.z).to eql z_original + z_offset
      end

    end

  end

end
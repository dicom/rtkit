# encoding: UTF-8

require 'spec_helper'


module RTKIT

  describe VoxelSpace do

    before :each do
      @nx = 3
      @ny = 4
      @nz = 5
      @delta_x = 0.5
      @delta_y = 1.0
      @delta_z = 2.0
      @delta = Coordinate.new(0.5, 1.0, 2.0)
      @pos = Coordinate.new(10.0, -5.0, 0.0)
      @vs = VoxelSpace.create(@nx, @ny, @nz, @delta_x, @delta_y, @delta_z, @pos)
    end


    context "::create" do

      it "should raise an error when a non-Coordinate is passed as 'pos' argument" do
        expect {VoxelSpace.create(@nx, @ny, @nz, @delta_x, @delta_y, @delta_z, '42')}.to raise_error
      end

      it "should pass the 'delta_x' argument to the 'delta_x' attribute" do
        @vs.delta_x.should eql @delta_x
      end

      it "should pass the 'delta_y' argument to the 'delta_y' attribute" do
        @vs.delta_y.should eql @delta_y
      end

      it "should pass the 'delta_z' argument to the 'delta_z' attribute" do
        @vs.delta_z.should eql @delta_z
      end

      it "should pass the 'pos' argument to the 'pos' attribute" do
        @vs.pos.should eql @pos
      end

      it "should pass the 'nx' argument to the 'nx' attribute" do
        @vs.nx.should eql @nx
      end

      it "should pass the 'ny' argument to the 'ny' attribute" do
        @vs.ny.should eql @ny
      end

      it "should pass the 'nz' argument to the 'nz' attribute" do
        @vs.nz.should eql @nz
      end

      it "should alias 'columns' to the 'nx' attribute" do
        @vs.columns.should eql @nx
      end

      it "should alias 'rows' to the 'ny' attribute" do
        @vs.rows.should eql @ny
      end

      it "should alias 'slices' to the 'nz' attribute" do
        @vs.slices.should eql @nz
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        vs_other = VoxelSpace.create(@nx, @ny, @nz, @delta_x, @delta_y, @delta_z, @pos)
        (@vs == vs_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        vs_other = VoxelSpace.create(3, 3, 3, 1, 1, 1, Coordinate.new(0, 0, 0))
        (@vs == vs_other).should be_false
      end

      it "should be false when comparing two instances with the same attributes, but different voxel values" do
        vs_other = VoxelSpace.create(@nx, @ny, @nz, @delta_x, @delta_y, @delta_z, @pos)
        vs_other[0] = 1
        (@vs == vs_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@vs == 42).should be_false
      end

    end


    context "#delta_x=()" do

      it "should pass the delta_x argument to the 'delta_x' attribute" do
        n = 4
        vs = VoxelSpace.new(3, n, n, n)
        vs.delta_x = @delta_x
        vs.delta_x.should eql @delta_x
      end

    end

    context "#delta_y=()" do

      it "should pass the delta_y argument to the 'delta_y' attribute" do
        n = 4
        vs = VoxelSpace.new(3, n, n, n)
        vs.delta_y = @delta_y
        vs.delta_y.should eql @delta_y
      end

    end

    context "#delta_z=()" do

      it "should pass the delta_z argument to the 'delta_z' attribute" do
        n = 4
        vs = VoxelSpace.new(3, n, n, n)
        vs.delta_z = @delta_z
        vs.delta_z.should eql @delta_z
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        vs_other = VoxelSpace.create(@nx, @ny, @nz, @delta_x, @delta_y, @delta_z, @pos)
        @vs.eql?(vs_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        vs_other = VoxelSpace.create(3, 3, 3, 1, 1, 1, Coordinate.new(0, 0, 0))
        @vs.eql?(vs_other).should be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        vs_other = VoxelSpace.create(@nx, @ny, @nz, @delta_x, @delta_y, @delta_z, @pos)
        @vs.hash.should be_a Fixnum
        @vs.hash.should eql vs_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        vs_other = VoxelSpace.create(3, 3, 3, 1, 1, 1, Coordinate.new(0, 0, 0))
        @vs.hash.should_not eql vs_other.hash
      end

    end


    context "#pos=()" do

      it "should raise an error when a non-Coordinate is passed as argument" do
        expect {@vs.pos = '42.0'}.to raise_error
      end

      it "should pass the pos argument to the 'pos' attribute" do
        n = 4
        vs = VoxelSpace.new(3, n, n, n)
        vs.pos = @pos
        vs.pos.should eql @pos
      end

    end


    context "#to_voxel_space" do

      it "should return itself" do
        @vs.to_voxel_space.equal?(@vs).should be_true
      end

    end

  end

end
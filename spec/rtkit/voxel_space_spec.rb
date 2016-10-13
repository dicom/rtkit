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
        expect {VoxelSpace.create(@nx, @ny, @nz, @delta_x, @delta_y, @delta_z, '42')}.to raise_error(/coordinate/)
      end

      it "should pass the 'delta_x' argument to the 'delta_x' attribute" do
        expect(@vs.delta_x).to eql @delta_x
      end

      it "should pass the 'delta_y' argument to the 'delta_y' attribute" do
        expect(@vs.delta_y).to eql @delta_y
      end

      it "should pass the 'delta_z' argument to the 'delta_z' attribute" do
        expect(@vs.delta_z).to eql @delta_z
      end

      it "should pass the 'pos' argument to the 'pos' attribute" do
        expect(@vs.pos).to eql @pos
      end

      it "should pass the 'nx' argument to the 'nx' attribute" do
        expect(@vs.nx).to eql @nx
      end

      it "should pass the 'ny' argument to the 'ny' attribute" do
        expect(@vs.ny).to eql @ny
      end

      it "should pass the 'nz' argument to the 'nz' attribute" do
        expect(@vs.nz).to eql @nz
      end

      it "should alias 'columns' to the 'nx' attribute" do
        expect(@vs.columns).to eql @nx
      end

      it "should alias 'rows' to the 'ny' attribute" do
        expect(@vs.rows).to eql @ny
      end

      it "should alias 'slices' to the 'nz' attribute" do
        expect(@vs.slices).to eql @nz
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        vs_other = VoxelSpace.create(@nx, @ny, @nz, @delta_x, @delta_y, @delta_z, @pos)
        expect(@vs == vs_other).to be true
      end

      it "should be false when comparing two instances having different attribute values" do
        vs_other = VoxelSpace.create(3, 3, 3, 1, 1, 1, Coordinate.new(0, 0, 0))
        expect(@vs == vs_other).to be false
      end

      it "should be false when comparing two instances with the same attributes, but different voxel values" do
        vs_other = VoxelSpace.create(@nx, @ny, @nz, @delta_x, @delta_y, @delta_z, @pos)
        vs_other[0] = 1
        expect(@vs == vs_other).to be false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@vs == 42).to be_falsey
      end

    end


    context "#delta_x=()" do

      it "should pass the delta_x argument to the 'delta_x' attribute" do
        n = 4
        vs = VoxelSpace.new(3, n, n, n)
        vs.delta_x = @delta_x
        expect(vs.delta_x).to eql @delta_x
      end

    end

    context "#delta_y=()" do

      it "should pass the delta_y argument to the 'delta_y' attribute" do
        n = 4
        vs = VoxelSpace.new(3, n, n, n)
        vs.delta_y = @delta_y
        expect(vs.delta_y).to eql @delta_y
      end

    end

    context "#delta_z=()" do

      it "should pass the delta_z argument to the 'delta_z' attribute" do
        n = 4
        vs = VoxelSpace.new(3, n, n, n)
        vs.delta_z = @delta_z
        expect(vs.delta_z).to eql @delta_z
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        vs_other = VoxelSpace.create(@nx, @ny, @nz, @delta_x, @delta_y, @delta_z, @pos)
        expect(@vs.eql?(vs_other)).to be true
      end

      it "should be false when comparing two instances having different attribute values" do
        vs_other = VoxelSpace.create(3, 3, 3, 1, 1, 1, Coordinate.new(0, 0, 0))
        expect(@vs.eql?(vs_other)).to be false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        vs_other = VoxelSpace.create(@nx, @ny, @nz, @delta_x, @delta_y, @delta_z, @pos)
        expect(@vs.hash).to be_a Fixnum
        expect(@vs.hash).to eql vs_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        vs_other = VoxelSpace.create(3, 3, 3, 1, 1, 1, Coordinate.new(0, 0, 0))
        expect(@vs.hash).not_to eql vs_other.hash
      end

    end


    context "#pos=()" do

      it "should raise an error when a non-Coordinate is passed as argument" do
        expect {@vs.pos = '42.0'}.to raise_error(/coordinate/)
      end

      it "should pass the pos argument to the 'pos' attribute" do
        n = 4
        vs = VoxelSpace.new(3, n, n, n)
        vs.pos = @pos
        expect(vs.pos).to eql @pos
      end

    end


    context "#to_voxel_space" do

      it "should return itself" do
        expect(@vs.to_voxel_space.equal?(@vs)).to be true
      end

    end

  end

end
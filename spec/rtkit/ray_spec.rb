# encoding: UTF-8

require 'spec_helper'


module RTKIT

  describe Ray do

    before :each do
      n = 3
      delta_x = 1.0
      delta_y = 1.0
      delta_z = 1.0
      @pos = Coordinate.new(0.0, 0.0, 0.0)
      @vs = VoxelSpace.create(n, n, n, delta_x, delta_y, delta_z, @pos)
      @p1 = Coordinate.new(1, -1, 1)
      @p2 = Coordinate.new(1, 3, 1)
      @r = Ray.new
    end

    context "::new" do

      it "should by default set the p1 attribute as nil" do
        expect(@r.p1).to be_nil
      end

      it "should by default set the p2 attribute as nil" do
        expect(@r.p2).to be_nil
      end

      it "should by default set the vs attribute as nil" do
        expect(@r.vs).to be_nil
      end

      it "should by default set the d attribute as 0.0" do
        expect(@r.d).to eql 0.0
      end

      it "should by default set the indices attribute as nil" do
        expect(@r.indices).to eql Array.new
      end

    end


    context "::trace" do

      it "should raise an ArgumentError when a non-Coordinate is passed as 'p1' argument" do
        expect {Ray.trace('42.0', @p2, @vs)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-Coordinate is passed as 'p2' argument" do
        expect {Ray.trace(@p1, '42.0', @vs)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-Coordinate is passed as 'voxel_space' argument" do
        expect {Ray.trace(@p1, @p2, '42')}.to raise_error(ArgumentError)
      end

      it "should pass the 'p1' argument to the 'p1' attribute" do
        r = Ray.trace(@p1, @p2, @vs)
        expect(r.p1).to eql @p1
      end

      it "should pass the 'p2' argument to the 'p2' attribute" do
        r = Ray.trace(@p1, @p2, @vs)
        expect(r.p2).to eql @p2
      end

      it "should pass the 'voxel_space' argument to the 'vs' attribute" do
        r = Ray.trace(@p1, @p2, @vs)
        expect(r.vs).to eql @vs
      end

      it "should give the expected indices & lengths for this ray trace (perpendicular on a 3**3 voxel space)" do
        # Parallell with y axis (positive direction).
        r = Ray.trace(Coordinate.new(1, -1, 1), Coordinate.new(1, 3, 1), @vs)
        expect(r.indices).to eql [10, 13, 16]
        expect(r.lengths).to eql [1.0, 1.0, 1.0]
      end

      it "should give the expected indices for this ray trace (perpendicular on a 3**3 voxel space)" do
        # Parallell with y axis (negative direction).
        r = Ray.trace(Coordinate.new(1, 3, 1), Coordinate.new(1, -1, 1), @vs)
        expect(r.indices).to eql [16, 13, 10]
      end

      it "should give the expected indices for this ray trace (perpendicular on a 3**3 voxel space)" do
        # Parallell with z axis (positive direction).
        r = Ray.trace(Coordinate.new(0, 0, -1), Coordinate.new(0, 0, 3), @vs)
        expect(r.indices).to eql [0, 9, 18]
      end

      it "should give the expected indices for this ray trace (perpendicular on a 2**2 voxel space)" do
        # Parallell with z axis (negative direction).
        vs = VoxelSpace.create(2, 2, 2, 1, 1, 1, @pos)
        r = Ray.trace(Coordinate.new(0, 0, 3), Coordinate.new(0, 0, -1), vs)
        expect(r.indices).to eql [4, 0]
      end

      it "should give the expected indices for this ray trace (perpendicular on a 3**3 voxel space)" do
        # Parallell with x axis (positive direction).
        r = Ray.trace(Coordinate.new(-1, 2.0, 2.0), Coordinate.new(3, 2.0, 2.0), @vs)
        expect(r.indices).to eql [24, 25, 26]
      end

      it "should give the expected indices for this ray trace (perpendicular on a 3**3 voxel space)" do
        # Parallell with x axis (negative direction).
        r = Ray.trace(Coordinate.new(3, 2, 2), Coordinate.new(-1, 2, 2), @vs)
        expect(r.indices).to eql [26, 25, 24]
      end

      it "should give the expected indices for this ray trace (perpendicular on a 3**3 voxel space, potentially provoking a float imprecision issue)" do
        # Parallell with y axis (positive direction). This case gave an out of index error because the
        # @ac at the last step is minimally less than @alpha_max, due to float imprecision.
        r = Ray.trace(Coordinate.new(0, -1, 0), Coordinate.new(0, 5, 0), @vs)
        expect(r.indices).to eql [0, 3, 6]
      end

=begin
      it "should give the expected indices for this ray trace (potentially provoking an index out of range error)" do
        vs = VoxelSpace.create(4, 5, 3, 2.0, 4.0, 1, Coordinate.new(0.0, 0.0, 0.0))
        r = Ray.trace(Coordinate.new(0.0, -1000.0, 0.0), Coordinate.new(-255.0, 800.0, 255.0), vs)
        r.indices.should eql [0, 3, 6]
      end
=end

      it "should give the expected index for this ray trace (perpendicular on a 1**3 voxel space)" do
        # Parallell with y axis (positive direction).
        vs = VoxelSpace.create(1, 1, 1, 1, 1, 1, @pos)
        r = Ray.trace(Coordinate.new(0, -1, 0), Coordinate.new(0, 2, 0), vs)
        expect(r.indices).to eql [0]
      end

      it "should give the expected index for this ray trace (oblique on a 1**3 voxel space)" do
        vs = VoxelSpace.create(1, 1, 1, 1, 1, 1, @pos)
        r = Ray.trace(Coordinate.new(1, 1, 1), Coordinate.new(-1, -1, -1), vs)
        expect(r.indices).to eql [0]
      end

      it "should give the expected indices for this ray trace (oblique on a 3**3 voxel space)" do
        r = Ray.trace(Coordinate.new(1, -1, 1), Coordinate.new(0, 3, 0), @vs)
        # Note that an equally valid result here would be: [10, 13, 4, 3, 6]
        expect(r.indices).to eql [10, 13, 12, 3, 6]
      end

      it "should give the expected indices & lengths for this ray trace (symmetrically oblique on a 3**3 voxel space)" do
        r = Ray.trace(Coordinate.new(4, 4, 4), Coordinate.new(-2, -2, -2), @vs)
        # Note that there are multiple valid index sequences for this ray trace.
        expect(r.indices).to eql [26, 25, 22, 13, 12, 9, 0]
        expect(r.lengths.collect {|f| f.round(10)}).to eql [3**0.5, 0, 0, 3**0.5, 0, 0, 3**0.5].collect {|f| f.round(10)}
      end

      it "should give the expected index & lengths for this ray trace (where it barely strafes through one voxel, entering through the z-x plane and leaving through the y-x plane)" do
        # This setup originally gave an index out of range error, as the initial directional alpha values was incorrectly determined.
        vs = VoxelSpace.create(3, 2, 1, 1, 2, 1, Coordinate.new(0.5, 3, 2.5))
        r = Ray.trace(Coordinate.new(0, 0, 0), Coordinate.new(1, 8, 10), vs)
        expect(r.indices).to eql [0]
        expect(r.lengths.collect {|f| f.round(4)}).to eql [0.6423]
      end

      it "should avoid an index out of range error with this case by using proper rounding" do
        vs = VoxelSpace.create(512, 171, 5, 0.6, 0.6, 75, Coordinate.new(-150, -50, 75))
        r = Ray.trace(Coordinate.new(0.3, -1000, 0), Coordinate.new(-250, 800, 255), vs)
      end

      #
      # Examples of rays missing the voxel space:
      #

      it "should give an empty indices array for this ray (which obliquely misses a 1**3 voxel space, potentially giving a negative alpha_max)" do
        vs = VoxelSpace.create(1, 1, 1, 1, 1, 1, @pos)
        r = Ray.trace(Coordinate.new(1, -1, -1), Coordinate.new(2, 2, 2), vs)
        expect(r.indices).to eql Array.new
      end

      it "should give an empty indices array for this ray (which obliquely misses a 1**3 voxel space, potentially giving an empty set of first intersection points)" do
        vs = VoxelSpace.create(1, 1, 1, 1, 1, 1, @pos)
        r = Ray.trace(Coordinate.new(-1, 2, 2), Coordinate.new(-4, 3, 3), vs)
        expect(r.indices).to eql Array.new
      end

      it "should give an empty indices array for this ray (which perpendicularly misses a 2**3 voxel space, potentially provoking a float error when trying to calculate a phi_x for min and max indices)" do
        vs = VoxelSpace.create(2, 2, 2, 1, 1, 1, @pos)
        r = Ray.trace(Coordinate.new(-1, 3, 3), Coordinate.new(3, 3, 3), vs)
        expect(r.indices).to eql Array.new
      end

      it "should give an empty indices array for this ray (which perpendicularly never reaches the voxel space)" do
        vs = VoxelSpace.create(2, 2, 2, 1, 1, 1, @pos)
        r = Ray.trace(Coordinate.new(1, -100, 1), Coordinate.new(1, -50, 1), vs)
        expect(r.indices).to eql Array.new
      end

      it "should give an empty indices array for this ray (which perpendicularly starts 'after' the voxel space)" do
        vs = VoxelSpace.create(2, 2, 2, 1, 1, 1, @pos)
        r = Ray.trace(Coordinate.new(1, 50, 1), Coordinate.new(1, 100, 1), vs)
        expect(r.indices).to eql Array.new
      end

      it "should give empty indices for this ray (potentially provoking a negative index)" do
        vs = VoxelSpace.create(3, 3, 3, 1, 4, 1, Coordinate.new(0.0, 0.0, 0.0))
        r = Ray.trace(Coordinate.new(0.0, -20.0, 0.0), Coordinate.new(-10.0, 20.0, -10.0), vs)
        expect(r.indices).to eql []
      end

      it "should give empty indices for this ray (potentially provoking a negative index)" do
        vs = VoxelSpace.create(3, 3, 3, 1, 4, 1, Coordinate.new(0.0, 0.0, 0.0))
        r = Ray.trace(Coordinate.new(-10.0, 20.0, -10.0), Coordinate.new(0.0, -20.0, 0.0), vs)
        expect(r.indices).to eql []
      end

      it "should give empty indices for this ray trace (perpendicularly barely missing a 3**3 voxel space)" do
        # Parallell with x axis (negative direction).
        r = Ray.trace(Coordinate.new(3, 2.5, 2.5), Coordinate.new(-1, 2.5, 2.5), @vs)
        expect(r.indices).to eql []
      end

      it "should give the empty indices & lengths for this ray trace (barely missing the voxel space)" do
        vs = VoxelSpace.create(3, 2, 1, 1, 2, 1, Coordinate.new(0.5, 3, 1.5))
        r = Ray.trace(Coordinate.new(0, 0, 0), Coordinate.new(1, 8, 10), vs)
        expect(r.indices).to eql []
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        r_other = Ray.new
        expect(@r == r_other).to be true
      end

      it "should be false when comparing two instances having different attribute values" do
        r_other = Ray.new
        r_other.p1 = @p1
        expect(@r == r_other).to be false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@r == 42).to be_falsey
      end

    end


    context "#ax" do

      it "should give the fraction of the x length between source and target for the ray's travel to the given plane index i" do
        r = Ray.new
        r.p1 = Coordinate.new(-1, 2.5, 2.5)
        r.p2 = Coordinate.new(3, 2.5, 2.5)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 1, 1, @pos)
        expect(r.ax(0)).to eql 0.125
        expect(r.ax(3)).to eql 0.875
      end

      it "should give -Infinity when the ray's travel is perpendicular to the x axis, and the x coordinate of the given plane is less than p1.x" do
        r = Ray.new
        r.p1 = Coordinate.new(1.5, -1, 1.5)
        r.p2 = Coordinate.new(1.5, 3, 1.5)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 1, 1, @pos)
        expect(r.ax(0)).to eql -Float::INFINITY
      end

      it "should give Infinity when the ray's travel is perpendicular to the x axis, and the x coordinate of the given plane is equal to p1.x" do
        r = Ray.new
        r.p1 = Coordinate.new(1.5, -1, 1.5)
        r.p2 = Coordinate.new(1.5, 3, 1.5)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 1, 1, @pos)
        expect(r.ax(2)).to eql Float::INFINITY
      end

      it "should give Infinity when the ray's travel is perpendicular to the x axis, and the x coordinate of the given plane is greater than p1.x" do
        r = Ray.new
        r.p1 = Coordinate.new(1.5, -1, 1.5)
        r.p2 = Coordinate.new(1.5, 3, 1.5)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 1, 1, @pos)
        expect(r.ax(3)).to eql Float::INFINITY
      end

    end


    context "#ay" do

      it "should give the fraction of the y length between source and target for the ray's travel to the given plane index j" do
        r = Ray.new
        r.p1 = Coordinate.new(2.5, -1, 2.5)
        r.p2 = Coordinate.new(2.5, 3, 2.5)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 1, 1, @pos)
        expect(r.ay(0)).to eql 0.125
        expect(r.ay(3)).to eql 0.875
      end

      it "should give -Infinity when the ray's travel is perpendicular to the y axis, and the y coordinate of the given plane is less than p1.y" do
        r = Ray.new
        r.p1 = Coordinate.new(1.5, 1.5, -1)
        r.p2 = Coordinate.new(1.5, 1.5, 3)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 1, 1, @pos)
        expect(r.ay(0)).to eql -Float::INFINITY
      end

      it "should give Infinity when the ray's travel is perpendicular to the y axis, and the y coordinate of the given plane is equal to p1.y" do
        r = Ray.new
        r.p1 = Coordinate.new(1.5, 1.5, -1)
        r.p2 = Coordinate.new(1.5, 1.5, 3)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 1, 1, @pos)
        expect(r.ay(2)).to eql Float::INFINITY
      end

      it "should give Infinity when the ray's travel is perpendicular to the y axis, and the y coordinate of the given plane is greater than p1.y" do
        r = Ray.new
        r.p1 = Coordinate.new(1.5, 1.5, -1)
        r.p2 = Coordinate.new(1.5, 1.5, 3)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 1, 1, @pos)
        expect(r.ay(3)).to eql Float::INFINITY
      end

    end


    context "#az" do

      it "should give the fraction of the z length between source and target for the ray's travel to the given plane index k" do
        r = Ray.new
        r.p1 = Coordinate.new(2, 2, -1)
        r.p2 = Coordinate.new(2, 2, 3)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 1, 1, @pos)
        expect(r.az(0)).to eql 0.125
        expect(r.az(3)).to eql 0.875
      end

      it "should give -Infinity when the ray's travel is perpendicular to the z axis, and the z coordinate of the given plane is less than p1.z" do
        r = Ray.new
        r.p1 = Coordinate.new(-1, 1, 1)
        r.p2 = Coordinate.new(3, 1, 1)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 1, 1, @pos)
        expect(r.az(0)).to eql -Float::INFINITY
      end

      it "should give Infinity when the ray's travel is perpendicular to the z axis, and the z coordinate of the given plane is equal to p1.z" do
        r = Ray.new
        r.p1 = Coordinate.new(-1, 1, 1)
        r.p2 = Coordinate.new(3, 1, 1)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 1, 1, @pos)
        expect(r.az(2)).to eql Float::INFINITY
      end

      it "should give Infinity when the ray's travel is perpendicular to the z axis, and the z coordinate of the given plane is greater than p1.z" do
        r = Ray.new
        r.p1 = Coordinate.new(-1, 1, 1)
        r.p2 = Coordinate.new(3, 1, 1)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 1, 1, @pos)
        expect(r.az(3)).to eql Float::INFINITY
      end

    end


    context "#bx" do

      it "should give the x coordinate of the first x plane of the ray's voxel space" do
        r = Ray.new
        pos = Coordinate.new(0, 2, 4)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 2, 3, pos)
        expect(r.bx).to eql -0.5
      end

    end


    context "#by" do

      it "should give the y coordinate of the first y plane of the ray's voxel space" do
        r = Ray.new
        pos = Coordinate.new(0, 2, 4)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 2, 3, pos)
        expect(r.by).to eql 1.0
      end

    end


    context "#bz" do

      it "should give the z coordinate of the first z plane of the ray's voxel space" do
        r = Ray.new
        pos = Coordinate.new(0, 2, 4)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 2, 3, pos)
        expect(r.bz).to eql 2.5
      end

    end


    context "#coord_x" do

      it "should give the x coordinate of the given plane index" do
        r = Ray.new
        pos = Coordinate.new(0, 2, 4)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 2, 3, pos)
        expect(r.coord_x(0)).to eql -0.5
      end

      it "should give the x coordinate of the given plane index" do
        r = Ray.new
        pos = Coordinate.new(0, 2, 4)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 2, 3, pos)
        expect(r.coord_x(3)).to eql 2.5
      end

    end


    context "#coord_y" do

      it "should give the y coordinate of the given plane index" do
        r = Ray.new
        pos = Coordinate.new(0, 2, 4)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 2, 3, pos)
        expect(r.coord_y(0)).to eql 1.0
      end

      it "should give the y coordinate of the given plane index" do
        r = Ray.new
        pos = Coordinate.new(0, 2, 4)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 2, 3, pos)
        expect(r.coord_y(3)).to eql 7.0
      end

    end


    context "#coord_z" do

      it "should give the z coordinate of the given plane index" do
        r = Ray.new
        pos = Coordinate.new(0, 2, 4)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 2, 3, pos)
        expect(r.coord_z(0)).to eql 2.5
      end

      it "should give the z coordinate of the given plane index" do
        r = Ray.new
        pos = Coordinate.new(0, 2, 4)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 2, 3, pos)
        expect(r.coord_z(3)).to eql 11.5
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        r_other = Ray.new
        expect(@r.eql?(r_other)).to be true
      end

      it "should be false when comparing two instances having different attribute values" do
        r_other = Ray.new
        r_other.p1 = @p1
        expect(@r.eql?(r_other)).to be false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        r_other = Ray.new
        expect(@r.hash).to be_a Fixnum
        expect(@r.hash).to eql r_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        r_other = Ray.new
        r_other.p1 = @p1
        expect(@r.hash).not_to eql r_other.hash
      end

    end


    context "#p1=()" do

      it "should pass the point1 argument to the 'p1' attribute" do
        r = Ray.new
        r.p1 = @p1
        expect(r.p1).to eql @p1
      end

    end


    context "#p2=()" do

      it "should pass the point2 argument to the 'p1' attribute" do
        r = Ray.new
        r.p2 = @p2
        expect(r.p2).to eql @p2
      end

    end


    context "#phi_x" do

      it "should give the index of the x plane which corresponds to the given alpha" do
        r = Ray.new
        r.p1 = Coordinate.new(-1, 1, 1)
        r.p2 = Coordinate.new(3, 1, 1)
        pos = Coordinate.new(0, 2, 4)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 2, 3, pos)
        expect(r.phi_x(0.375)).to eql 1
      end

      it "should give the plane index corresponding to the source position (instead of e.g. NaN) when the ray is perpendicular on the x axis (source x equals target x)" do
        r = Ray.new
        x = 1
        r.p1 = Coordinate.new(x, -1, 1)
        r.p2 = Coordinate.new(x, 3, 1)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 1, 1, @pos)
        expect(r.phi_x(0)).to eql x
        expect(r.phi_x(0.375)).to eql x
        expect(r.phi_x(1)).to eql x
      end

      it "should give the plane index (1) corresponding to the source position (instead of e.g. NaN) when the ray is perpendicular on the x axis (source x equals target x)" do
        r = Ray.new
        x = 1
        r.p1 = Coordinate.new(0, 0, 0)
        r.p2 = Coordinate.new(0, 5, 10)
        r.vs = VoxelSpace.create(3, 3, 1, 1, 1, 1, Coordinate.new(-1, 1, 5))
        expect(r.phi_x(0)).to eql 1
        expect(r.phi_x(0.375)).to eql 1
        expect(r.phi_x(1)).to eql 1
      end

    end


    context "#phi_y" do

      it "should give the index of the y plane which corresponds to the given alpha" do
        r = Ray.new
        r.p1 = Coordinate.new(1, 0, 1)
        r.p2 = Coordinate.new(1, 8, 1)
        pos = Coordinate.new(0, 2, 4)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 2, 3, pos)
        expect(r.phi_y(0.625)).to eql 2
      end

      it "should give the plane index corresponding to the source position (instead of e.g. NaN) when the ray is perpendicular on the y axis (source y equals target y)" do
        r = Ray.new
        y = 2
        r.p1 = Coordinate.new(-1, y, -1)
        r.p2 = Coordinate.new(3, y, 3)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 1, 1, @pos)
        expect(r.phi_y(0)).to eql y
        expect(r.phi_y(0.5)).to eql y
        expect(r.phi_y(1)).to eql y
      end

    end


    context "#phi_z" do

      it "should give the index of the z plane which corresponds to the given alpha" do
        r = Ray.new
        r.p1 = Coordinate.new(1, 1, 1)
        r.p2 = Coordinate.new(1, 1, 13)
        pos = Coordinate.new(0, 2, 4)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 2, 3, pos)
        expect(r.phi_z(0.875)).to eql 3
      end

      it "should give the plane index corresponding to the source position (instead of e.g. NaN) when the ray is perpendicular on the z axis (source z equals target z)" do
        r = Ray.new
        z = 0
        r.p1 = Coordinate.new(3, -1, z)
        r.p2 = Coordinate.new(-1, 3, z)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 1, 1, @pos)
        expect(r.phi_z(0)).to eql z
        expect(r.phi_z(0.625)).to eql z
        expect(r.phi_z(1)).to eql z
      end

    end


    context "#vs=()" do

      it "should pass the voxel_space argument to the 'vs' attribute" do
        r = Ray.new
        r.vs = @vs
        expect(r.vs).to eql @vs
      end

    end


    context "#px" do

      it "should give the x coordinate of the ray" do
        r = Ray.new
        r.p1 = Coordinate.new(-1, 1, 1)
        r.p2 = Coordinate.new(3, 1, 1)
        pos = Coordinate.new(0, 2, 4)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 2, 3, pos)
        expect(r.px(0.375)).to eql 0.5
      end

    end


    context "#py" do

      it "should give the y coordinate of the ray" do
        r = Ray.new
        r.p1 = Coordinate.new(1, 0, 1)
        r.p2 = Coordinate.new(1, 8, 1)
        pos = Coordinate.new(0, 2, 4)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 2, 3, pos)
        expect(r.py(0.625)).to eql 5.0
      end

    end


    context "#pz" do

      it "should give the z coordinate of the ray" do
        r = Ray.new
        r.p1 = Coordinate.new(1, 1, 1)
        r.p2 = Coordinate.new(1, 1, 13)
        pos = Coordinate.new(0, 2, 4)
        r.vs = VoxelSpace.create(3, 3, 3, 1, 2, 3, pos)
        expect(r.pz(0.875)).to eql 11.5
      end

    end


    context "#reset" do

      it "should reset the ray's computed parameters" do
        r = Ray.trace(@p1, @p2, @vs)
        r.reset
        expect(r.d).to eql 0.0
        expect(r.indices).to eql Array.new
      end

    end


    context "#to_ray" do

      it "should return itself" do
        expect(@r.to_ray.equal?(@r)).to be true
      end

    end

  end

end
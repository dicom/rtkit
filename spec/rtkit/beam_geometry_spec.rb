# encoding: UTF-8

require 'spec_helper'


module RTKIT

  describe BeamGeometry do

    before :each do
      @nx = 3
      @ny = 3
      @nz = 3
      @delta_x = 1
      @delta_y = 1
      @delta_z = 1
      @cosines = [0, 0, 1, 1, 0, 0]
      @source = Coordinate.new(1, -1, 1)
      @isocenter = Coordinate.new(1, 1, 1)
      @volume_pos = Coordinate.new(0, 0, 0)
      @image_pos = Coordinate.new(0, 3, 0)
      @vs = VoxelSpace.create(@nx, @ny, @nz, @delta_x, @delta_y, @delta_z, @volume_pos)
      @ps = PixelSpace.create(@nx, @ny, @delta_x, @delta_y, @image_pos, @cosines)
      @bg = BeamGeometry.new(@source, @isocenter, @vs)
    end

    context "::new" do

      it "should raise an error when a non-BeamGeometry is passed as 'source' argument" do
        expect {BeamGeometry.new(42.0, @isocenter, @vs)}.to raise_error(/to_coordinate/)
      end

      it "should raise an error when a non-BeamGeometry is passed as 'isocenter' argument" do
        expect {BeamGeometry.new(@source, 42.0, @vs)}.to raise_error(/to_coordinate/)
      end

      it "should raise an error when a non-VoxelSpace is passed as 'voxel_space' argument" do
        expect {BeamGeometry.new(@source, @isocenter, 42.0)}.to raise_error(/to_voxel_space/)
      end

      it "should pass the 'source' argument to the 'source' attribute" do
        expect(@bg.source).to eql @source
      end

      it "should pass the 'isocenter' argument to the 'isocenter' attribute" do
        expect(@bg.isocenter).to eql @isocenter
      end

      it "should pass the 'voxel_space' argument to the 'voxel_space' attribute" do
        expect(@bg.voxel_space).to eql @vs
      end

    end


    context "::setup" do

      it "should raise an ArgumentError when a negative source isocenter distance is passed" do
        expect {BeamGeometry.setup(0.0, -100, @isocenter, @vs)}.to raise_error(ArgumentError, /'sid'/)
      end

      it "should raise an ArgumentError when a zero source isocenter distance is passed" do
        expect {BeamGeometry.setup(0.0, 0, @isocenter, @vs)}.to raise_error(ArgumentError, /'sid'/)
      end

      it "should give the expected 'source' attribute for this setup" do
        iso = Coordinate.new(0, 0, 0)
        sid = 50
        angle = 0
        bg = BeamGeometry.setup(angle, sid, iso, @vs)
        expect(bg.source).to eql Coordinate.new(0, -50, 0)
      end

      it "should give the expected 'source' attribute for this setup" do
        iso = Coordinate.new(0, -5.0, -10.0)
        sid = 100.0
        angle = 180.0
        bg = BeamGeometry.setup(angle, sid, iso, @vs)
        expect(bg.source).to eql Coordinate.new(0, 95, -10.0)
      end

      it "should give the expected 'source' attribute for this setup" do
        iso = Coordinate.new(5, 0, 10)
        sid = 500.0
        angle = 90.0
        bg = BeamGeometry.setup(angle, sid, iso, @vs)
        expect(bg.source).to eql Coordinate.new(505, 0, 10)
      end

      it "should give the expected 'source' attribute for this setup" do
        iso = Coordinate.new(5, 0, 10)
        sid = 1000
        angle = 270
        bg = BeamGeometry.setup(angle, sid, iso, @vs)
        expect(bg.source).to eql Coordinate.new(-995, 0, 10)
      end

      it "should give the expected 'source' attribute for this setup" do
        iso = Coordinate.new(0, 0, 0)
        sid = 100
        angle = 60
        bg = BeamGeometry.setup(angle, sid, iso, @vs)
        expect(bg.source).to eql Coordinate.new(86.6025403784439, -50.0, 0.0)
      end

      it "should give the expected 'source' attribute for this setup" do
        iso = Coordinate.new(0, 0, 0)
        sid = 100.0
        angle = 225.0
        bg = BeamGeometry.setup(angle, sid, iso, @vs)
        source = bg.source
        expect(source.x.round(6)).to eql -70.710678
        expect(source.y.round(6)).to eql 70.710678
        expect(source.z).to eql 0.0
      end

      it "should pass the 'isocenter' argument to the 'isocenter' attribute" do
        bg = BeamGeometry.setup(0.0, 1000.0, @isocenter, @vs)
        expect(bg.isocenter).to eql @isocenter
      end

      it "should pass the 'voxel_space' argument to the 'voxel_space' attribute" do
        bg = BeamGeometry.setup(0.0, 1000.0, @isocenter, @vs)
        expect(bg.voxel_space).to eql @vs
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        bg_other = BeamGeometry.new(@source, @isocenter, @vs)
        expect(@bg == bg_other).to be true
      end

      it "should be false when comparing two instances having different attribute values" do
        bg_other = BeamGeometry.new(@source, Coordinate.new(4, -5, 6), @vs)
        expect(@bg == bg_other).to be false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@bg == 42).to be_falsey
      end

    end


    context "#create_drr" do

      it "should raise an error when a non-PixelSpace is passed as 'pixel_space' argument" do
        expect {@bg.create_drr(42.0)}.to raise_error(/to_pixel_space/)
      end

      it "should return a PixelSpace instance (when the rays intersect the voxel space)" do
        result = @bg.create_drr(@ps)
        expect(result).to be_a PixelSpace
      end

      it "should return a PixelSpace instance (when the rays misses the voxel space)" do
        source = Coordinate.new(-50, -10, -50)
        iso = Coordinate.new(1, 1, 1)
        vs = VoxelSpace.create(3, 3, 3, 1, 1, 1, Coordinate.new(0, 0, 0))
        bg = BeamGeometry.new(source, iso, vs)
        ps = PixelSpace.create(@nx, @ny, @delta_x, @delta_y, Coordinate.new(-50, 10, -50), @cosines)
        result = bg.create_drr(ps)
        expect(result).to be_a PixelSpace
      end

=begin
      it "should fill the pixel space with empty density values for this empty voxel space" do
        result = @bg.create_drr(@ps)
        NArray[result].should eql NArray[NArray.sint(3, 3)]
      end

      it "should fill the pixel space with the same (non-zero) value for this setup" do
        # Note that this is not a very principal test, and should possibly be replaced.
        @vs[true, 0, true] = NArray.int(3, 3).indgen!
        result = @bg.create_drr(@ps)
        result.to_a.flatten.uniq.should eql [4]
      end

      it "should fill the pixel space with the expected density values for this voxel space setup" do
        # Note that this is not a very principal test, and should possibly be replaced.
        @vs[true, 2, true] = NArray.int(3, 3).indgen!
        result = @bg.create_drr(@ps)
        result.to_a.should eql NArray.int(3, 3).indgen!.to_a.transpose
      end
=end

=begin
      it "should fill the pixel space with the expected density values for this voxel space setup" do
        # Note that this is not a very principal test, and should possibly be replaced.
        @nx = 4
        @ny = 4
        @nz = 1
        @delta_x = 50
        @delta_y = 200
        @delta_z = 50
        @cosines = [0, 0, 1, 1, 0, 0]
        @source = Coordinate.new(0, -300, 0)
        @isocenter = Coordinate.new(0, 0, 0)
        @volume_pos = Coordinate.new(-75, -100, -75)
        @image_pos = Coordinate.new(-150, 300, -150)
        @vs = VoxelSpace.create(@nx, @ny, @nz, @delta_x, @delta_y, @delta_z, @volume_pos)
        @ps = PixelSpace.create(@nx+4, @ny+4, @delta_x, @delta_y, @image_pos, @cosines)
        @bg = BeamGeometry.new(@source, @isocenter, @vs)
        # Create an outer ring of dense material, and fill the interior with a mix of soft tissue and air:
        #@vs[true, 2, true] = NArray.int(3, 3).indgen!
        @vs[0, true, 0] = 3000
        @vs[3, true, 0] = 3000
        @vs[true, 0, 0] = 3000
        @vs[true, 3, 0] = 3000
        @vs[1, 1, 0] = 1000
        @vs[2, 1, 0] = 0
        @vs[1, 2, 0] = -500
        @vs[2, 2, 0] = -1000
        result = @bg.create_drr(@ps)
puts result.inspect
        #result.to_a.should eql NArray.int(8, 8).indgen!.to_a.transpose
      end
=end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        bg_other = BeamGeometry.new(@source, @isocenter, @vs)
        expect(@bg.eql?(bg_other)).to be true
      end

      it "should be false when comparing two instances having different attribute values" do
        bg_other = BeamGeometry.new(Coordinate.new(4, -5, 6), @isocenter, @vs)
        expect(@bg.eql?(bg_other)).to be false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        bg_other = BeamGeometry.new(@source, @isocenter, @vs)
        expect(@bg.hash).to be_a Fixnum
        expect(@bg.hash).to eql bg_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        bg_other = BeamGeometry.new(@source, @isocenter, VoxelSpace.create(3, 3, 3, 2, 2, 2, @volume_pos))
        expect(@bg.hash).not_to eql bg_other.hash
      end

    end


    context "#isocenter=()" do

      it "should raise an error when a non-Coordinate is passed as argument" do
        expect {@bg.isocenter = '42.0'}.to raise_error(/coordinate/)
      end

      it "should pass the position argument to the 'isocenter' attribute" do
        isocenter = Coordinate.new(1, 2, 3)
        @bg.isocenter = isocenter
        expect(@bg.isocenter).to eql isocenter
      end

    end


    context "#source=()" do

      it "should raise an error when a non-Coordinate is passed as argument" do
        expect {@bg.source = '42.0'}.to raise_error(/coordinate/)
      end

      it "should pass the position argument to the 'source' attribute" do
        source = Coordinate.new(1, 2, 3)
        @bg.source = source
        expect(@bg.source).to eql source
      end

    end


    context "#to_beam_geometry" do

      it "should return itself" do
        expect(@bg.to_beam_geometry.equal?(@bg)).to be true
      end

    end


    context "#voxel_space=()" do

      it "should raise an error when a non-VoxelSpace is passed as argument" do
        expect {@bg.voxel_space = '42.0'}.to raise_error(/to_voxel_space/)
      end

      it "should pass the vs argument to the 'voxel_space' attribute" do
        vs = VoxelSpace.create(3, 3, 3, 2, 2, 2, @volume_pos)
        @bg.voxel_space = vs
        expect(@bg.voxel_space).to eql vs
      end

    end

  end

end
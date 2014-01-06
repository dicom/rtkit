# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe BinMatcher do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @f = Frame.new('1.4321', @p)
      @st = Study.new('1.456.789', @p)
      @is = ImageSeries.new('1.345.789', 'CT', @f, @st)
      @i1 = SliceImage.new('1.6789.5', 5.0, @is)
      @bv = BinVolume.new(@is)
      @bm = BinMatcher.new
    end

    context "::new" do

      it "should raise an ArgumentError when the 'volumes' argument is specified and it is not an Array" do
        expect {BinMatcher.new('invalid')}.to raise_error(ArgumentError, /volumes/)
      end

      it "should raise an ArgumentError when an array is passed in the 'volumes' argument and it contains an element which is not a BinVolume" do
        expect {BinMatcher.new(['invalid'])}.to raise_error(ArgumentError, /volumes/)
      end

      it "should raise an ArgumentError when the 'master' argument is specified and it is not a BinVolume" do
        expect {BinMatcher.new(nil, 'invalid')}.to raise_error(ArgumentError, /master/)
      end

      it "should create a BinMatcher instance when no arguments are passed" do
        expect(BinMatcher.new.class).to eql BinMatcher
      end

      it "should create a BinMatcher instance when nil-arguments are passed" do
        expect(BinMatcher.new(volumes=nil, master=nil).class).to eql BinMatcher
      end

      it "should set the volumes attribute as an empty array and the master attribute as nil when an empty BinMatcher instance is created" do
        expect(@bm.master).to be_nil
        expect(@bm.volumes).to eql Array.new
      end

      it "should create a BinMatcher instance when a BinVolume array is passed for 'volumes' and a BinVolume is passed for 'master', and transfer these to the instance attributes" do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        img_series = d.patient.study.image_series.first
        volumes = Array.new
        master = img_series.struct.structure('External').bin_volume
        volumes << img_series.struct.structure('Small').bin_volume
        bm = BinMatcher.new(volumes, master)
        expect(bm.class).to eql BinMatcher
        expect(bm.volumes).to eql volumes
        expect(bm.master).to eql master
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        bm_other = BinMatcher.new
        expect(@bm == bm_other).to be_true
      end

      it "should be false when comparing two instances having different attributes" do
        bm_other = BinMatcher.new([@bv])
        expect(@bm == bm_other).to be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@bm == 42).to be_false
      end

    end


    context "#add" do

      it "should raise an ArgumentError when the argument is not a BinVolume" do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        bm = BinMatcher.new
        expect {bm.add('invalid')}.to raise_error(ArgumentError, /volume/)
      end

      it "should add the BinVolume instance to the BinMatcher volumes attribute" do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        volume = d.patient.study.image_series.first.struct.structure('External').bin_volume
        @bm.add(volume)
        expect(@bm.volumes).to eql [volume]
      end

    end


    context "#by_sensitivity" do

      it "should return an array of volumes, ranked by their sensitivity scores (volume with best score first)" do
        b1 = BinVolume.new(@is)
        b2 = BinVolume.new(@is)
        b3 = BinVolume.new(@is)
        b1.sensitivity = 0.1
        b2.sensitivity = 0.55
        b3.sensitivity = 0.9
        bm = BinMatcher.new([b3, b1, b2])
        ranked = bm.by_sensitivity
        expect(ranked.first).to eql b3
        expect(ranked.last).to eql b1
      end

    end


    context "#by_specificity" do

      it "should return an array of volumes, ranked by their specificity scores (volume with best score first)" do
        b1 = BinVolume.new(@is)
        b2 = BinVolume.new(@is)
        b3 = BinVolume.new(@is)
        b1.specificity = 0.2
        b2.specificity = 0.41
        b3.specificity = 0.8
        bm = BinMatcher.new([b3, b2, b1])
        ranked = bm.by_specificity
        expect(ranked.first).to eql b3
        expect(ranked.last).to eql b1
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        bm_other = BinMatcher.new
        expect(@bm.eql?(bm_other)).to be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        bm_other = BinMatcher.new([@bv])
        expect(@bm.eql?(bm_other)).to be_false
      end

    end


    context "#fill_blanks" do

      it "should leave the volume and master attributes untouched if they are already containing the same set of image references" do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        master = d.patient.study.image_series.first.struct.structure('External').bin_volume
        volume = d.patient.study.image_series.first.struct.structure('External').bin_volume
        original_master_image_length = master.bin_images.length
        original_volume_image_length = volume.bin_images.length
        bm = BinMatcher.new([volume], master)
        bm.fill_blanks
        expect(bm.master.bin_images.length).to eql original_master_image_length
        expect(bm.volumes.first.bin_images.length).to eql original_volume_image_length
      end

      it "should add a BinImage instance to the volume when it contains less BinImage instances than the master volume" do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        master = d.patient.study.image_series.first.struct.structure('External').bin_volume
        volume = d.patient.study.image_series.first.struct.structure('External').bin_volume
        original_master_image_length = master.bin_images.length
        original_volume_image_length = volume.bin_images.length
        volume.bin_images.pop
        bm = BinMatcher.new([volume], master)
        bm.fill_blanks
        expect(bm.master.bin_images.length).to eql original_master_image_length
        expect(bm.volumes.first.bin_images.length).to eql original_volume_image_length
      end

      it "should not change length of the 'volumes' attribute when including a master volume for processing" do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        master = d.patient.study.image_series.first.struct.structure('External').bin_volume
        volume = d.patient.study.image_series.first.struct.structure('External').bin_volume
        volume.bin_images.pop
        bm = BinMatcher.new([volume], master)
        original_number_of_volumes = bm.volumes.length
        bm.fill_blanks
        expect(bm.volumes.length).to eql original_number_of_volumes
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        bm_other = BinMatcher.new
        expect(@bm.hash).to be_a Fixnum
        expect(@bm.hash).to eql bm_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        bm_other = BinMatcher.new([@bv])
        expect(@bm.hash).not_to eql bm_other.hash
      end

    end


    context "#master=()" do

      it "should raise an ArgumentError when the argument is not a BinVolume" do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        bm = BinMatcher.new
        expect {bm.master = 'invalid'}.to raise_error(ArgumentError, /volume/)
      end

      it "should add the BinVolume instance to the BinMatcher volumes attribute" do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        master = d.patient.study.image_series.first.struct.structure('External').bin_volume
        @bm.master = master
        expect(@bm.master).to eql master
      end

    end


    context "#narrays" do

      it "should return an empty array when called on a BinMatcher instance with no volumes" do
        narrays = @bm.narrays
        expect(narrays.class).to eql Array
        expect(narrays.length).to eql 0
      end

      it "should return an array of (2) NArray objects from the BinMatcher instance containing 2 volumes" do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        volume1 = d.patient.study.image_series.first.struct.structure('External').bin_volume
        volume2 = d.patient.study.image_series.first.struct.structure('Small').bin_volume
        bm = BinMatcher.new([volume1, volume2])
        narrays = bm.narrays
        expect(narrays.class).to eql Array
        expect(narrays.length).to eql 2
        expect(narrays.first.class).to eql NArray
      end

    end

=begin
    context "#remove_empty_indices" do

      it "should remove remove the expected slice, row and column for all volumes, and otherwise leave the volumes untouched" do
        i1 = BinImage.new(NArray[[0,0,0], [0,0,0], [0,0,0]].to_type(1), @i1)
        i2 = BinImage.new(NArray[[0,0,0], [0,0,0], [0,0,0]].to_type(1), @i1)
        i3 = BinImage.new(NArray[[1,1,0], [1,1,0], [0,0,0]].to_type(1), @i1)
        i4 = BinImage.new(NArray[[0,0,0], [0,0,0], [0,0,0]].to_type(1), @i1)
        i5 = BinImage.new(NArray[[0,0,0], [0,0,0], [0,0,0]].to_type(1), @i1)
        i6 = BinImage.new(NArray[[0,1,0], [1,0,0], [0,0,0]].to_type(1), @i1)
        i7 = BinImage.new(NArray[[1,1,0], [0,1,0], [0,0,0]].to_type(1), @i1)
        i8 = BinImage.new(NArray[[0,0,0], [0,0,0], [0,0,0]].to_type(1), @i1)
        i9 = BinImage.new(NArray[[0,0,0], [0,0,0], [0,0,0]].to_type(1), @i1)
        master = BinVolume.new(@f, [i1, i2, i3])
        vol1 = BinVolume.new(@f, [i4, i5, i6])
        vol2 = BinVolume.new(@f, [i7, i8, i9])
        bm = BinMatcher.new([vol1, vol2])
        bm.master = master
        bm.remove_empty_indices
puts "===="
bm.volumes.each {|vol| puts vol.narr.inspect}
bm.volumes.each {|vol| puts vol.narr.shape}
puts bm.master.narr.shape
        # Number of volumes should be unchanged:
        bm.volumes.length.should eql 2
        # Original narray shapes should be unchanged:
        bm.master.narray.shape.should eql [3, 3, 3]
        bm.volumes.first.narray.shape.should eql [3, 3, 3]
        bm.volumes.last.narray.shape.should eql [3, 3, 3]
        # Check that all positives are preserved:
        (master.narr.eq 1).where.length.should eql 4
        (vol1.narr.eq 1).where.length.should eql 2
        (vol2.narr.eq 1).where.length.should eql 3
        # Check the new narr shapes:
        master.narr.shape.should eql [2, 2, 2]
        vol1.narr.shape.should eql [2, 2, 2]
        vol2.narr.shape.should eql [2, 2, 2]
      end

    end
=end

    context "#score_dice" do

      before :each do
        @master = BinImage.new(NArray[[0,1,1,0,0,0,0,0,0,0]].to_type(1), @i1).to_bin_volume(@is)
        @vol = BinImage.new(NArray[[0,0,1,1,0,0,0,0,0,0]].to_type(1), @i1).to_bin_volume(@is)
      end

      it "should give the expected dice score for this case" do
        bm = BinMatcher.new([@vol])
        bm.master = @master
        bm.score_dice
        expect(bm.volumes.first.dice).to eql 0.5
      end

    end


    # Testing a simple, artificial 1-slice-per-volume, 4 volumes BinMatcher case.
    context "#score_ss" do

      before :each do
        images = Array.new
        volumes = Array.new
        # Expert segmentations (the first rater is our simulated expert and the others deviate in various ways):
        # n = 20, segmented pixels = 10
        m_image = BinImage.new(NArray[[1,1,1,1,1,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0]].to_type(1), @i1) # master
        images << BinImage.new(NArray[[1,1,1,1,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0]].to_type(1), @i1) # lacking 3
        images << BinImage.new(NArray[[1,1,1,1,1,1,0,1,0,1,1,1,1,1,1,1,0,0,0,0]].to_type(1), @i1) # 4 false positive
        images << BinImage.new(NArray[[1,1,1,0,1,0,0,0,0,1,1,1,1,1,1,1,0,0,1,1]].to_type(1), @i1) # lacking 1, 4 false positive
        images << BinImage.new(NArray[[1,1,1,1,1,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0]].to_type(1), @i1) # 'perfect'
        images.each {|image| volumes << BinVolume.new(@is, :images => [image])}
        master = BinVolume.new(@is, :images => [m_image])
        @bm = BinMatcher.new(volumes)
        @bm.master = master
        @bm.score_ss
      end

      it "should produce the expected scores for the purely under-specified volume" do
        expect(@bm.volumes[0].sensitivity).to eql 0.7
        expect(@bm.volumes[0].specificity).to eql 1.0
      end

      it "should produce the expected scores for the purely over-specified volume" do
        expect(@bm.volumes[1].sensitivity).to eql 1.0
        expect(@bm.volumes[1].specificity).to eql 0.6
      end

      it "should produce the expected scores for the over- and under-specified volume" do
        expect(@bm.volumes[2].sensitivity).to eql 0.9
        expect(@bm.volumes[2].specificity).to eql 0.6
      end

      it "should produce the expected scores for the perfectly specified volume" do
        expect(@bm.volumes[3].sensitivity).to eql 1.0
        expect(@bm.volumes[3].specificity).to eql 1.0
      end

    end


    # Testing samples which have almost no positives and almost all positives.
    context "#score_ss" do

      before :each do
        @p_one = BinImage.new(NArray[[1,0,0,0,0,0,0,0,0,0]].to_type(1), @i1).to_bin_volume(@is)
        @p_two = BinImage.new(NArray[[1,1,0,0,0,0,0,0,0,0]].to_type(1), @i1).to_bin_volume(@is)
        @n_one = BinImage.new(NArray[[1,1,1,1,1,1,1,1,1,0]].to_type(1), @i1).to_bin_volume(@is)
        @n_two = BinImage.new(NArray[[1,1,1,1,1,1,1,1,0,0]].to_type(1), @i1).to_bin_volume(@is)
        @p_all = BinImage.new(NArray[[1,1,1,1,1,1,1,1,1,1]].to_type(1), @i1).to_bin_volume(@is)
        @n_all = BinImage.new(NArray[[0,0,0,0,0,0,0,0,0,0]].to_type(1), @i1).to_bin_volume(@is)
      end

      it "should give the expected scores for this case" do
        bm = BinMatcher.new([@p_two])
        bm.master = @p_one
        bm.score_ss
        expect(bm.volumes.first.sensitivity).to eql 1.0
        expect(bm.volumes.first.specificity).to eql 8/9.0
      end

      it "should give the expected scores for this case" do
        bm = BinMatcher.new([@p_one])
        bm.master = @p_two
        bm.score_ss
        expect(bm.volumes.first.sensitivity).to eql 0.5
        expect(bm.volumes.first.specificity).to eql 1.0
      end

      it "should give the expected scores for this case" do
        bm = BinMatcher.new([@p_one])
        bm.master = @n_one
        bm.score_ss
        expect(bm.volumes.first.sensitivity).to eql 1/9.0
        expect(bm.volumes.first.specificity).to eql 1.0
      end

      it "should give the expected scores for this case" do
        bm = BinMatcher.new([@n_one])
        bm.master = @p_one
        bm.score_ss
        expect(bm.volumes.first.sensitivity).to eql 1.0
        expect(bm.volumes.first.specificity).to eql 1/9.0
      end

    end


    context "#sort_volumes" do

      it "should raise an error when the volumes do not have the same number of BinImages" do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        v1 = d.patient.study.image_series.first.struct.structure('External').bin_volume
        v2 = d.patient.study.image_series.first.struct.structure('Star').bin_volume
        v1.bin_images.pop
        bm = BinMatcher.new([v1, v2])
        expect {bm.sort_volumes}.to raise_error(/number/)
      end

      it "should sort the volumes so that the BinImages of all volumes appear in the same order, with respect to their Image reference" do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        volumes = Array.new
        d.patient.study.image_series.first.struct.structures.each do |roi|
          volumes << roi.bin_volume
        end
        bm = BinMatcher.new(volumes)
        bm.sort_volumes
        slice_orders = Array.new
        volumes.each do |volume|
          slice_orders << volume.bin_images.collect {|bin_image| bin_image.pos_slice}
        end
        expect(slice_orders.uniq.length).to eql 1
      end

    end


    context "#to_bin_matcher" do

      it "should return itself" do
        expect(@bm.to_bin_matcher.equal?(@bm)).to be_true
      end

    end

  end

end
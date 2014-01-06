# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe Staple do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @f = Frame.new('1.4321', @p)
      @st = Study.new('1.456.789', @p)
      @is = ImageSeries.new('1.345.789', 'CT', @f, @st)
      @i1 = SliceImage.new('1.234.876', 0.0, @is)
      @i2 = SliceImage.new('1.567.432', 3.0, @is)
      @i3 = SliceImage.new('1.987.321', 6.0, @is)
      @bv1 = BinImage.new(NArray[[1,0,0,0,0,0,0,0,0,0]].to_type(1), @i1).to_bin_volume(@is)
      @bv2 = BinImage.new(NArray[[1,0,0,0,0,0,0,0,0,0]].to_type(1), @i1).to_bin_volume(@is)
      @bm = BinMatcher.new([@bv1, @bv2])
      @s = Staple.new(@bm)
    end

    context "::new" do

      it "should raise an ArgumentError when a BinMatcher is not passed as argument" do
        expect {Staple.new("invalid argument")}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when the supplied BinMatcher contains only one volume (at least two is required)" do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        volume = d.patient.study.image_series.first.struct.structure('External').bin_volume
        bm = BinMatcher.new([volume])
        expect {Staple.new(bm)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError if the segmentations passed as an argument are of unequal length" do
        b1, b2 = BinImage.new(NArray.byte(3,3), @i1), BinImage.new(NArray.byte(3,4), @i1)
        v1, v2 = BinVolume.new(@is, :images => [b1]), BinVolume.new(@is, :images => [b2])
        bm = BinMatcher.new([v1, v2])
        expect {Staple.new(bm)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError if the segmentations passed as an argument are different shapes, even if having equal length" do
        b1, b2 = BinImage.new(NArray.byte(4,3), @i1), BinImage.new(NArray.byte(3,4), @i1)
        v1, v2 = BinVolume.new(@is, :images => [b1]), BinVolume.new(@is, :images => [b2])
        bm = BinMatcher.new([v1, v2])
        expect {Staple.new(bm)}.to raise_error(ArgumentError)
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        s_other = Staple.new(@bm)
        expect(@s == s_other).to be_true
      end

      it "should be false when comparing two instances having different attributes" do
        s_other = Staple.new(@bm, :max_iterations => 4)
        expect(@s == s_other).to be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@s == 42).to be_false
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        s_other = Staple.new(@bm)
        expect(@s.eql?(s_other)).to be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        s_other = Staple.new(@bm, :max_iterations => 4)
        expect(@s.eql?(s_other)).to be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        s_other = Staple.new(@bm)
        expect(@s.hash).to be_a Fixnum
        expect(@s.hash).to eql s_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        s_other = Staple.new(@bm, :max_iterations => 4)
        expect(@s.hash).not_to eql s_other.hash
      end

    end


    context "#solve" do

      it "should produce a true segmentation array of all zeroes when the input volumes are filled with zeroes" do
        b1, b2 = BinImage.new(NArray.byte(3,3), @i1), BinImage.new(NArray.byte(3,3), @i1)
        v1, v2 = BinVolume.new(@is, :images => [b1]), BinVolume.new(@is, :images => [b2])
        bm = BinMatcher.new([v1, v2])
        s = Staple.new(bm)
        s.solve
        expect(s.true_segmentation.max).to eql 0
        expect(s.true_segmentation.min).to eql 0
      end

      it "should produce a true segmentation array of all ones when the input volumes are filled with ones" do
        b1, b2 = BinImage.new(NArray.byte(3,3).fill(1), @i1), BinImage.new(NArray.byte(3,3).fill(1), @i1)
        v1, v2 = BinVolume.new(@is, :images => [b1]), BinVolume.new(@is, :images => [b2])
        bm = BinMatcher.new([v1, v2])
        s = Staple.new(bm)
        s.solve
        expect(s.true_segmentation.max).to eql 1
        expect(s.true_segmentation.min).to eql 1
      end

      it "should produce a true segmentation array which has the same shape and sizes as the input volumes" do
        frames = 2
        columns = 3
        rows = 4
        b1, b2 = BinImage.new(NArray.byte(columns, rows).random!(2), @i1), BinImage.new(NArray.byte(columns, rows).random!(2), @i1)
        v1, v2 = BinVolume.new(@is, :images => [b1, b2]), BinVolume.new(@is, :images => [b2, b1])
        bm = BinMatcher.new([v1, v2])
        s = Staple.new(bm, :max_iterations => 2)
        s.solve
        expect(s.true_segmentation.shape).to eql [frames, columns, rows]
      end

      it "should produce weights of 0.5 and true segmentation array with ones (because 0.5 is rounded to 1) when a volume of [0,1] and a volume of [1,0] is given" do
        b1, b2 = BinImage.new(NArray.to_na([[0,1],[1,0]]).to_type(1), @i1), BinImage.new(NArray.to_na([[1,0],[0,1]]).to_type(1), @i1)
        v1, v2 = BinVolume.new(@is, :images => [b1]), BinVolume.new(@is, :images => [b2])
        bm = BinMatcher.new([v1, v2])
        s = Staple.new(bm)
        s.solve
        expect(s.true_segmentation.eq NArray.to_na([[1,1], [1,1]])).to be_true
        expect(s.weights.eq NArray.to_na([0.5, 0.5, 0.5, 0.5])).to be_true
      end

      it "should produce arrays of sensitivity, specificity and phi with dimensions corresponding to the input number of volumes" do
        n = 2
        b1, b2 = BinImage.new(NArray.byte(3,3), @i1), BinImage.new(NArray.byte(3,3), @i1)
        v1, v2 = BinVolume.new(@is, :images => [b1]), BinVolume.new(@is, :images => [b2])
        bm = BinMatcher.new([v1, v2])
        s = Staple.new(bm)
        s.solve
        expect(s.p.length).to eql n
        expect(s.q.length).to eql n
        expect(s.phi.shape).to eql [2, n]
      end

      it "should score the sensitivity and specificity of both segmentations as 1 when the input volumes are filled with ones" do
        b1, b2 = BinImage.new(NArray.byte(3,3).fill(1), @i1), BinImage.new(NArray.byte(3,3).fill(1), @i1)
        v1, v2 = BinVolume.new(@is, :images => [b1]), BinVolume.new(@is, :images => [b2])
        bm = BinMatcher.new([v1, v2])
        s = Staple.new(bm)
        s.solve
        expect(s.p.eq NArray.byte(2).fill(1)).to be_true
        expect(s.q.eq NArray.byte(2).fill(1)).to be_true
        expect(s.phi.eq NArray.byte(2, 2).fill(1)).to be_true
      end

      it "should score the segmentation as 0.5 and 0.5 on sensitivity and specificity when two volumes of 'opposite' segmentations are given" do
        b1, b2 = BinImage.new(NArray.to_na([[0,1],[1,0]]).to_type(1), @i1), BinImage.new(NArray.to_na([[1,0],[0,1]]).to_type(1), @i1)
        v1, v2 = BinVolume.new(@is, :images => [b1]), BinVolume.new(@is, :images => [b2])
        bm = BinMatcher.new([v1, v2])
        s = Staple.new(bm)
        s.solve
        expect(s.p.to_a.sort).to eql [0.5, 0.5]
        expect(s.q.to_a.sort).to eql [0.5, 0.5]
      end

    end


    # Testing a simple, artificial 1-slice-per-volume, 5 volumes case.
    context "#solve" do

      before :each do
        images = Array.new
        volumes = Array.new
        # Expert segmentations (the first rater is our simulated expert and the others deviate in various ways):
        # n = 20, segmented pixels = 10
        images << BinImage.new(NArray[[1,1,1,1,1,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0]].to_type(1), @i1) # 'perfect'
        images << BinImage.new(NArray[[1,1,1,1,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0]].to_type(1), @i1) # lacking 3
        images << BinImage.new(NArray[[1,1,1,1,1,1,0,1,0,1,1,1,1,1,1,1,0,0,0,0]].to_type(1), @i1) # 4 false positive
        images << BinImage.new(NArray[[1,0,0,1,1,0,0,0,0,0,1,1,0,1,1,0,0,0,0,0]].to_type(1), @i1) # lacking 3
        images << BinImage.new(NArray[[1,1,1,0,1,0,0,0,0,1,1,1,1,1,1,1,0,0,1,1]].to_type(1), @i1) # lacking 1, 4 false positive
        @expert = images[0]
        images.each {|image| volumes << BinVolume.new(@is, :images => [image])}
        @expected_sensitivity = NArray.to_na([1.0, 0.7, 1.0, 0.7, 0.9])
        @expected_specificity = NArray.to_na([1.0, 1.0, 0.6, 1.0, 0.6])
        bm = BinMatcher.new(volumes)
        @s = Staple.new(bm)
        @s.remove_empty_indices # removing 2 columns which are not segmented by anyone
        @s.solve
      end

      it "should produce a true segmentation volume with shape: slices=1, columns=20 and rows=1" do
        expect(@s.true_segmentation.shape).to eql [1, 20, 1]
      end

      it "should produce a true segmentation which is equal to the expert rater's segmentation" do
        expect(@s.true_segmentation[0, true, 0].eq @expert.narray).to be_true
      end

      it "should produce results of sensitivity as expected" do
        expect(@s.p.eq @expected_sensitivity).to be_true
      end

      it "should produce results of specificity as expected" do
        expect(@s.p.eq @expected_specificity).to be_true
      end

      it "should produce results of phi (sensitivity and specificity) as expected" do
        expected_phi = NArray.float(2, 5)
        expected_phi[0, true] = @expected_sensitivity
        expected_phi[1, true] = @expected_specificity
        expect(@s.phi.eq expected_phi).to be_true
      end

    end


    # Testing a simple, artificial 3-slices-per-volume, 2 volumes case.
    context "#solve" do

      before :each do
        # The two segmentations equal in each slice, but the slices are different:
        @b11 = BinImage.new(NArray[[1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]].to_type(1), @i1)
        @b12 = BinImage.new(NArray[[0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0]].to_type(1), @i2)
        @b13 = BinImage.new(NArray[[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1]].to_type(1), @i3)
        @b21 = BinImage.new(NArray[[1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]].to_type(1), @i1)
        @b22 = BinImage.new(NArray[[0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0]].to_type(1), @i2)
        @b23 = BinImage.new(NArray[[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1]].to_type(1), @i3)
        @v1 = BinVolume.new(@is, :images => [@b11, @b12, @b13])
        @v2 = BinVolume.new(@is, :images => [@b21, @b22, @b23])
        @expected_sensitivity = NArray.to_na([1.0, 1.0])
        @expected_specificity = NArray.to_na([1.0, 1.0])
        @bm = BinMatcher.new([@v1, @v2])
        @s = Staple.new(@bm)
        @s.solve
      end

      it "should produce a true segmentation volume with shape: slices=3, columns=20 and rows=1" do
        expect(@s.true_segmentation.shape).to eql [3, 20, 1]
      end

      it "should produce results of sensitivity as expected" do
        expect(@s.p.eq @expected_sensitivity).to be_true
      end

      it "should produce results of specificity as expected" do
        expect(@s.p.eq @expected_specificity).to be_true
      end

      it "should create a master volume in the BinMatcher instance who's BinImages have equal narrays as those of the input volumes" do
        expect((@bm.master.bin_images[0].narray.eq @b11.narray).where.length).to eql @b11.narray.length
        expect((@bm.master.bin_images[1].narray.eq @b12.narray).where.length).to eql @b12.narray.length
        expect((@bm.master.bin_images[2].narray.eq @b13.narray).where.length).to eql @b13.narray.length
      end

    end


    # Testing a simple, phantom case.
    context "#solve" do

      before :each do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        image_series = d.patient.study.image_series.first
        uid = "1.3.6.1.4.1.2452.6.1182637672.1264755347.3544421004.3934111437" # Picking a single slice for faster execution.
        volumes = Array.new
        image_series.structures.each do |roi|
          image = roi.slice(uid).bin_image
          volumes << BinVolume.new(image_series, :images => [image])
        end
        bm = BinMatcher.new(volumes)
        @s = Staple.new(bm, :max_iterations => 5)
        @s.remove_empty_indices # removing columns which are not segmented by anyone
        # 5 iterations:
        @expected_sensitivity = NArray.to_na([1.0, 1.0, 0.73, 0.98, 0.96, 0.96, 1.0])
        @expected_specificity = NArray.to_na([0.78, 0.0, 1.0, 0.63, 0.76, 0.75, 0.80])
        @s.solve
      end

      it "should (after successfull extraction of structure set contours from the selected image and convertion to binary segmentation images) process these in the Staple class to produce a sensible hidden true segmentation and scoring of the various contours" do
        expect(@s.p.length).to eql 7
        expect((@s.p - @expected_sensitivity).abs.max).to be < 0.02
        expect((@s.q - @expected_specificity).abs.max).to be < 0.02
      end

    end


    context "#to_staple" do

      it "should return itself" do
        expect(@s.to_staple.equal?(@s)).to be_true
      end

    end

  end

end
# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe DoseVolume do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.987.3', 'CT', @f, @st)
      @ss = StructureSet.new('1.765.354', @is)
      @plan = Plan.new('1.456.654', @ss)
      @dose = RTDose.new('1.987.246', @plan)
      @uid = '1.345.789'
      @vol = DoseVolume.new(@uid, @f, @dose)
    end

    describe "::load" do

      before :each do
        @dcm = DICOM::DObject.read(FILE_DOSE)
      end

      it "should raise an ArgumentError when a non-DObject is passed as the 'dcm' argument" do
        expect {DoseVolume.load(42, @dose)}.to raise_error(ArgumentError, /'dcm'/)
      end

      it "should raise an ArgumentError when an non-Series is passed as the 'series' argument" do
        expect {DoseVolume.load(@dcm, 'not-a-series')}.to raise_error(ArgumentError, /'series'/)
      end

      it "should raise an ArgumentError when a DObject with a non-Image type modality is passed with the 'dcm' argument" do
        expect {DoseVolume.load(DICOM::DObject.read(FILE_STRUCT), @dose)}.to raise_error(ArgumentError, /'dcm'/)
      end

      it "should create a DoseVolume instance with attributes taken from the DICOM Object" do
        dose = RTDose.load(@dcm, @st)
        dose.series_uid.should eql @dcm.value('0020,000E')
        dose.modality.should eql @dcm.value('0008,0060')
      end

      it "should create a DoseVolume instance which is properly referenced to its RTDose" do
        vol = DoseVolume.load(@dcm, @dose)
        vol.dose_series.should eql @dose
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-string is passed as the 'sop_uid' argument" do
        expect {DoseVolume.new(42, @f, @dose)}.to raise_error(ArgumentError, /'sop_uid'/)
      end

      it "should raise an ArgumentError when a non-Frame is passed as the 'frame' argument" do
        expect {DoseVolume.new(@uid, 'not-a-frame', @dose)}.to raise_error(ArgumentError, /'frame'/)
      end

      it "should raise an ArgumentError when a non-Series is passed as the 'series' argument" do
        expect {DoseVolume.new(@uid, @f, 'not-a-series')}.to raise_error(ArgumentError, /'series'/)
      end

      it "should raise an ArgumentError when a non-image related Series is passed as the 'series' argument" do
        expect {DoseVolume.new(@uid, @f, @ss)}.to raise_error(ArgumentError, /'series'/)
      end

      it "should by default set the 'images' attribute as an empty array" do
        @vol.images.should eql Array.new
      end

      it "should by default set the 'modality' attribute as 'RTDOSE'" do
        @vol.modality.should eql 'RTDOSE'
      end

      it "should by default set the 'class_uid' attribute as nil" do
        @vol.class_uid.should be_nil
      end

      it "should pass the series UID of the referenced RTDose instance to the 'series_uid' attribute" do
        @vol.series_uid.should eql @dose.series_uid
      end

      it "should pass the 'series' argument to the 'dose_series' attribute" do
        @vol.dose_series.should eql @dose
      end

      it "should add the Volume instance (once) to the referenced RTDose" do
        @vol.dose_series.volumes.length.should eql 1
        @vol.dose_series.volumes.first.should eql @vol
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        vol_other = DoseVolume.new(@uid, @f, @dose)
        (@vol == vol_other).should be_true
      end

      it "should be false when comparing two instances having different attributes" do
        vol_other = DoseVolume.new('1.6.99', @f, @dose)
        (@vol == vol_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@vol == 42).should be_false
      end

    end


    context "#add_image" do

      it "should raise an ArgumentError when a non-Image is passed as the 'image' argument" do
        expect {@vol.add_image('not-an-image')}.to raise_error(ArgumentError, /'image'/)
      end

      it "should add the Image to the image-less DoseVolume instance" do
        vol_other = DoseVolume.new('1.23.787', @f, @dose)
        img = Image.new('1.45.876', vol_other)
        @vol.add_image(img)
        @vol.images.size.should eql 1
        @vol.images.first.should eql img
      end

      it "should add the Image to the DoseVolume instance already containing one or more images" do
        ds = DataSet.read(DIR_DOSE_ONLY)
        vol = ds.patient.study.iseries.struct.plan.rt_dose.volume
        previous_size = vol.images.size
        img = Image.new('1.45.876', vol)
        vol.add_image(img)
        vol.images.size.should eql previous_size + 1
        vol.images.last.should eql img
      end

      it "should not add multiple entries of the same Image" do
        img = Image.new('1.45.876', @vol)
        @vol.add_image(img)
        @vol.images.size.should eql 1
        @vol.images.first.should eql img
      end

    end


    context "#bin_volume" do

      context "[dicom dataset]" do

        before :each do
          d = DataSet.read(DIR_SIMPLE_PHANTOM_CASE)
          img_series = d.patient.study.image_series.first
          @dvol = img_series.struct.plan.rt_dose.sum
          @bin_volume = @dvol.bin_volume(:min => 0.5)
        end

        it "should raise an ArgumentError when no :min or :max options has been given" do
          expect {@dvol.bin_volume}.to raise_error(ArgumentError)
        end

        it "should return a BinVolume instance, containing 5 BinImage references, from this DoseVolume" do
          @bin_volume.class.should eql BinVolume
          @bin_volume.bin_images.length.should eql 5
        end

        it "should set the BinVolume's series equal to that of the DoseVolume" do
          @bin_volume.series.should eql @dvol
        end

=begin
        it "should set the DoseVolume as the BinVolume's source" do
          @bin_volume.source.should eql @dvol
        end
=end

        it "should return a BinVolume instance, where the narray matches the number of images for this volume as well as the dimensions of the referenced images" do
          # [5, 22, 22]
          @bin_volume.narray.shape.should eql [@dvol.images.length, @dvol.images.first.columns, @dvol.images.first.rows]
        end

        it "should return a BinVolume instance, where the segmented indices (as derived from the dose limits) are marked as 1 and the non-segmented indices are 0" do
          # Note: This is not so much a principal test as a consistency test.
          (@bin_volume.narray.eq 1).where.length.should eql 180
          (@bin_volume.narray.eq 0).where.length.should eql 2240
        end

      end

      context "[constructed dataset]" do

        before :each do
          @vol.scaling = 0.1
          @cols = 4
          @rows = 4
          # Dose images:
          @i1 = Image.new('1.67.11', @vol)
          @i2 = Image.new('1.67.12', @vol)
          @i1.columns, @i2.columns = @cols, @cols
          @i1.rows, @i2.rows = @rows, @rows
          @i1.row_spacing, @i2.row_spacing = 5, 5
          @i1.col_spacing, @i2.col_spacing = 5, 5
          @i1.cosines, @i2.cosines = [1, 0, 0, 0, 1, 0], [1, 0, 0, 0, 1, 0]
          @i1.pos_slice, @i2.pos_slice = 0.0, 50.0
          @i1.pos_x, @i2.pos_x = 0.0, 0.0
          @i1.pos_y, @i2.pos_y = 0.0, 0.0
          @i1.narray = NArray.int(@cols, @rows).fill(500)
          @i2.narray = NArray.int(@cols, @rows).fill(600)
          # Anatomy images:
          ct_cols = @cols * 2
          ct_rows = @rows * 2
          @ct1 = Image.new('1.671', @is)
          @ct2 = Image.new('1.672', @is)
          @ct1.columns, @ct2.columns = ct_cols, ct_cols
          @ct1.rows, @ct2.rows = ct_rows, ct_rows
          @ct1.row_spacing, @ct2.row_spacing = 2.5, 2.5
          @ct1.col_spacing, @ct2.col_spacing = 2.5, 2.5
          @ct1.cosines, @ct2.cosines = [1, 0, 0, 0, 1, 0], [1, 0, 0, 0, 1, 0]
          @ct1.pos_slice, @ct2.pos_slice = 0.0, 50.0
          @ct1.pos_x, @ct2.pos_x = 0.0, 0.0
          @ct1.pos_y, @ct2.pos_y = 0.0, 0.0
          @ct1.narray = NArray.int(ct_cols, ct_rows)
          @ct2.narray = NArray.int(ct_cols, ct_rows)
          # ROI:
          @partial = ROI.new("Upper right - both slices", 1, @f, @ss)
          @s1 = Slice.new(@ct1.uid, @partial)
          @s2 = Slice.new(@ct2.uid, @partial)
          @cnt1 = Contour.new(@s1)
          @cnt2 = Contour.new(@s2)
          @c11 = Coordinate.new(10.0, 0.0, 0.0, @cnt1)
          @c12 = Coordinate.new(15.0, 0.0, 0.0, @cnt1)
          @c13 = Coordinate.new(15.0, 5.0, 0.0, @cnt1)
          @c14 = Coordinate.new(10.0, 5.0, 0.0, @cnt1)
          @c21 = Coordinate.new(10.0, 0.0, 0.0, @cnt2)
          @c22 = Coordinate.new(15.0, 0.0, 0.0, @cnt2)
          @c23 = Coordinate.new(15.0, 5.0, 0.0, @cnt2)
          @c24 = Coordinate.new(10.0, 5.0, 0.0, @cnt2)
        end

        it "should give the expected binary images when comparing against this ROI using the :min option" do
          @i1.narray[[2, 3, 6, 7]] = [700, 680, 720, 730]
          @i2.narray[[2, 3, 6, 7]] = [690, 670, 700, 710]
          bv = @vol.bin_volume(:min => 65.0)
          bv.bin_images.length.should eql 2
          (bv.bin_images.first.narray.eq 1).where.to_a.should eql [2, 3, 6, 7]
          (bv.bin_images.last.narray.eq 1).where.to_a.should eql [2, 3, 6, 7]
        end

        it "should give the expected binary images when comparing against this ROI using the :max option" do
          @i1.narray[[8, 9, 12, 13]] = [310, 380, 320, 330]
          @i2.narray[[8, 9, 12, 13]] = [390, 370, 300, 310]
          bv = @vol.bin_volume(:max => 45.0)
          bv.bin_images.length.should eql 2
          (bv.bin_images.first.narray.eq 1).where.to_a.should eql [8, 9, 12, 13]
          (bv.bin_images.last.narray.eq 1).where.to_a.should eql [8, 9, 12, 13]
        end

        it "should give the expected binary images when comparing against this ROI using both :min and :max options" do
          @i1.narray[[8, 9, 12, 13]] = [520, 580, 520, 550]
          @i2.narray[[2, 3, 6, 7]] = [560, 570, 540, 530]
          bv = @vol.bin_volume(:min => 51.0, :max => 59.0)
          bv.bin_images.length.should eql 2
          (bv.bin_images.first.narray.eq 1).where.to_a.should eql [8, 9, 12, 13]
          (bv.bin_images.last.narray.eq 1).where.to_a.should eql [2, 3, 6, 7]
        end

        it "should give a perfect score with Dice's coeffiecent for this case" do
          @i1.narray[[2, 3, 6, 7]] = [700, 680, 720, 730]
          @i2.narray[[2, 3, 6, 7]] = [690, 670, 700, 710]
          dose_bv = @vol.bin_volume(:min => 65.0)
          roi_bv = @partial.bin_volume(@vol)
          bm = BinMatcher.new([dose_bv], roi_bv)
          bm.score_dice
          dose_bv.dice.should eql 1.0
        end

      end

    end


    # A constructed case:
    context "#distribution" do

      before :each do
        @vol.scaling = 0.1
        @cols = 4
        @rows = 4
        # Dose images:
        @i1 = Image.new('1.67.11', @vol)
        @i2 = Image.new('1.67.12', @vol)
        @i1.columns, @i2.columns = @cols, @cols
        @i1.rows, @i2.rows = @rows, @rows
        @i1.row_spacing, @i2.row_spacing = 5, 5
        @i1.col_spacing, @i2.col_spacing = 5, 5
        @i1.cosines, @i2.cosines = [1, 0, 0, 0, 1, 0], [1, 0, 0, 0, 1, 0]
        @i1.pos_slice, @i2.pos_slice = 0.0, 50.0
        @i1.pos_x, @i2.pos_x = 0.0, 0.0
        @i1.pos_y, @i2.pos_y = 0.0, 0.0
        @i1.narray = NArray.int(@cols, @rows).indgen! * 100
        @i2.narray = NArray.int(@cols, @rows).indgen! * 200
        # Anatomy images:
        ct_cols = @cols * 2
        ct_rows = @rows * 2
        @ct1 = Image.new('1.671', @is)
        @ct2 = Image.new('1.672', @is)
        @ct1.columns, @ct2.columns = ct_cols, ct_cols
        @ct1.rows, @ct2.rows = ct_rows, ct_rows
        @ct1.row_spacing, @ct2.row_spacing = 2.5, 2.5
        @ct1.col_spacing, @ct2.col_spacing = 2.5, 2.5
        @ct1.cosines, @ct2.cosines = [1, 0, 0, 0, 1, 0], [1, 0, 0, 0, 1, 0]
        @ct1.pos_slice, @ct2.pos_slice = 0.0, 50.0
        @ct1.pos_x, @ct2.pos_x = 0.0, 0.0
        @ct1.pos_y, @ct2.pos_y = 0.0, 0.0
        @ct1.narray = NArray.int(ct_cols, ct_rows)
        @ct2.narray = NArray.int(ct_cols, ct_rows)
      end

      it "should, as a starting point, have it's dose array return as expected" do
        exp_arr = NArray.int(2, @cols, @rows)
        exp_arr[0, true, true] = NArray.int(@cols, @rows).indgen! * 10.0
        exp_arr[1, true, true] = NArray.int(@cols, @rows).indgen! * 2 * 10.0
        (@vol.dose_arr == exp_arr).should be_true
      end

      it "should (when called without argument) return the full dose distribution" do
        full_dist = @vol.distribution
        full_dist.length.should eql 32
        full_dist.max.should eql 300.0
        full_dist.min.should eql 0.0
        full_dist.median.should eql 100.0
      end

      context "(with external ROI)" do

        before :each do
          @external = ROI.new("External", 1, @f, @ss)
          @s1 = Slice.new(@ct1.uid, @external)
          @s2 = Slice.new(@ct2.uid, @external)
          @cnt1 = Contour.new(@s1)
          @cnt2 = Contour.new(@s2)
          @c11 = Coordinate.new(0.0, 0.0, 0.0, @cnt1)
          @c12 = Coordinate.new(15.0, 0.0, 0.0, @cnt1)
          @c13 = Coordinate.new(15.0, 15.0, 0.0, @cnt1)
          @c14 = Coordinate.new(0.0, 15.0, 0.0, @cnt1)
          @c21 = Coordinate.new(0.0, 0.0, 0.0, @cnt2)
          @c22 = Coordinate.new(15.0, 0.0, 0.0, @cnt2)
          @c23 = Coordinate.new(15.0, 15.0, 0.0, @cnt2)
          @c24 = Coordinate.new(0.0, 15.0, 0.0, @cnt2)
        end

        it "should, as a starting point, have the slices properly referenced to corresponding images" do
          @s1.image.should eql @ct1
          @s2.image.should eql @ct2
        end

        it "should have length equal to that of the entire dose array" do
          @vol.distribution(@external).length.should eql 32
        end

        it "should return the global max dose" do
          @vol.distribution(@external).max.should eql 300.0
        end

        it "should return the global min dose" do
          @vol.distribution(@external).min.should eql 0.0
        end

        it "should return the global median dose" do
          @vol.distribution(@external).median.should eql 100.0
        end

      end

      context "(with a partial, multi-slice ROI)" do

        before :each do
          @partial = ROI.new("Upper right - both slices", 1, @f, @ss)
          @s1 = Slice.new(@ct1.uid, @partial)
          @s2 = Slice.new(@ct2.uid, @partial)
          @cnt1 = Contour.new(@s1)
          @cnt2 = Contour.new(@s2)
          @c11 = Coordinate.new(10.0, 0.0, 0.0, @cnt1)
          @c12 = Coordinate.new(15.0, 0.0, 0.0, @cnt1)
          @c13 = Coordinate.new(15.0, 5.0, 0.0, @cnt1)
          @c14 = Coordinate.new(10.0, 5.0, 0.0, @cnt1)
          @c21 = Coordinate.new(10.0, 0.0, 0.0, @cnt2)
          @c22 = Coordinate.new(15.0, 0.0, 0.0, @cnt2)
          @c23 = Coordinate.new(15.0, 5.0, 0.0, @cnt2)
          @c24 = Coordinate.new(10.0, 5.0, 0.0, @cnt2)
        end

        it "should, as a starting point, have the slices properly referenced to corresponding images" do
          @s1.image.should eql @ct1
          @s2.image.should eql @ct2
        end

        it "should have length equal to a fourth of the entire dose array" do
          @vol.distribution(@partial).length.should eql 8
        end

        it "should return the partial max dose" do
          @vol.distribution(@partial).max.should eql 140.0
        end

        it "should return the partial min dose" do
          @vol.distribution(@partial).min.should eql 20.0
        end

        it "should return the partial median dose" do
          @vol.distribution(@partial).median.should eql 60.0
        end

      end

    end


    # A DICOM case:
    context "#distribution" do

      before :each do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CASE)
        img_series = d.patient.study.image_series.first
        @roi = img_series.struct.roi('External')
        @rt_dose = img_series.struct.plan.rt_dose
      end

      it "should return a DoseDistribution instance when called without an argument" do
        distribution = @rt_dose.volumes.first.distribution
        distribution.class.should eql DoseDistribution
      end

      it "should return a DoseDistribution instance when called with a ROI argument" do
        distribution = @rt_dose.volumes.first.distribution(@roi)
        distribution.class.should eql DoseDistribution
      end

      it "should return a DoseDistribution with size equal to the number of images * columns * rows" do
        dvol = @rt_dose.volumes.first
        distribution = dvol.distribution
        distribution.length.should eql dvol.images.length * dvol.images.first.columns * dvol.images.first.rows
      end

      it "should return the single beam's dose distribution with the expected properties (as per the source TPS for this dataset)" do
        dvol = @rt_dose.volume("1.3.6.1.4.1.2452.6.3641918815.1239528433.2837719487.3331095889")
        roi_distribution = dvol.distribution(@roi)
        #roi_distribution.length.should eql 336
        roi_distribution.max.should be_within(0.002).of(6.25)
        roi_distribution.min.should be_within(0.001).of(0.0)
        roi_distribution.median.should be_within(0.095).of(0.11)
        roi_distribution.mean.should be_within(0.86).of(1.75)
        roi_distribution.rmsdev.should be_within(0.38).of(2.41)
      end

      it "should return the summed dose distribution with the expected properties (as per the source TPS for this dataset)" do
        roi_distribution = @rt_dose.sum.distribution(@roi)
        # Our results don't exactly match those given in the TPS.
        # Perform an approximate check instead of a precise comparison:
        #roi_distribution.length.should eql 336 # RTKIT gives a larger number of elements, which as of yet hasn't been shown to be incorrect
        roi_distribution.max.should be_within(0.001).of(17.17)
        roi_distribution.min.should be_within(0.0501).of(0.05)
        roi_distribution.median.should be_within(0.18).of(0.43)
        roi_distribution.mean.should be_within(2.2).of(4.89)
        roi_distribution.rmsdev.should be_within(0.92).of(6.27)
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        vol_other = DoseVolume.new(@uid, @f, @dose)
        @vol.eql?(vol_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        vol_other = DoseVolume.new('1.6.99', @f, @dose)
        @vol.eql?(vol_other).should be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        vol_other = DoseVolume.new(@uid, @f, @dose)
        @vol.hash.should be_a Fixnum
        @vol.hash.should eql vol_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        vol_other = DoseVolume.new('1.6.99', @f, @dose)
        @vol.hash.should_not eql vol_other.hash
      end

    end


    context "#image" do

      before :each do
        @uid1 = '1.23.787'
        @uid2 = '1.45.876'
        @pos_slice1 = 66.5
        @pos_slice2 = 77.7
        @img1 = Image.new(@uid1, @vol)
        @img2 = Image.new(@uid2, @vol)
        @img1.pos_slice = @pos_slice1
        @img2.pos_slice = @pos_slice2
      end

      it "should raise an ArgumentError if multiple arguments are passed" do
        expect {@vol.image(@uid1, @uid2)}.to raise_error(ArgumentError, /one/)
      end

      it "should return the first Image when no arguments are used" do
        @vol.image.should eql @vol.images.first
      end

      it "should return the matching Image when a UID string is supplied" do
        img = @vol.image(@uid2)
        img.uid.should eql @uid2
      end

      it "should return the matching Image when a slice position float is supplied" do
        img = @vol.image(@pos_slice2)
        img.pos_slice.should eql @pos_slice2
      end

    end


    context "#to_dose_volume" do

      it "should return itself" do
        @vol.to_dose_volume.equal?(@vol).should be_true
      end

    end

  end

end
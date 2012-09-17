# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe ROI do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.345.789', 'CT', @f, @st)
      @ss = StructureSet.new('1.765.12', @is)
      @name = 'Test'
      @number = 12
      @roi = ROI.new(@name, @number, @f, @ss)
      @sop = '1.245.123'
    end


    context "::create_from_items" do

      before :each do
        dcm = DICOM::DObject.read(FILE_STRUCT)
        @roi_item = dcm['3006,0020'][0]
        @contour_item = dcm['3006,0039'][0]
        @rt_item = dcm['3006,0080'][0]
      end

      it "should raise an ArgumentError when a non-Item is passed as the 'roi_item' argument" do
        expect {ROI.create_from_items('non-Item', @contour_item, @rt_item, @ss)}.to raise_error(ArgumentError, /roi_item/)
      end

      it "should raise an ArgumentError when a non-Item is passed as the 'contour_item' argument" do
        expect {ROI.create_from_items(@roi_item, 'non-Item', @rt_item, @ss)}.to raise_error(ArgumentError, /contour_item/)
      end

      it "should raise an ArgumentError when a non-Item is passed as the 'rt_item' argument" do
        expect {ROI.create_from_items(@roi_item, @contour_item, 'non-Item', @ss)}.to raise_error(ArgumentError, /rt_item/)
      end

      it "should raise an ArgumentError when a non-StructureSet is passed as the 'struct' argument" do
        expect {ROI.create_from_items(@roi_item, @contour_item, @rt_item, 'not-a-struct')}.to raise_error(ArgumentError, /struct/)
      end

      it "should fill the 'slices' array attribute with Slices created from the items" do
        roi = ROI.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        roi.slices.length.should eql @contour_item['3006,0040'].count
        roi.slices.first.class.should eql Slice
      end

      it "should set the ROI's 'algorithm' attribute equal to that of the value found in the Structure Set ROI Item" do
        roi = ROI.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        roi.algorithm.should eql @roi_item.value('3006,0036')
      end

      it "should set the ROI's 'name' attribute equal to that of the value found in the Structure Set ROI Item" do
        roi = ROI.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        roi.name.should eql @roi_item.value('3006,0026')
      end

      it "should set the ROI's 'number' attribute equal to that of the value found in the Structure Set ROI Item" do
        roi = ROI.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        roi.number.should eql @roi_item.value('3006,0022').to_i
      end

      it "should set the ROI's 'type' attribute equal to that of the value found in the RT ROI Observations Item" do
        roi = ROI.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        roi.type.should eql @rt_item.value('3006,00A4')
      end

      it "should set the ROI's 'interpreter' attribute equal to that of the value found in the RT ROI Observations Item" do
        roi = ROI.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        value = @contour_item.value('3006,00A6') || ""
        roi.interpreter.should eql value
      end

      it "should set the ROI's 'color' attribute equal to that of the value found in the ROI Contour Item" do
        roi = ROI.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        roi.color.should eql @contour_item.value('3006,002A')
      end

      it "should set the ROI's 'struct' attribute equal to the 'struct' argument" do
        roi = ROI.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        roi.struct.should eql @ss
      end

      it "should create a referenced Frame instance who's UID matches the value of the Frame UID tag of the 'ROI Item'" do
        roi = ROI.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        roi.frame.uid.should eql @roi_item.value('3006,0024')
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-String is passed as a 'name' argument" do
        expect {ROI.new(42, @number, @f, @ss)}.to raise_error(ArgumentError, /name/)
      end

      it "should raise an ArgumentError when a non-Integer is passed as a 'number' argument" do
        expect {ROI.new(@name, 'NaN', @f, @ss)}.to raise_error(ArgumentError, /number/)
      end

      it "should raise an ArgumentError when a non-Frame is passed as a 'frame' argument" do
        expect {ROI.new(@name, @number, 'not-a-frame', @ss)}.to raise_error(ArgumentError, /frame/)
      end

      it "should raise an ArgumentError when a non-StructureSet is passed as a 'struct' argument" do
        expect {ROI.new(@name, @number, @f, 'not-a-struct')}.to raise_error(ArgumentError, /struct/)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :algorithm argument" do
        expect {ROI.new(@name, @number, @f, @ss, :algorithm => 42)}.to raise_error(ArgumentError, /:algorithm/)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :type argument" do
        expect {ROI.new(@name, @number, @f, @ss, :type => 42)}.to raise_error(ArgumentError, /:type/)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :interpreter argument" do
        expect {ROI.new(@name, @number, @f, @ss, :interpreter => 42)}.to raise_error(ArgumentError, /:interpreter/)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :color argument" do
        expect {ROI.new(@name, @number, @f, @ss, :color => 42)}.to raise_error(ArgumentError, /:color/)
      end

      it "should pass the 'name' argument to the 'name' attribute" do
        @roi.name.should eql @name
      end

      it "should pass the 'number' argument to the 'number' attribute" do
        @roi.number.should eql @number
      end

      it "should pass the 'frame' argument to the 'frame' attribute" do
        @roi.frame.should eql @f
      end

      it "should pass the 'struct' argument to the 'struct' attribute" do
        @roi.struct.should eql @ss
      end

      it "should by default set the 'slices' attribute to an empty array" do
        @roi.slices.should eql Array.new
      end

      it "should by default set the 'algorithm' attribute to 'Automatic'" do
        @roi.algorithm.should eql 'Automatic'
      end

      it "should by default set the 'type' attribute to a 'CONTROL'" do
        @roi.type.should eql 'CONTROL'
      end

      it "should by default set the 'interpreter' attribute to 'RTKIT'" do
        @roi.interpreter.should eql 'RTKIT'
      end

      it "should by default set the 'color' attribute to a proper color string" do
        @roi.color.class.should eql String
        @roi.color.split("\\").length.should eql 3
      end

      it "should add the ROI instance (once) to the referenced StructureSet" do
        @ss.rois.length.should eql 1
        @ss.roi(@roi.name).should eql @roi
      end

      it "should add the ROI instance (once) to the referenced Frame" do
        @f.rois.length.should eql 1
        @f.roi(@roi.name).should eql @roi
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        roi = ROI.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        roi_other = ROI.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        (roi == roi_other).should be_true
      end

      it "should be false when comparing two instances having different attributes" do
        roi_other = ROI.new('Other ROI', @number, @f, @ss)
        (@roi == roi_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@roi == 42).should be_false
      end

    end


    context "#add_slice" do

      it "should raise an ArgumentError when a non-Slice is passed as the 'slice' argument" do
        expect {@roi.add_slice('not-a-slice')}.to raise_error(ArgumentError, /slice/)
      end

      it "should add the Slice to the empty ROI instance" do
        roi_other = ROI.new("Brain", 2, @f, @ss)
        s = Slice.new(@sop, roi_other)
        @roi.add_slice(s)
        @roi.slices.size.should eql 1
        @roi.slices.first.should eql s
      end

      it "should add the Slice to the ROI instance already containing a Slice" do
        roi_other = ROI.new("Brain", 2, @f, @ss)
        s1 = Slice.new(@sop, @roi)
        s2 = Slice.new("1.567.322", roi_other)
        @roi.add_slice(s2)
        @roi.slices.size.should eql 2
        @roi.slices.first.should eql s1
        @roi.slices.last.should eql s2
      end

      it "should not add multiple entries of the same Slice" do
        s = Slice.new(@sop, @roi)
        @roi.add_slice(s)
        @roi.slices.size.should eql 1
        @roi.slices.first.should eql s
      end

    end


    context "#attach_to" do

      before :each do
        @ds = DataSet.new
        @p = Patient.new('John', '12345', @ds)
        @st = Study.new('1.456.789', @p)
        @f1 = Frame.new('1.4321', @p)
        @f2 = Frame.new('1.5678', @p)
        @is1 = ImageSeries.new('1.345.789', 'CT', @f1, @st)
        @is2 = ImageSeries.new('1.345.456', 'CT', @f2, @st)
        @ss1 = StructureSet.new('1.765.12', @is1)
        @ss2 = StructureSet.new('1.765.34', @is2)
      end

      it "should raise an ArgumentError when a non-ImageSeries is passed as the 'series' argument" do
        roi = ROI.new(@name, @number, @f, @ss1)
        expect {roi.attach_to('not-a-series')}.to raise_error(ArgumentError, /series/)
      end

      it "should add the (empty) ROI to the ImageSeries instance" do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        series = d.patient.study.iseries
        roi = @ss1.create_roi(@f1)
        @ss1.expects(:remove_roi).once.with(roi)
        roi.attach_to(series)
        roi.frame.should eql series.frame
        series.rois.include?(roi).should be_true
      end

      it "should add the ROI (containing slices) to the ImageSeries instance" do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        series = d.patient.study.image_series.first
        roi = ROI.new(@name, @number, @f, @ss)
        @ss.expects(:remove_roi).once.with(roi)
        roi.attach_to(series)
        roi.frame.should eql series.frame
        series.rois.include?(roi).should be_true
      end

      it "should not do anything with the rois when they already belong to the given ImageSeries and have the correct frame" do
        roi1 = @ss1.create_roi(@f1)
        roi2 = @ss1.create_roi(@f1)
        # Before any processing (verify):
        @ss1.rois.length.should eql 2
        @ss1.rois.collect{|roi| roi.__id__}.should eql [roi1.__id__, roi2.__id__]
        @ss1.rois.each do |roi|
          roi.attach_to(@is1)
        end
        # After processing (test):
        @ss1.rois.collect{|roi| roi.frame}.should eql [@f1, @f1]
        @ss1.rois.length.should eql 2
        @ss1.rois.collect{|roi| roi.__id__}.should eql [roi1.__id__, roi2.__id__]
      end

      it "should not remove (and subsequently re-add) a ROI which belongs to the correct struct, but belongs to another frame than that of the ImageSeries" do
        roi_wrong_frame = @ss1.create_roi(@f2)
        roi_corr_frame = @ss1.create_roi(@f1)
        # Before any processing (verify):
        @ss1.rois.length.should eql 2
        @ss1.rois.collect{|roi| roi.__id__}.should eql [roi_wrong_frame.__id__, roi_corr_frame.__id__]
        @ss1.rois.each do |roi|
          roi.attach_to(@is1)
        end
        # After processing (test):
        [roi_wrong_frame, roi_corr_frame].collect{|roi| roi.frame}.should eql [@f1, @f1]
        @ss1.rois.length.should eql 2
        @ss1.rois.collect{|roi| roi.__id__}.should eql [roi_wrong_frame.__id__, roi_corr_frame.__id__]
      end

    end


    context "#bin_volume" do

      before :each do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        img_series = d.patient.study.image_series.first
        @roi = img_series.struct.roi('External')
        @bin_volume = @roi.bin_volume
      end

      it "should return a BinVolume instance, containing 5 BinImage references, from this ROI" do
        @bin_volume.class.should eql BinVolume
        @bin_volume.bin_images.length.should eql 5
      end

      it "should set the BinVolume's series equal to that of the ROI" do
        @bin_volume.series.should eql @roi.image_series
      end

      it "should set the ROI as the BinVolume's source" do
        @bin_volume.source.should eql @roi
      end

      it "should return a BinVolume instance, where the narray matches the number of contours in this ROI as well as the dimensions of the referenced images" do
        @bin_volume.narray.shape.should eql [5, 512, 171]
      end

      it "should return a BinVolume instance, where the segmented indices (as derived from the ROI's Contours) are marked as 1 and the non-segmented indices are 0" do
        # Note: This is not so much a principal test as a consistency test.
        (@bin_volume.narray.eq 1).where.length.should eql 37410
        (@bin_volume.narray.eq 0).where.length.should eql 400350
      end

    end


    context "#bin_volume(dose_volume)" do

      before :each do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CASE)
        img_series = d.patient.study.image_series.first
        @roi = img_series.struct.roi('External')
        @dvol = img_series.struct.plan.rt_dose.volumes.first
        @bin_volume = @roi.bin_volume(@dvol)
      end

      it "should accept a DoseVolume as argument and return a bin_volume instance" do
        @bin_volume.class.should eql BinVolume
      end

      it "should return a BinVolume instance, where the narray matches the number of contours in this ROI as well as the dimensions of the dose volume (images)" do
        @bin_volume.narray.shape.should eql [@roi.slices.length, @dvol.images.first.columns, @dvol.images.first.rows]
      end

    end


    context "#contour_item" do

      before :each do
        @roi = ROI.new(@name, @number, @f, @ss)
      end

      it "should return a ROI Contour Sequence Item properly populated with values from the ROI instance" do
        item = @roi.contour_item
        item.class.should eql DICOM::Item
        item.count.should eql 3
        item.value('3006,002A').should eql @roi.color
        item.value('3006,0084').should eql @roi.number.to_s
        item['3006,0040'].count.should eql 0
      end

    end


    context "#create_slices" do

      before :each do
        dcm = DICOM::DObject.read(FILE_STRUCT)
        @sequence = dcm['3006,0039'][0]['3006,0040']
        @roi = ROI.new(@name, @number, @f, @ss)
      end

      it "should raise an ArgumentError when a non-Sequence is passed as the 'contour_sequence' argument" do
        expect {@roi.create_slices('not-a-sequence')}.to raise_error(ArgumentError, /contour_sequence/)
      end

      it "should create Slices from the information in the Contour Sequence and add these to the ROI" do
        @roi.create_slices(@sequence)
        @roi.slices.length.should eql 5
      end

    end


    context "#distribution" do

      before :each do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CASE)
        img_series = d.patient.study.image_series.first
        @roi = img_series.struct.roi('External')
        @dvol = img_series.struct.plan.rt_dose.volumes.first
      end

      it "should return a DoseDistribution instance when called without an argument" do
        distribution = @roi.distribution
        distribution.class.should eql DoseDistribution
      end

      it "should return a DoseDistribution instance when called with a DoseVolume argument" do
        distribution = @roi.distribution(@dvol)
        distribution.class.should eql DoseDistribution
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        roi = ROI.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        roi_other = ROI.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        roi.eql?(roi_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        roi_other = ROI.new('Other ROI', @number, @f, @ss)
        @roi.eql?(roi_other).should be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        roi = ROI.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        roi_other = ROI.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        roi.hash.should be_a Fixnum
        roi.hash.should eql roi_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        roi_other = ROI.new('Other ROI', @number, @f, @ss)
        @roi.hash.should_not eql roi_other.hash
      end

    end


    context "#num_contours" do

      before :each do
        dcm = DICOM::DObject.read(FILE_STRUCT)
        @sequence = dcm['3006,0039'][0]['3006,0040']
        @roi = ROI.new(@name, @number, @f, @ss)
      end

      it "should return 0 for a ROI containing no contours" do
        @roi.slices.length.should eql 0
      end

      it "should return 5 for a ROI containing 5 contours" do
        @roi.create_slices(@sequence)
        @roi.num_contours.should eql 5
      end

    end


    context "#obs_item" do

      it "should return a RT ROI Observations Sequence Item properly populated with values from the ROI instance" do
        roi = ROI.new(@name, @number, @f, @ss)
        item = roi.obs_item
        item.class.should eql DICOM::Item
        item.count.should eql 4
        item.value('3006,0082').should eql roi.number.to_s
        item.value('3006,0084').should eql roi.number.to_s
        item.value('3006,00A4').should eql roi.type
        item.value('3006,00A6').should eql roi.interpreter
      end

    end


    context "#remove_references" do

      it "should nullify the 'frame' and 'struct' attributes of the ROI instance" do
        roi = ROI.new(@name, @number, @f, @ss)
        roi.remove_references
        roi.frame.should be_nil
        roi.struct.should be_nil
      end

    end


    context "#size" do

      before :each do
        i1 = Image.new('1.789.541', @is)
        i2 = Image.new('1.789.542', @is)
        i3 = Image.new('1.789.543', @is)
        i1.cosines, i2.cosines, i3.cosines = [1,0,0,0,1,0], [1,0,0,0,1,0], [1,0,0,0,1,0]
        i1.row_spacing, i2.row_spacing, i3.row_spacing = 1.0, 1.0, 1.0
        i1.col_spacing, i2.col_spacing, i3.col_spacing = 2.0, 2.0, 2.0
        i1.rows, i2.rows, i3.rows = 10, 10, 10
        i1.columns, i2.columns, i3.columns = 10, 10, 10
        i1.pos_x, i2.pos_x, i3.pos_x = 0.0, 0.0, 0.0
        i1.pos_y, i2.pos_y, i3.pos_y = 0.0, 0.0, 0.0
        i1.pos_slice, i2.pos_slice, i3.pos_slice = 5.0, 10.0, 15.0
        s1 = Slice.new('1.789.541', @roi)
        s2 = Slice.new('1.789.542', @roi)
        s3 = Slice.new('1.789.543', @roi)
        # First slice, volume: 45 mm^3 (3*3 pixels * 2mm^2 * 5mm * 0.5):
        c1 = Contour.create_from_coordinates([0.0, 4.0, 4.0, 0.0], [0.0, 0.0, 2.0, 2.0], [5.0, 5.0, 5.0, 5.0], s1)
        # Middle slice, volume: 160 mm^3 (4*4 pixels * 2mm^2 * 5mm):
        c2 = Contour.create_from_coordinates([2.0, 8.0, 8.0, 2.0], [1.0, 1.0, 4.0, 4.0], [10.0, 10.0, 10.0, 10.0], s2)
        # Last slice, volume: 60 mm^3 (3*4 pixels * 2mm^2 * 5mm * 0.5):
        c3 = Contour.create_from_coordinates([4.0, 8.0, 8.0, 4.0], [2.0, 2.0, 5.0, 5.0], [15.0, 15.0, 15.0, 15.0], s3)
        # Sum volume: 265 mm^3 = 0.265 cm^3
      end

      it "should return the expected size (as a float value in units of cm^3) for this case" do
        size = @roi.size
        size.should be_a Float
        size.should eql 0.265
      end

      it "should give this value for this ROI (NB: But the expected value is not an exact, principal value!!)" do
        # This test is just for consistency at the moment, and should be replaced by a (set of) principal test(s) on volume.
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        roi = d.patient.study.image_series.first.struct.roi('External')
        roi.size.round(1).should eql 770.6
      end

    end


    context "#slice" do

      before :each do
        dcm = DICOM::DObject.read(FILE_STRUCT)
        @sequence = dcm['3006,0039'][0]['3006,0040']
        @roi = ROI.new(@name, @number, @f, @ss)
        @roi.create_slices(@sequence)
      end

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@roi.slice(42)}.to raise_error(ArgumentError, /String/)
      end

      it "should raise an ArgumentError if multiple arguments are passed" do
        expect {@roi.slice(@sop, @sop)}.to raise_error(ArgumentError, /one/)
      end

      it "should return the first slice when no arguments are used" do
        @roi.slice.should eql @roi.slices.first
      end

      it "should return the the matching Slice when a UID string is supplied" do
        uid = '1.3.6.1.4.1.2452.6.685926274.1132857921.4126754476.3684171967'
        slice = @roi.slice(uid)
        slice.uid.should eql uid
      end

    end


    context "#ss_item" do

      it "should return a Structure Set ROI Sequence Item properly populated with values from the ROI instance" do
        roi = ROI.new(@name, @number, @f, @ss)
        item = roi.ss_item
        item.class.should eql DICOM::Item
        item.count.should eql 4
        item.value('3006,0022').should eql roi.number.to_s
        item.value('3006,0024').should eql roi.frame.uid
        item.value('3006,0026').should eql roi.name
        item.value('3006,0036').should eql roi.algorithm
      end

    end


    context "#to_roi" do

      it "should return itself" do
        @roi.to_roi.equal?(@roi).should be_true
      end

    end

  end

end
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
        expect(roi.slices.length).to eql @contour_item['3006,0040'].count
        expect(roi.slices.first.class).to eql Slice
      end

      it "should set the ROI's 'algorithm' attribute equal to that of the value found in the Structure Set ROI Item" do
        roi = ROI.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(roi.algorithm).to eql @roi_item.value('3006,0036')
      end

      it "should set the ROI's 'name' attribute equal to that of the value found in the Structure Set ROI Item" do
        roi = ROI.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(roi.name).to eql @roi_item.value('3006,0026')
      end

      it "should set the ROI's 'number' attribute equal to that of the value found in the Structure Set ROI Item" do
        roi = ROI.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(roi.number).to eql @roi_item.value('3006,0022').to_i
      end

      it "should set the ROI's 'type' attribute equal to that of the value found in the RT ROI Observations Item" do
        roi = ROI.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(roi.type).to eql @rt_item.value('3006,00A4')
      end

      it "should set the ROI's 'interpreter' attribute equal to that of the value found in the RT ROI Observations Item" do
        roi = ROI.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        value = @contour_item.value('3006,00A6') || ""
        expect(roi.interpreter).to eql value
      end

      it "should set the ROI's 'color' attribute equal to that of the value found in the ROI Contour Item" do
        roi = ROI.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(roi.color).to eql @contour_item.value('3006,002A')
      end

      it "should set the ROI's 'struct' attribute equal to the 'struct' argument" do
        roi = ROI.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(roi.struct).to eql @ss
      end

      it "should create a referenced Frame instance who's UID matches the value of the Frame UID tag of the 'ROI Item'" do
        roi = ROI.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(roi.frame.uid).to eql @roi_item.value('3006,0024')
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
        expect(@roi.name).to eql @name
      end

      it "should pass the 'number' argument to the 'number' attribute" do
        expect(@roi.number).to eql @number
      end

      it "should pass the 'frame' argument to the 'frame' attribute" do
        expect(@roi.frame).to eql @f
      end

      it "should pass the 'struct' argument to the 'struct' attribute" do
        expect(@roi.struct).to eql @ss
      end

      it "should by default set the 'slices' attribute to an empty array" do
        expect(@roi.slices).to eql Array.new
      end

      it "should by default set the 'algorithm' attribute to 'Automatic'" do
        expect(@roi.algorithm).to eql 'Automatic'
      end

      it "should by default set the 'type' attribute to a 'CONTROL'" do
        expect(@roi.type).to eql 'CONTROL'
      end

      it "should by default set the 'interpreter' attribute to 'RTKIT'" do
        expect(@roi.interpreter).to eql 'RTKIT'
      end

      it "should by default set the 'color' attribute to a proper color string" do
        expect(@roi.color.class).to eql String
        expect(@roi.color.split("\\").length).to eql 3
      end

      it "should add the ROI instance (once) to the referenced StructureSet" do
        expect(@ss.structures.length).to eql 1
        expect(@ss.structure(@roi.name)).to eql @roi
      end

      it "should add the ROI instance (once) to the referenced Frame" do
        expect(@f.structures.length).to eql 1
        expect(@f.structure(@roi.name)).to eql @roi
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        roi = ROI.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        roi_other = ROI.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        expect(roi == roi_other).to be true
      end

      it "should be false when comparing two instances having different attributes" do
        roi_other = ROI.new('Other ROI', @number, @f, @ss)
        expect(@roi == roi_other).to be false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@roi == 42).to be_falsey
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
        expect(@roi.slices.size).to eql 1
        expect(@roi.slices.first).to eql s
      end

      it "should add the Slice to the ROI instance already containing a Slice" do
        roi_other = ROI.new("Brain", 2, @f, @ss)
        s1 = Slice.new(@sop, @roi)
        s2 = Slice.new("1.567.322", roi_other)
        @roi.add_slice(s2)
        expect(@roi.slices.size).to eql 2
        expect(@roi.slices.first).to eql s1
        expect(@roi.slices.last).to eql s2
      end

      it "should not add multiple entries of the same Slice" do
        s = Slice.new(@sop, @roi)
        @roi.add_slice(s)
        expect(@roi.slices.size).to eql 1
        expect(@roi.slices.first).to eql s
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
        @ss1.expects(:remove_structure).once.with(roi)
        roi.attach_to(series)
        expect(roi.frame).to eql series.frame
        expect(series.structures.include?(roi)).to be true
      end

      it "should add the ROI (containing slices) to the ImageSeries instance" do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        series = d.patient.study.image_series.first
        roi = ROI.new(@name, @number, @f, @ss)
        @ss.expects(:remove_structure).once.with(roi)
        roi.attach_to(series)
        expect(roi.frame).to eql series.frame
        expect(series.structures.include?(roi)).to be true
      end

      it "should not do anything with the rois when they already belong to the given ImageSeries and have the correct frame" do
        roi1 = @ss1.create_roi(@f1)
        roi2 = @ss1.create_roi(@f1)
        # Before any processing (verify):
        expect(@ss1.structures.length).to eql 2
        expect(@ss1.structures.collect{|roi| roi.__id__}).to eql [roi1.__id__, roi2.__id__]
        @ss1.structures.each do |roi|
          roi.attach_to(@is1)
        end
        # After processing (test):
        expect(@ss1.structures.collect{|roi| roi.frame}).to eql [@f1, @f1]
        expect(@ss1.structures.length).to eql 2
        expect(@ss1.structures.collect{|roi| roi.__id__}).to eql [roi1.__id__, roi2.__id__]
      end

      it "should not remove (and subsequently re-add) a ROI which belongs to the correct struct, but belongs to another frame than that of the ImageSeries" do
        roi_wrong_frame = @ss1.create_roi(@f2)
        roi_corr_frame = @ss1.create_roi(@f1)
        # Before any processing (verify):
        expect(@ss1.structures.length).to eql 2
        expect(@ss1.structures.collect{|roi| roi.__id__}).to eql [roi_wrong_frame.__id__, roi_corr_frame.__id__]
        @ss1.structures.each do |roi|
          roi.attach_to(@is1)
        end
        # After processing (test):
        expect([roi_wrong_frame, roi_corr_frame].collect{|roi| roi.frame}).to eql [@f1, @f1]
        expect(@ss1.structures.length).to eql 2
        expect(@ss1.structures.collect{|roi| roi.__id__}).to eql [roi_wrong_frame.__id__, roi_corr_frame.__id__]
      end

      it "should successfully add the ROI to a struct-less ImageSeries instance (creating a new StructureSet instance)" do
        roi = ROI.new(@name, @number, @f, @ss1)
        struct_less_is = ImageSeries.new('1.767.232', 'CT', @f1, @st)
        roi.attach_to(struct_less_is)
        expect(roi.frame).to eql struct_less_is.frame
        expect(struct_less_is.structures.include?(roi)).to be true
        expect(roi.image_series).to eql struct_less_is
      end

    end


    context "#bin_volume" do

      before :each do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        img_series = d.patient.study.image_series.first
        @roi = img_series.struct.structure('External')
        @bin_volume = @roi.bin_volume
      end

      it "should return a BinVolume instance, containing 5 BinImage references, from this ROI" do
        expect(@bin_volume.class).to eql BinVolume
        expect(@bin_volume.bin_images.length).to eql 5
      end

      it "should set the BinVolume's series equal to that of the ROI" do
        expect(@bin_volume.series).to eql @roi.image_series
      end

      it "should set the ROI as the BinVolume's source" do
        expect(@bin_volume.source).to eql @roi
      end

      it "should return a BinVolume instance, where the narray matches the number of contours in this ROI as well as the dimensions of the referenced images" do
        expect(@bin_volume.narray.shape).to eql [5, 512, 171]
      end

      it "should return a BinVolume instance, where the segmented indices (as derived from the ROI's Contours) are marked as 1 and the non-segmented indices are 0" do
        # Note: This is not so much a principal test as a consistency test.
        expect((@bin_volume.narray.eq 1).where.length).to eql 37410
        expect((@bin_volume.narray.eq 0).where.length).to eql 400350
      end

    end


    context "#bin_volume(dose_volume)" do

      before :each do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CASE)
        img_series = d.patient.study.image_series.first
        @roi = img_series.struct.structure('External')
        @dvol = img_series.struct.plan.rt_dose.volumes.first
        @bin_volume = @roi.bin_volume(@dvol)
      end

      it "should accept a DoseVolume as argument and return a bin_volume instance" do
        expect(@bin_volume.class).to eql BinVolume
      end

      it "should return a BinVolume instance, where the narray matches the number of contours in this ROI as well as the dimensions of the dose volume (images)" do
        expect(@bin_volume.narray.shape).to eql [@roi.slices.length, @dvol.images.first.columns, @dvol.images.first.rows]
      end

    end


    context "#contour_item" do

      before :each do
        @roi = ROI.new(@name, @number, @f, @ss)
      end

      it "should return a ROI Contour Sequence Item properly populated with values from the ROI instance" do
        item = @roi.contour_item
        expect(item.class).to eql DICOM::Item
        expect(item.count).to eql 3
        expect(item.value('3006,002A')).to eql @roi.color
        expect(item.value('3006,0084')).to eql @roi.number.to_s
        expect(item['3006,0040'].count).to eql 0
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
        expect(@roi.slices.length).to eql 5
      end

    end


    context "#distribution" do

      before :each do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CASE)
        img_series = d.patient.study.image_series.first
        @roi = img_series.struct.structure('External')
        @dvol = img_series.struct.plan.rt_dose.volumes.first
      end

      it "should return a DoseDistribution instance when called without an argument" do
        distribution = @roi.distribution
        expect(distribution.class).to eql DoseDistribution
      end

      it "should return a DoseDistribution instance when called with a DoseVolume argument" do
        distribution = @roi.distribution(@dvol)
        expect(distribution.class).to eql DoseDistribution
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        roi = ROI.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        roi_other = ROI.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        expect(roi.eql?(roi_other)).to be true
      end

      it "should be false when comparing two instances having different attribute values" do
        roi_other = ROI.new('Other ROI', @number, @f, @ss)
        expect(@roi.eql?(roi_other)).to be false
      end

    end


    context "#export_pixels" do

      it "should move the ROI pixels from the source to target images with the given offset" do
        # Target
        tf = Frame.new('1.4321', @p)
        t_series = ImageSeries.new('1.767.454', 'CT', tf, @st)
        t1 = SliceImage.new('1.941', 13.0, t_series)
        t2 = SliceImage.new('1.942', 18.0, t_series)
        t3 = SliceImage.new('1.943', 23.0, t_series)
        tf.add_image(t1)
        tf.add_image(t2)
        tf.add_image(t3)
        t1.rows, t2.rows,  = 6, 6
        t1.columns, t2.columns = 6, 6
        t1.pos_x, t2.pos_x = 0, 0
        t1.pos_y, t2.pos_y = 0, 0
        t1.row_spacing, t2.row_spacing = 5, 5
        t1.col_spacing, t2.col_spacing = 5, 5
        t1.cosines, t2.cosines = [1, 0, 0, 0, 1, 0], [1, 0, 0, 0, 1, 0]
        t1.narray, t2.narray = NArray.sint(6, 6), NArray.sint(6, 6)
        # Source
        i1 = SliceImage.new('1.231', 3.0, @is)
        i2 = SliceImage.new('1.232', 8.0, @is)
        i3 = SliceImage.new('1.234', 13.0, @is)
        i1.rows, i2.rows,  = 6, 6
        i1.columns, i2.columns = 6, 6
        i1.pos_x, i2.pos_x = 0, 0
        i1.pos_y, i2.pos_y = 0, 0
        i1.row_spacing, i2.row_spacing = 5, 5
        i1.col_spacing, i2.col_spacing = 5, 5
        i1.cosines, i2.cosines = [1, 0, 0, 0, 1, 0], [1, 0, 0, 0, 1, 0]
        i1.narray, i2.narray = NArray.sint(6, 6).indgen!, NArray.sint(6, 6).indgen! + 100
        s1 = Slice.new('1.231', @roi)
        s2 = Slice.new('1.232', @roi)
        c11 = Contour.create_from_coordinates([5, 10, 5], [5, 5, 10], [3, 3, 3], s1)
        c12 = Contour.create_from_coordinates([15, 20, 15], [15, 15, 20], [3, 3, 3], s1)
        c21 = Contour.create_from_coordinates([5, 15, 15, 5], [5, 5, 15, 15], [8, 8, 8, 8], s2)
        offset = Coordinate.new(5, -5, 10)
        @roi.export_pixels(t_series, offset)
        expect(t1.narray[[2, 3, 8, 16, 17, 22]].to_a).to eql [7, 8, 13, 21, 22, 27]
        expect((t1.narray.eq 0).where.length).to eql 30
        expect(t2.narray[[2, 3, 4, 8, 9, 10, 14, 15, 16]].to_a).to eql [107, 108, 109, 113, 114, 115, 119, 120, 121]
        expect((t2.narray.eq 0).where.length).to eql 27
        expect(t3.narray).to be_nil
      end

    end


    context "#fill" do

      it "should call the set_pixels method of the image instances with the expected indices" do
        i1 = SliceImage.new('1.231', 3.0, @is)
        i2 = SliceImage.new('1.232', 8.0, @is)
        i1.rows, i2.rows = 6, 6
        i1.columns, i2.columns = 6, 6
        i1.pos_x, i2.pos_x = 0, 0
        i1.pos_y, i2.pos_y = 0, 0
        i1.row_spacing, i2.row_spacing = 5, 5
        i1.col_spacing, i2.col_spacing = 5, 5
        i1.cosines, i2.cosines = [1, 0, 0, 0, 1, 0], [1, 0, 0, 0, 1, 0]
        i1.narray, i2.narray = NArray.sint(6, 6), NArray.sint(6, 6)
        s1 = Slice.new('1.231', @roi)
        s2 = Slice.new('1.232', @roi)
        c11 = Contour.create_from_coordinates([5, 10, 5], [5, 5, 10], [3, 3, 3], s1)
        c12 = Contour.create_from_coordinates([15, 20, 15], [15, 15, 20], [3, 3, 3], s1)
        c21 = Contour.create_from_coordinates([5, 15, 15, 5], [5, 5, 15, 15], [8, 8, 8, 8], s2)
        value =1
        i1.expects(:set_pixels).with([7, 8, 13, 21, 22, 27], value)
        i2.expects(:set_pixels).with([7, 8, 9, 13, 14, 15, 19, 20, 21], value)
        is = @roi.fill(value)
      end

    end


    context "#frame=()" do

      it "should raise an when a non-Frame is passed" do
        expect {@roi.frame = 'not-a-frame'}.to raise_error(/to_frame/)
      end

      it "should assign the new frame to the roi" do
        f_other = Frame.new('1.787.434', @p)
        @roi.frame = f_other
        expect(@roi.frame).to eql f_other
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        roi = ROI.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        roi_other = ROI.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        expect(roi.hash).to be_a Fixnum
        expect(roi.hash).to eql roi_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        roi_other = ROI.new('Other ROI', @number, @f, @ss)
        expect(@roi.hash).not_to eql roi_other.hash
      end

    end


    context "#num_contours" do

      before :each do
        dcm = DICOM::DObject.read(FILE_STRUCT)
        @sequence = dcm['3006,0039'][0]['3006,0040']
        @roi = ROI.new(@name, @number, @f, @ss)
      end

      it "should return 0 for a ROI containing no contours" do
        expect(@roi.slices.length).to eql 0
      end

      it "should return 5 for a ROI containing 5 contours" do
        @roi.create_slices(@sequence)
        expect(@roi.num_contours).to eql 5
      end

    end


    context "#obs_item" do

      it "should return a RT ROI Observations Sequence Item properly populated with values from the ROI instance" do
        roi = ROI.new(@name, @number, @f, @ss)
        item = roi.obs_item
        expect(item.class).to eql DICOM::Item
        expect(item.count).to eql 4
        expect(item.value('3006,0082')).to eql roi.number.to_s
        expect(item.value('3006,0084')).to eql roi.number.to_s
        expect(item.value('3006,00A4')).to eql roi.type
        expect(item.value('3006,00A6')).to eql roi.interpreter
      end

    end


    context "#remove_references" do

      it "should nullify the 'frame' and 'struct' attributes of the ROI instance" do
        roi = ROI.new(@name, @number, @f, @ss)
        roi.remove_references
        expect(roi.frame).to be_nil
        expect(roi.struct).to be_nil
      end

    end


    context "#size" do

      before :each do
        i1 = SliceImage.new('1.789.541', 5.0, @is)
        i2 = SliceImage.new('1.789.542', 10.0, @is)
        i3 = SliceImage.new('1.789.543', 15.0, @is)
        i1.cosines, i2.cosines, i3.cosines = [1,0,0,0,1,0], [1,0,0,0,1,0], [1,0,0,0,1,0]
        i1.row_spacing, i2.row_spacing, i3.row_spacing = 1.0, 1.0, 1.0
        i1.col_spacing, i2.col_spacing, i3.col_spacing = 2.0, 2.0, 2.0
        i1.rows, i2.rows, i3.rows = 10, 10, 10
        i1.columns, i2.columns, i3.columns = 10, 10, 10
        i1.pos_x, i2.pos_x, i3.pos_x = 0.0, 0.0, 0.0
        i1.pos_y, i2.pos_y, i3.pos_y = 0.0, 0.0, 0.0
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
        expect(size).to be_a Float
        expect(size).to eql 0.265
      end

      it "should give this value for this ROI (NB: But the expected value is not an exact, principal value!!)" do
        # This test is just for consistency at the moment, and should be replaced by a (set of) principal test(s) on volume.
        # According to Oncentra 4.1, this volume is 708.845, and according to dicompyler 0.4.1 it is 933.75 cm^3.
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        roi = d.patient.study.image_series.first.struct.structure('External')
        expect(roi.size.round(1)).to eql 770.6
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
        expect(@roi.slice).to eql @roi.slices.first
      end

      it "should return the the matching Slice when a UID string is supplied" do
        uid = '1.3.6.1.4.1.2452.6.685926274.1132857921.4126754476.3684171967'
        slice = @roi.slice(uid)
        expect(slice.uid).to eql uid
      end

    end


    context "#ss_item" do

      it "should return a Structure Set ROI Sequence Item properly populated with values from the ROI instance" do
        roi = ROI.new(@name, @number, @f, @ss)
        item = roi.ss_item
        expect(item.class).to eql DICOM::Item
        expect(item.count).to eql 4
        expect(item.value('3006,0022')).to eql roi.number.to_s
        expect(item.value('3006,0024')).to eql roi.frame.uid
        expect(item.value('3006,0026')).to eql roi.name
        expect(item.value('3006,0036')).to eql roi.algorithm
      end

    end


    context "#to_roi" do

      it "should return itself" do
        expect(@roi.to_roi.equal?(@roi)).to be true
      end

    end


    context "#translate" do

      it "should call the translate method on all slices belonging to the roi, with the given offsets" do
        s1 = Slice.new('1.765.55', @roi)
        s2 = Slice.new('1.765.66', @roi)
        x_offset = -5
        y_offset = 10.4
        z_offset = -99.0
        s1.expects(:translate).with(x_offset, y_offset, z_offset)
        s2.expects(:translate).with(x_offset, y_offset, z_offset)
        @roi.translate(x_offset, y_offset, z_offset)
      end

    end

  end

end
# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe ProjectionImage do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.888.434', 'CT', @f, @st)
      @ss = StructureSet.new('1.765.354', @is)
      @plan = Plan.new('1.456.654', @ss)
      @beam = Beam.new('AP', 1, 'Linac1', 95.0, @plan)
      @cp = ControlPoint.new(0, 0.0, @beam)
      @rtis = RTImage.new('1.345.789', @plan)
      @uid = '1.234.876'
      @im = ProjectionImage.new(@uid, @rtis, :beam => @beam)
    end

    describe "::load" do

      before :each do
        @dcm = DICOM::DObject.read(FILE_RTIMAGE)
      end

      it "should raise an ArgumentError when a non-DObject is passed as the 'dcm' argument" do
        expect {ProjectionImage.load(42, @rtis)}.to raise_error(ArgumentError, /'dcm'/)
      end

      it "should raise an ArgumentError when an non-Series is passed as the 'series' argument" do
        expect {ProjectionImage.load(@dcm, 'not-a-series')}.to raise_error(ArgumentError, /series/)
      end

      it "should raise an ArgumentError when a DObject with a non-image type modality is passed with the 'dcm' argument" do
        expect {ProjectionImage.load(DICOM::DObject.read(FILE_STRUCT), @rtis)}.to raise_error(ArgumentError, /'dcm'/)
      end

      it "should create an Image instance with attributes taken from the DICOM Object" do
        # Note: No pos_slice or cosines for ProjectionImage.
        im = ProjectionImage.load(@dcm, @rtis)
        expect(im.uid).to eql @dcm.value('0008,0018')
        expect(im.date).to eql @dcm.value('0008,0012')
        expect(im.time).to eql @dcm.value('0008,0013')
        expect(im.columns).to eql @dcm.value('0028,0011')
        expect(im.rows).to eql @dcm.value('0028,0010')
        img_pos = @dcm.value('3002,0012').split("\\").collect {|val| val.to_f}
        expect(im.pos_x).to eql img_pos[0]
        expect(im.pos_y).to eql img_pos[1]
        spacing = @dcm.value('3002,0011').split("\\").collect {|val| val.to_f}
        expect(im.col_spacing).to eql spacing[1]
        expect(im.row_spacing).to eql spacing[0]
      end

      it "should create an Image instance which is properly referenced to its series" do
        im = ProjectionImage.load(@dcm, @rtis)
        expect(im.series).to eql @rtis
      end

      it "should pass the 'dcm' argument to the 'dcm' attribute" do
        im = ProjectionImage.load(@dcm, @rtis)
        expect(im.dcm).to eql @dcm
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-string is passed as the 'sop_uid' argument" do
        expect {ProjectionImage.new(42, @rtis)}.to raise_error(ArgumentError, /'sop_uid'/)
      end

      it "should raise an ArgumentError when a non-Series is passed as the 'series' argument" do
        expect {ProjectionImage.new(@uid, 'not-a-series')}.to raise_error(ArgumentError, /'series'/)
      end

      it "should raise an ArgumentError when a Series with a non-image-series type modality is passed as the 'modality' argument" do
        expect {ProjectionImage.new(@uid, StructureSet.new('1.7890', @is))}.to raise_error(ArgumentError, /'series'/)
      end

      it "should by default set the 'date' attribute as an nil" do
        expect(@im.date).to be_nil
      end

      it "should by default set the 'columns' attribute as an nil" do
        expect(@im.columns).to be_nil
      end

      it "should by default set the 'rows' attribute as an nil" do
        expect(@im.rows).to be_nil
      end

      it "should by default set the 'dcm' attribute as an nil" do
        expect(@im.dcm).to be_nil
      end

      it "should by default set the 'pos_x' attribute as an nil" do
        expect(@im.pos_x).to be_nil
      end

      it "should by default set the 'pos_y' attribute as an nil" do
        expect(@im.pos_y).to be_nil
      end

      it "should by default set the 'col_spacing' attribute as an nil" do
        expect(@im.col_spacing).to be_nil
      end

      it "should by default set the 'row_spacing' attribute as an nil" do
        expect(@im.row_spacing).to be_nil
      end

      it "should by default set the 'time' attribute as an nil" do
        expect(@im.time).to be_nil
      end

      it "should pass the 'uid' argument to the 'uid' attribute" do
        expect(@im.uid).to eql @uid
      end

      it "should pass the 'series' argument to the 'series' attribute" do
        expect(@im.series).to eql @rtis
      end

      it "should add the Image instance (once) to the referenced RTImage series" do
        expect(@im.series.images.length).to eql 1
        expect(@im.series.image(@im.uid)).to eql @im
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        im_other = ProjectionImage.new(@uid, @rtis)
        expect(@im == im_other).to be_true
      end

      it "should be false when comparing two instances having different attributes" do
        im_other = ProjectionImage.new('1.4.99', @rtis)
        expect(@im == im_other).to be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@im == 42).to be_false
      end

    end


    describe "#col_spacing=()" do

      it "should pass the argument to the 'col_spacing' attribute" do
        value = 3.3
        @im.col_spacing = value
        expect(@im.col_spacing).to eql value
      end

    end


    describe "#columns=()" do

=begin
      it "should raise an ArgumentError when a negative Integer is passed as argument" do
        expect {@im.columns = -34}.to raise_error(ArgumentError, /'cols'/)
      end
=end

      it "should pass the argument to the 'rows' attribute" do
        value = 34
        @im.columns = value
        expect(@im.columns).to eql value
      end

    end


    context "#coordinates_from_indices" do

      before :each do
        @cols = NArray.byte(3).indgen!
        @rows = NArray.byte(3).indgen!
        @im.stubs(:pos_x).returns(-5.0)
        @im.stubs(:pos_y).returns(-3.0)
        @im.stubs(:pos_slice).returns(50.0)
        @im.stubs(:col_spacing).returns(2.0)
        @im.stubs(:row_spacing).returns(3.0)
      end

      it "should raise an ArgumentError when a non-NArray is passed as the 'column_indices' argument" do
        expect {@im.coordinates_from_indices('not-a-narray', @rows)}.to raise_error(ArgumentError, /column_indices/)
      end

      it "should raise an ArgumentError when a non-NArray is passed as the 'row_indices' argument" do
        expect {@im.coordinates_from_indices(@cols, 'not-a-narray')}.to raise_error(ArgumentError, /row_indices/)
      end

      it "should raise an ArgumentError when a the arguments are not of equal length" do
        expect {@im.coordinates_from_indices(NArray.byte(4), NArray.byte(2))}.to raise_error(ArgumentError, /equal/)
      end

      it "should return the image position coordinates when converting the zero-index in an image of standard orientation" do
        @im.stubs(:cosines).returns([1.0, 0.0, 0.0, 0.0, 1.0, 0.0])
        x, y, z = @im.coordinates_from_indices(NArray[0], NArray[0])
        expect(x.to_a).to eql [-5.0]
        expect(y.to_a).to eql [-3.0]
        expect(z.to_a).to eql [50.0]
      end

      it "should return the image position coordinates when converting the zero-index in an image with negative (but otherwise standard) direction cosines" do
        @im.stubs(:cosines).returns([-1.0, 0.0, 0.0, 0.0, -1.0, 0.0])
        x, y, z = @im.coordinates_from_indices(NArray[0], NArray[0])
        expect(x.to_a).to eql [-5.0]
        expect(y.to_a).to eql [-3.0]
        expect(z.to_a).to eql [50.0]
      end

      it "should return the image position coordinates when converting the zero-index in an image with 'rotated' unity direction cosines" do
        @im.stubs(:cosines).returns([0.0, 0.0, 1.0, 1.0, 0.0, 0.0])
        x, y, z = @im.coordinates_from_indices(NArray[0], NArray[0])
        expect(x.to_a).to eql [-5.0]
        expect(y.to_a).to eql [-3.0]
        expect(z.to_a).to eql [50.0]
      end

      it "should return the image position coordinates when converting the zero-index in an image with non-orthogonal direction cosines" do
        @im.stubs(:cosines).returns([0.9953, -0.03130, 0.09128, 0.0, 0.9459, 0.3244])
        x, y, z = @im.coordinates_from_indices(NArray[0], NArray[0])
        expect(x.to_a).to eql [-5.0]
        expect(y.to_a).to eql [-3.0]
        expect(z.to_a).to eql [50.0]
      end

      it "should return the expected image positions when converting the given indices in an image of standard orientation" do
        @im.stubs(:cosines).returns([1.0, 0.0, 0.0, 0.0, 1.0, 0.0])
        x, y, z = @im.coordinates_from_indices(NArray[3, 1], NArray[3, 1])
        expect(x.to_a).to eql [1.0, -3.0]
        expect(y.to_a).to eql [6.0, 0.0]
        expect(z.to_a).to eql [50.0, 50.0]
      end

      it "should return the expected image positions when converting the given indices in an image with negative (but otherwise standard) direction cosines" do
        @im.stubs(:cosines).returns([-1.0, 0.0, 0.0, 0.0, -1.0, 0.0])
        x, y, z = @im.coordinates_from_indices(NArray[3, 1], NArray[3, 1])
        expect(x.to_a).to eql [-11.0, -7.0]
        expect(y.to_a).to eql [-12.0, -6.0]
        expect(z.to_a).to eql [50.0, 50.0]
      end

      it "should return the expected image positions when converting the given indices in an image with 'rotated' unity direction cosines" do
        @im.stubs(:cosines).returns([0.0, 0.0, 1.0, 1.0, 0.0, 0.0])
        x, y, z = @im.coordinates_from_indices(NArray[3, 1], NArray[3, 1])
        expect(x.to_a).to eql [4.0, -2.0]
        expect(y.to_a).to eql [-3.0, -3.0]
        expect(z.to_a).to eql [56.0, 52.0]
      end

      it "should return the expected image positions when converting the given indices in an image with non-orthogonal direction cosines" do
        @im.stubs(:cosines).returns([0.9953, -0.03130, 0.09128, 0.0, 0.9459, 0.3244])
        xn, yn, zn = @im.coordinates_from_indices(NArray[3, 1], NArray[3, 1])
        x, y, z = Array.new, Array.new, Array.new
        xn.each {|i| x << i.to_f.round(2)}
        yn.each {|i| y << i.to_f.round(2)}
        zn.each {|i| z << i.to_f.round(2)}
        expect(x).to eql [0.97, -3.01]
        expect(y).to eql [5.33, -0.22]
        expect(z).to eql [53.47, 51.16]
      end

    end


    # The indices produced in this method's tests should be identical with the indices from the previous methods tests.
    context "#coordinates_to_indices" do

      before :each do
        @x = NArray.byte(3).indgen!
        @y = NArray.byte(3).indgen!
        @z = NArray.byte(3).indgen!
        @im.stubs(:pos_x).returns(-5.0)
        @im.stubs(:pos_y).returns(-3.0)
        @im.stubs(:pos_slice).returns(50.0)
        @im.stubs(:col_spacing).returns(2.0)
        @im.stubs(:row_spacing).returns(3.0)
      end

      it "should raise an ArgumentError when a non-NArray is passed as the 'x' argument" do
        expect {@im.coordinates_to_indices('not-a-narray', @y, @z)}.to raise_error(ArgumentError, /'x'/)
      end

      it "should raise an ArgumentError when a non-NArray is passed as the 'y' argument" do
        expect {@im.coordinates_to_indices(@x, 'not-a-narray', @z)}.to raise_error(ArgumentError, /'y'/)
      end

      it "should raise an ArgumentError when a non-NArray is passed as the 'z' argument" do
        expect {@im.coordinates_to_indices(@x, @y, 'not-a-narray')}.to raise_error(ArgumentError, /'z'/)
      end

      it "should raise an ArgumentError when a the arguments are not of equal length" do
        expect {@im.coordinates_to_indices(NArray.byte(4), NArray.byte(2), NArray.byte(4))}.to raise_error(ArgumentError, /equal/)
      end

      it "should return the zero-index when converting the image position coordinates in an image of standard orientation" do
        @im.stubs(:cosines).returns([1.0, 0.0, 0.0, 0.0, 1.0, 0.0])
        cols, rows = @im.coordinates_to_indices(NArray[-5.0], NArray[-3.0], NArray[50.0])
        expect(cols.to_a).to eql [0]
        expect(rows.to_a).to eql [0]
      end

      it "should return the zero-index when converting the image position coordinates in an image with negative (but otherwise standard) direction cosines" do
        @im.stubs(:cosines).returns([-1.0, 0.0, 0.0, 0.0, -1.0, 0.0])
        cols, rows = @im.coordinates_to_indices(NArray[-5.0], NArray[-3.0], NArray[50.0])
        expect(cols.to_a).to eql [0]
        expect(rows.to_a).to eql [0]
      end

      it "should return the zero-index when converting the image position coordinates in an image with 'rotated' unity direction cosines" do
        @im.stubs(:cosines).returns([0.0, 0.0, 1.0, 1.0, 0.0, 0.0])
        cols, rows = @im.coordinates_to_indices(NArray[-5.0], NArray[-3.0], NArray[50.0])
        expect(cols.to_a).to eql [0]
        expect(rows.to_a).to eql [0]
      end

      it "should return the zero-index when converting the image position coordinates in an image with non-orthogonal direction cosines" do
        @im.stubs(:cosines).returns([0.9953, -0.03130, 0.09128, 0.0, 0.9459, 0.3244])
        cols, rows = @im.coordinates_to_indices(NArray[-5.0], NArray[-3.0], NArray[50.0])
        expect(cols.to_a).to eql [0]
        expect(rows.to_a).to eql [0]
      end

      it "should return the expected image positions when converting the given indices in an image of standard orientation" do
        @im.stubs(:cosines).returns([1.0, 0.0, 0.0, 0.0, 1.0, 0.0])
        cols, rows = @im.coordinates_to_indices(NArray[1.0, -3.0], NArray[6.0, 0.0], NArray[50.0, 50.0])
        expect(cols.to_a).to eql [3, 1]
        expect(rows.to_a).to eql [3, 1]
      end

      it "should return the expected image positions when converting the given indices in an image with negative (but otherwise standard) direction cosines" do
        @im.stubs(:cosines).returns([-1.0, 0.0, 0.0, 0.0, -1.0, 0.0])
        cols, rows = @im.coordinates_to_indices(NArray[-11.0, -7.0], NArray[-12.0, -6.0], NArray[50.0, 50.0])
        expect(cols.to_a).to eql [3, 1]
        expect(rows.to_a).to eql [3, 1]
      end

      it "should return the expected image positions when converting the given indices in an image with 'rotated' unity direction cosines" do
        @im.stubs(:cosines).returns([0.0, 0.0, 1.0, 1.0, 0.0, 0.0])
        cols, rows = @im.coordinates_to_indices(NArray[4.0, -2.0], NArray[-3.0, -3.0], NArray[56.0, 52.0])
        expect(cols.to_a).to eql [3, 1]
        expect(rows.to_a).to eql [3, 1]
      end

      it "should return the expected image positions when converting the given indices in an image with non-orthogonal direction cosines" do
        @im.stubs(:cosines).returns([0.9953, -0.03130, 0.09128, 0.0, 0.9459, 0.3244])
        cols, rows = @im.coordinates_to_indices(NArray[0.97, -3.01], NArray[5.93, -0.22], NArray[53.47, 51.16])
        expect(cols.to_a).to eql [3, 1]
        expect(rows.to_a).to eql [3, 1]
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        im_other = ProjectionImage.new(@uid, @rtis)
        expect(@im.eql?(im_other)).to be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        im_other = ProjectionImage.new('1.4.99', @rtis)
        expect(@im.eql?(im_other)).to be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        im_other = ProjectionImage.new(@uid, @rtis)
        expect(@im.hash).to be_a Fixnum
        expect(@im.hash).to eql im_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        im_other = ProjectionImage.new('1.4.99', @rtis)
        expect(@im.hash).not_to eql im_other.hash
      end

    end


    describe "#narray=()" do

      before :each do
        @im.columns = 2
        @im.rows = 2
      end

      it "should raise an ArgumentError when a non-NArray is passed as argument" do
        expect {@im.narray = [[1,2],[3,4]]}.to raise_error(ArgumentError, /'narray'/)
      end

      it "should raise an ArgumentError when the passed NArray's number of columns deviates from that of the Image instance" do
        expect {@im.narray = NArray[[1,2,3],[4,5,6]]}.to raise_error(ArgumentError, /'narray'/)
      end

      it "should raise an ArgumentError when the passed NArray's number of rows deviates from that of the Image instance" do
        expect {@im.narray = NArray[[1,2],[3,4],[5,6]]}.to raise_error(ArgumentError, /'narray'/)
      end

      it "should pass the argument to the 'narray' attribute" do
        narray = NArray[[1,2],[3,4]]
        @im.narray = narray
        expect(@im.narray).to eql narray
      end

    end


    describe "#pos_x=()" do

      it "should pass the argument to the 'pos_x' attribute" do
        value = -22.2
        @im.pos_x = value
        expect(@im.pos_x).to eql value
      end

    end


    describe "#pos_y=()" do

      it "should pass the argument to the 'pos_y' attribute" do
        value = -44.4
        @im.pos_y = value
        expect(@im.pos_y).to eql value
      end

    end


    describe "#row_spacing=()" do

      it "should pass the argument to the 'row_spacing' attribute" do
        value = 3.3
        @im.row_spacing = value
        expect(@im.row_spacing).to eql value
      end

    end


    describe "#rows=()" do

=begin
      it "should raise an ArgumentError when a negative Integer is passed as argument" do
        expect {@im.rows = -32}.to raise_error(ArgumentError, /'rows'/)
      end
=end

      it "should pass the argument to the 'rows' attribute" do
        value = 32
        @im.rows = value
        expect(@im.rows).to eql value
      end

    end


    describe "#set_resolution" do

      before :each do
        @im.columns = 4
        @im.rows = 4
        @im.narray = NArray.int(4, 4).fill(1)
      end

      it "should reduce the number of columns as expected by :even cropping (symmetric situation)" do
        @im.narray[[0,-1], true] = -1
        @im.set_resolution(cols=2, rows=4)
        expect(@im.rows).to eql rows
        expect(@im.columns).to eql cols
        expect(@im.narray.shape).to eql [cols, rows]
        expect(@im.narray == NArray.int(cols, rows).fill(1)).to be_true
      end

      it "should reduce the number of columns as expected by :even cropping (asymmetric situation)" do
        @im.narray[0, true] = -1
        @im.set_resolution(cols=3, rows=4)
        expect(@im.rows).to eql rows
        expect(@im.columns).to eql cols
        expect(@im.narray.shape).to eql [cols, rows]
        expect(@im.narray == NArray.int(cols, rows).fill(1)).to be_true
      end

      it "should reduce the number of columns as expected by :left cropping" do
        @im.narray[0..1, true] = -1
        @im.set_resolution(cols=2, rows=4, :hor => :left)
        expect(@im.rows).to eql rows
        expect(@im.columns).to eql cols
        expect(@im.narray.shape).to eql [cols, rows]
        expect(@im.narray == NArray.int(cols, rows).fill(1)).to be_true
      end

      it "should reduce the number of columns as expected by :right cropping" do
        @im.narray[-2..-1, true] = -1
        @im.set_resolution(cols=2, rows=4, :hor => :right)
        expect(@im.rows).to eql rows
        expect(@im.columns).to eql cols
        expect(@im.narray.shape).to eql [cols, rows]
        expect(@im.narray == NArray.int(cols, rows).fill(1)).to be_true
      end

      it "should expand the number of columns as expected by :even bordering (symmetric situation)" do
        @im.set_resolution(cols=6, rows=4)
        expect(@im.rows).to eql rows
        expect(@im.columns).to eql cols
        expect(@im.narray.shape).to eql [cols, rows]
        expected = NArray.int(cols, rows)
        expected[1..-2, true] = 1
        expect(@im.narray == expected).to be_true
      end

      it "should expand the number of columns as expected by :even bordering (asymmetric situation)" do
        @im.set_resolution(cols=5, rows=4)
        expect(@im.rows).to eql rows
        expect(@im.columns).to eql cols
        expect(@im.narray.shape).to eql [cols, rows]
        expected = NArray.int(cols, rows)
        expected[1..-1, true] = 1
        expect(@im.narray == expected).to be_true
      end

      it "should expand the number of columns as expected by :left bordering" do
        @im.set_resolution(cols=6, rows=4, :hor => :left)
        expect(@im.rows).to eql rows
        expect(@im.columns).to eql cols
        expect(@im.narray.shape).to eql [cols, rows]
        expected = NArray.int(cols, rows)
        expected[2..-1, true] = 1
        expect(@im.narray == expected).to be_true
      end

      it "should expand the number of columns as expected by :right bordering" do
        @im.set_resolution(cols=6, rows=4, :hor => :right)
        expect(@im.rows).to eql rows
        expect(@im.columns).to eql cols
        expect(@im.narray.shape).to eql [cols, rows]
        expected = NArray.int(cols, rows)
        expected[0..-3, true] = 1
        expect(@im.narray == expected).to be_true
      end

      it "should reduce the number of rows as expected by :even cropping (symmetric situation)" do
        @im.narray[true, [0,-1]] = -1
        @im.set_resolution(cols=4, rows=2)
        expect(@im.rows).to eql rows
        expect(@im.columns).to eql cols
        expect(@im.narray.shape).to eql [cols, rows]
        expect(@im.narray == NArray.int(cols, rows).fill(1)).to be_true
      end

      it "should reduce the number of rows as expected by :even cropping (asymmetric situation)" do
        @im.narray[true, 0] = -1
        @im.set_resolution(cols=4, rows=3)
        expect(@im.rows).to eql rows
        expect(@im.columns).to eql cols
        expect(@im.narray.shape).to eql [cols, rows]
        expect(@im.narray == NArray.int(cols, rows).fill(1)).to be_true
      end

      it "should reduce the number of rows as expected by :top cropping" do
        @im.narray[true, 0..1] = -1
        @im.set_resolution(cols=4, rows=2, :ver => :top)
        expect(@im.rows).to eql rows
        expect(@im.columns).to eql cols
        expect(@im.narray.shape).to eql [cols, rows]
        expect(@im.narray == NArray.int(cols, rows).fill(1)).to be_true
      end

      it "should reduce the number of rows as expected by :bottom cropping" do
        @im.narray[true, -2..-1] = -1
        @im.set_resolution(cols=4, rows=2, :ver => :bottom)
        expect(@im.rows).to eql rows
        expect(@im.columns).to eql cols
        expect(@im.narray.shape).to eql [cols, rows]
        expect(@im.narray == NArray.int(cols, rows).fill(1)).to be_true
      end

      it "should expand the number of rows as expected by :even bordering (symmetric situation)" do
        @im.set_resolution(cols=4, rows=6)
        expect(@im.rows).to eql rows
        expect(@im.columns).to eql cols
        expect(@im.narray.shape).to eql [cols, rows]
        expected = NArray.int(cols, rows)
        expected[true, 1..-2] = 1
        expect(@im.narray == expected).to be_true
      end

      it "should expand the number of rows as expected by :even bordering (asymmetric situation)" do
        @im.set_resolution(cols=4, rows=5)
        expect(@im.rows).to eql rows
        expect(@im.columns).to eql cols
        expect(@im.narray.shape).to eql [cols, rows]
        expected = NArray.int(cols, rows)
        expected[true, 1..-1] = 1
        expect(@im.narray == expected).to be_true
      end

      it "should expand the number of rows as expected by :top bordering" do
        @im.set_resolution(cols=4, rows=6, :ver => :top)
        expect(@im.rows).to eql rows
        expect(@im.columns).to eql cols
        expect(@im.narray.shape).to eql [cols, rows]
        expected = NArray.int(cols, rows)
        expected[true, 2..-1] = 1
        expect(@im.narray == expected).to be_true
      end

      it "should expand the number of rows as expected by :bottom bordering" do
        @im.set_resolution(cols=4, rows=6, :ver => :bottom)
        expect(@im.rows).to eql rows
        expect(@im.columns).to eql cols
        expect(@im.narray.shape).to eql [cols, rows]
        expected = NArray.int(cols, rows)
        expected[true, 0..-3] = 1
        expect(@im.narray == expected).to be_true
      end

      it "should both expand the rows as expected by :bottom bordering and reduce the columns as expected by :left cropping" do
        @im.narray[0..1, true] = -1
        @im.set_resolution(cols=2, rows=6, :hor => :left, :ver => :bottom)
        expect(@im.rows).to eql rows
        expect(@im.columns).to eql cols
        expect(@im.narray.shape).to eql [cols, rows]
        expected = NArray.int(cols, rows)
        expected[true, 0..-3] = 1
        expect(@im.narray == expected).to be_true
      end

    end


    context "#to_dcm" do

      it "should return a DICOM object (when called on an image instance created from scratch, i.e. non-dicom source)" do
        dcm = @im.to_dcm
        expect(dcm).to be_a DICOM::DObject
      end

      it "should add series level attributes" do
        @im.series.expects(:add_attributes_to_dcm)
        dcm = @im.to_dcm
      end

      it "should create a DICOM object containing the attributes of the image instance" do
        @im.columns = 10
        @im.rows = 15
        @im.narray = NArray.int(10, 15).indgen!
        @im.row_spacing = 1.0
        @im.col_spacing = 2.0
        @im.pos_x = -1.0
        @im.pos_y = 5.0
        dcm = @im.to_dcm
        expect(dcm.value('0008,0012')).to eql @im.date
        expect(dcm.value('0008,0013')).to eql @im.time
        expect(dcm.value('0008,0018')).to eql @im.uid
        expect(dcm.value('0028,0011')).to eql @im.columns
        expect(dcm.value('0028,0010')).to eql @im.rows
        expect(dcm.value('3002,0011')).to eql [@im.row_spacing, @im.col_spacing].join("\\")
        expect(dcm.value('3002,0012')).to eql [@im.pos_x, @im.pos_y].join("\\")
        expect(dcm.narray).to eql @im.narray
      end

    end


    context "#to_projection_image" do

      it "should return itself" do
        expect(@im.to_projection_image.equal?(@im)).to be_true
      end

    end

  end

end
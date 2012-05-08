# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe Image do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.345.789', 'CT', @f, @st)
      @uid = '1.234.876'
      @im = Image.new(@uid, @is)
    end

    describe "::load" do

      before :each do
        @dcm = DICOM::DObject.read(FILE_IMAGE)
      end

      it "should raise an ArgumentError when a non-DObject is passed as the 'dcm' argument" do
        expect {Image.load(42, @is)}.to raise_error(ArgumentError, /'dcm'/)
      end

      it "should raise an ArgumentError when an non-Series is passed as the 'series' argument" do
        expect {Image.load(@dcm, 'not-a-series')}.to raise_error(ArgumentError, /series/)
      end

      it "should raise an ArgumentError when a DObject with a non-image type modality is passed with the 'dcm' argument" do
        expect {Image.load(DICOM::DObject.read(FILE_STRUCT), @is)}.to raise_error(ArgumentError, /'dcm'/)
      end

      it "should create an Image instance with attributes taken from the DICOM Object" do
        im = Image.load(@dcm, @is)
        im.uid.should eql @dcm.value('0008,0018')
        im.date.should eql @dcm.value('0008,0012')
        im.time.should eql @dcm.value('0008,0013')
      end

      it "should create an Image instance which is properly referenced to its series" do
        im = Image.load(@dcm, @is)
        im.series.should eql @is
      end

      it "should pass the 'dcm' argument to the 'dcm' attribute" do
        im = Image.load(@dcm, @is)
        im.dcm.should eql @dcm
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-string is passed as the 'sop_uid' argument" do
        expect {Image.new(42, @is)}.to raise_error(ArgumentError, /'sop_uid'/)
      end

      it "should raise an ArgumentError when a non-Series is passed as the 'series' argument" do
        expect {Image.new(@uid, 'not-a-series')}.to raise_error(ArgumentError, /'series'/)
      end

      it "should raise an ArgumentError when a Series with a non-image-series type modality is passed as the 'modality' argument" do
        expect {Image.new(@uid, StructureSet.new('1.7890', @is))}.to raise_error(ArgumentError, /'series'/)
      end

      it "should by default set the 'cosines' attribute as an nil" do
        @im.cosines.should be_nil
      end

      it "should by default set the 'date' attribute as an nil" do
        @im.date.should be_nil
      end

      it "should by default set the 'columns' attribute as an nil" do
        @im.columns.should be_nil
      end

      it "should by default set the 'rows' attribute as an nil" do
        @im.rows.should be_nil
      end

      it "should by default set the 'dcm' attribute as an nil" do
        @im.dcm.should be_nil
      end

      it "should by default set the 'pos_x' attribute as an nil" do
        @im.pos_x.should be_nil
      end

      it "should by default set the 'pos_y' attribute as an nil" do
        @im.pos_y.should be_nil
      end

      it "should by default set the 'pos_slice' attribute as an nil" do
        @im.pos_slice.should be_nil
      end

      it "should by default set the 'col_spacing' attribute as an nil" do
        @im.col_spacing.should be_nil
      end

      it "should by default set the 'row_spacing' attribute as an nil" do
        @im.row_spacing.should be_nil
      end

      it "should by default set the 'time' attribute as an nil" do
        @im.time.should be_nil
      end

      it "should pass the 'uid' argument to the 'uid' attribute" do
        @im.uid.should eql @uid
      end

      it "should pass the 'series' argument to the 'series' attribute" do
        @im.series.should eql @is
      end

      it "should add the Image instance (once) to the referenced ImageSeries" do
        @im.series.images.length.should eql 1
        @im.series.image(@im.uid).should eql @im
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        im_other = Image.new(@uid, @is)
        (@im == im_other).should be_true
      end

      it "should be false when comparing two instances having different attributes" do
        im_other = Image.new('1.4.99', @is)
        (@im == im_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@im == 42).should be_false
      end

    end


    describe "#col_spacing=()" do

      it "should pass the argument to the 'col_spacing' attribute" do
        value = 3.3
        @im.col_spacing = value
        @im.col_spacing.should eql value
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
        @im.columns.should eql value
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
        x.to_a.should eql [-5.0]
        y.to_a.should eql [-3.0]
        z.to_a.should eql [50.0]
      end

      it "should return the image position coordinates when converting the zero-index in an image with negative (but otherwise standard) direction cosines" do
        @im.stubs(:cosines).returns([-1.0, 0.0, 0.0, 0.0, -1.0, 0.0])
        x, y, z = @im.coordinates_from_indices(NArray[0], NArray[0])
        x.to_a.should eql [-5.0]
        y.to_a.should eql [-3.0]
        z.to_a.should eql [50.0]
      end

      it "should return the image position coordinates when converting the zero-index in an image with 'rotated' unity direction cosines" do
        @im.stubs(:cosines).returns([0.0, 0.0, 1.0, 1.0, 0.0, 0.0])
        x, y, z = @im.coordinates_from_indices(NArray[0], NArray[0])
        x.to_a.should eql [-5.0]
        y.to_a.should eql [-3.0]
        z.to_a.should eql [50.0]
      end

      it "should return the image position coordinates when converting the zero-index in an image with non-orthogonal direction cosines" do
        @im.stubs(:cosines).returns([0.9953, -0.03130, 0.09128, 0.0, 0.9459, 0.3244])
        x, y, z = @im.coordinates_from_indices(NArray[0], NArray[0])
        x.to_a.should eql [-5.0]
        y.to_a.should eql [-3.0]
        z.to_a.should eql [50.0]
      end

      it "should return the expected image positions when converting the given indices in an image of standard orientation" do
        @im.stubs(:cosines).returns([1.0, 0.0, 0.0, 0.0, 1.0, 0.0])
        x, y, z = @im.coordinates_from_indices(NArray[3, 1], NArray[3, 1])
        x.to_a.should eql [1.0, -3.0]
        y.to_a.should eql [6.0, 0.0]
        z.to_a.should eql [50.0, 50.0]
      end

      it "should return the expected image positions when converting the given indices in an image with negative (but otherwise standard) direction cosines" do
        @im.stubs(:cosines).returns([-1.0, 0.0, 0.0, 0.0, -1.0, 0.0])
        x, y, z = @im.coordinates_from_indices(NArray[3, 1], NArray[3, 1])
        x.to_a.should eql [-11.0, -7.0]
        y.to_a.should eql [-12.0, -6.0]
        z.to_a.should eql [50.0, 50.0]
      end

      it "should return the expected image positions when converting the given indices in an image with 'rotated' unity direction cosines" do
        @im.stubs(:cosines).returns([0.0, 0.0, 1.0, 1.0, 0.0, 0.0])
        x, y, z = @im.coordinates_from_indices(NArray[3, 1], NArray[3, 1])
        x.to_a.should eql [4.0, -2.0]
        y.to_a.should eql [-3.0, -3.0]
        z.to_a.should eql [56.0, 52.0]
      end

      it "should return the expected image positions when converting the given indices in an image with non-orthogonal direction cosines" do
        @im.stubs(:cosines).returns([0.9953, -0.03130, 0.09128, 0.0, 0.9459, 0.3244])
        xn, yn, zn = @im.coordinates_from_indices(NArray[3, 1], NArray[3, 1])
        x, y, z = Array.new, Array.new, Array.new
        xn.each {|i| x << i.to_f.round(2)}
        yn.each {|i| y << i.to_f.round(2)}
        zn.each {|i| z << i.to_f.round(2)}
        x.should eql [0.97, -3.01]
        y.should eql [5.33, -0.22]
        z.should eql [53.47, 51.16]
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
        cols.to_a.should eql [0]
        rows.to_a.should eql [0]
      end

      it "should return the zero-index when converting the image position coordinates in an image with negative (but otherwise standard) direction cosines" do
        @im.stubs(:cosines).returns([-1.0, 0.0, 0.0, 0.0, -1.0, 0.0])
        cols, rows = @im.coordinates_to_indices(NArray[-5.0], NArray[-3.0], NArray[50.0])
        cols.to_a.should eql [0]
        rows.to_a.should eql [0]
      end

      it "should return the zero-index when converting the image position coordinates in an image with 'rotated' unity direction cosines" do
        @im.stubs(:cosines).returns([0.0, 0.0, 1.0, 1.0, 0.0, 0.0])
        cols, rows = @im.coordinates_to_indices(NArray[-5.0], NArray[-3.0], NArray[50.0])
        cols.to_a.should eql [0]
        rows.to_a.should eql [0]
      end

      it "should return the zero-index when converting the image position coordinates in an image with non-orthogonal direction cosines" do
        @im.stubs(:cosines).returns([0.9953, -0.03130, 0.09128, 0.0, 0.9459, 0.3244])
        cols, rows = @im.coordinates_to_indices(NArray[-5.0], NArray[-3.0], NArray[50.0])
        cols.to_a.should eql [0]
        rows.to_a.should eql [0]
      end

      it "should return the expected image positions when converting the given indices in an image of standard orientation" do
        @im.stubs(:cosines).returns([1.0, 0.0, 0.0, 0.0, 1.0, 0.0])
        cols, rows = @im.coordinates_to_indices(NArray[1.0, -3.0], NArray[6.0, 0.0], NArray[50.0, 50.0])
        cols.to_a.should eql [3, 1]
        rows.to_a.should eql [3, 1]
      end

      it "should return the expected image positions when converting the given indices in an image with negative (but otherwise standard) direction cosines" do
        @im.stubs(:cosines).returns([-1.0, 0.0, 0.0, 0.0, -1.0, 0.0])
        cols, rows = @im.coordinates_to_indices(NArray[-11.0, -7.0], NArray[-12.0, -6.0], NArray[50.0, 50.0])
        cols.to_a.should eql [3, 1]
        rows.to_a.should eql [3, 1]
      end

      it "should return the expected image positions when converting the given indices in an image with 'rotated' unity direction cosines" do
        @im.stubs(:cosines).returns([0.0, 0.0, 1.0, 1.0, 0.0, 0.0])
        cols, rows = @im.coordinates_to_indices(NArray[4.0, -2.0], NArray[-3.0, -3.0], NArray[56.0, 52.0])
        cols.to_a.should eql [3, 1]
        rows.to_a.should eql [3, 1]
      end

      it "should return the expected image positions when converting the given indices in an image with non-orthogonal direction cosines" do
        @im.stubs(:cosines).returns([0.9953, -0.03130, 0.09128, 0.0, 0.9459, 0.3244])
        cols, rows = @im.coordinates_to_indices(NArray[0.97, -3.01], NArray[5.93, -0.22], NArray[53.47, 51.16])
        cols.to_a.should eql [3, 1]
        rows.to_a.should eql [3, 1]
      end

    end


    describe "#cosines=()" do

=begin
      it "should raise an ArgumentError when an Array of length other than 6 is passed as argument" do
        expect {@im.cosines = [1.0, 2.0, 3.0]}.to raise_error(ArgumentError, /'cos'/)
      end
=end

      it "should pass the argument to the 'cosines' attribute" do
        value = [1.0, 2.0, 3.0, 4.0, 5.0, 6.6]
        @im.cosines = value
        @im.cosines.should eql value
      end

      it "should convert array string parameters to floats" do
        value_str = ['1.0', '2.0', '3.0', '4.0', '5.0', '6.6']
        value = [1.0, 2.0, 3.0, 4.0, 5.0, 6.6]
        @im.cosines = value_str
        @im.cosines.should eql value
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        im_other = Image.new(@uid, @is)
        @im.eql?(im_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        im_other = Image.new('1.4.99', @is)
        @im.eql?(im_other).should be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        im_other = Image.new(@uid, @is)
        @im.hash.should be_a Fixnum
        @im.hash.should eql im_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        im_other = Image.new('1.4.99', @is)
        @im.hash.should_not eql im_other.hash
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
        @im.narray.should eql narray
      end

    end


    describe "#pos_slice=()" do

      it "should pass the argument to the 'pos_slice' attribute" do
        value = 33.3
        @im.pos_slice = value
        @im.pos_slice.should eql value
      end

    end


    describe "#pos_x=()" do

      it "should pass the argument to the 'pos_x' attribute" do
        value = -22.2
        @im.pos_x = value
        @im.pos_x.should eql value
      end

    end


    describe "#pos_y=()" do

      it "should pass the argument to the 'pos_y' attribute" do
        value = -44.4
        @im.pos_y = value
        @im.pos_y.should eql value
      end

    end


    describe "#row_spacing=()" do

      it "should pass the argument to the 'row_spacing' attribute" do
        value = 3.3
        @im.row_spacing = value
        @im.row_spacing.should eql value
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
        @im.rows.should eql value
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
        @im.rows.should eql rows
        @im.columns.should eql cols
        @im.narray.shape.should eql [cols, rows]
        (@im.narray == NArray.int(cols, rows).fill(1)).should be_true
      end

      it "should reduce the number of columns as expected by :even cropping (asymmetric situation)" do
        @im.narray[0, true] = -1
        @im.set_resolution(cols=3, rows=4)
        @im.rows.should eql rows
        @im.columns.should eql cols
        @im.narray.shape.should eql [cols, rows]
        (@im.narray == NArray.int(cols, rows).fill(1)).should be_true
      end

      it "should reduce the number of columns as expected by :left cropping" do
        @im.narray[0..1, true] = -1
        @im.set_resolution(cols=2, rows=4, :hor => :left)
        @im.rows.should eql rows
        @im.columns.should eql cols
        @im.narray.shape.should eql [cols, rows]
        (@im.narray == NArray.int(cols, rows).fill(1)).should be_true
      end

      it "should reduce the number of columns as expected by :right cropping" do
        @im.narray[-2..-1, true] = -1
        @im.set_resolution(cols=2, rows=4, :hor => :right)
        @im.rows.should eql rows
        @im.columns.should eql cols
        @im.narray.shape.should eql [cols, rows]
        (@im.narray == NArray.int(cols, rows).fill(1)).should be_true
      end

      it "should expand the number of columns as expected by :even bordering (symmetric situation)" do
        @im.set_resolution(cols=6, rows=4)
        @im.rows.should eql rows
        @im.columns.should eql cols
        @im.narray.shape.should eql [cols, rows]
        expected = NArray.int(cols, rows)
        expected[1..-2, true] = 1
        (@im.narray == expected).should be_true
      end

      it "should expand the number of columns as expected by :even bordering (asymmetric situation)" do
        @im.set_resolution(cols=5, rows=4)
        @im.rows.should eql rows
        @im.columns.should eql cols
        @im.narray.shape.should eql [cols, rows]
        expected = NArray.int(cols, rows)
        expected[1..-1, true] = 1
        (@im.narray == expected).should be_true
      end

      it "should expand the number of columns as expected by :left bordering" do
        @im.set_resolution(cols=6, rows=4, :hor => :left)
        @im.rows.should eql rows
        @im.columns.should eql cols
        @im.narray.shape.should eql [cols, rows]
        expected = NArray.int(cols, rows)
        expected[2..-1, true] = 1
        (@im.narray == expected).should be_true
      end

      it "should expand the number of columns as expected by :right bordering" do
        @im.set_resolution(cols=6, rows=4, :hor => :right)
        @im.rows.should eql rows
        @im.columns.should eql cols
        @im.narray.shape.should eql [cols, rows]
        expected = NArray.int(cols, rows)
        expected[0..-3, true] = 1
        (@im.narray == expected).should be_true
      end

      it "should reduce the number of rows as expected by :even cropping (symmetric situation)" do
        @im.narray[true, [0,-1]] = -1
        @im.set_resolution(cols=4, rows=2)
        @im.rows.should eql rows
        @im.columns.should eql cols
        @im.narray.shape.should eql [cols, rows]
        (@im.narray == NArray.int(cols, rows).fill(1)).should be_true
      end

      it "should reduce the number of rows as expected by :even cropping (asymmetric situation)" do
        @im.narray[true, 0] = -1
        @im.set_resolution(cols=4, rows=3)
        @im.rows.should eql rows
        @im.columns.should eql cols
        @im.narray.shape.should eql [cols, rows]
        (@im.narray == NArray.int(cols, rows).fill(1)).should be_true
      end

      it "should reduce the number of rows as expected by :top cropping" do
        @im.narray[true, 0..1] = -1
        @im.set_resolution(cols=4, rows=2, :ver => :top)
        @im.rows.should eql rows
        @im.columns.should eql cols
        @im.narray.shape.should eql [cols, rows]
        (@im.narray == NArray.int(cols, rows).fill(1)).should be_true
      end

      it "should reduce the number of rows as expected by :bottom cropping" do
        @im.narray[true, -2..-1] = -1
        @im.set_resolution(cols=4, rows=2, :ver => :bottom)
        @im.rows.should eql rows
        @im.columns.should eql cols
        @im.narray.shape.should eql [cols, rows]
        (@im.narray == NArray.int(cols, rows).fill(1)).should be_true
      end

      it "should expand the number of rows as expected by :even bordering (symmetric situation)" do
        @im.set_resolution(cols=4, rows=6)
        @im.rows.should eql rows
        @im.columns.should eql cols
        @im.narray.shape.should eql [cols, rows]
        expected = NArray.int(cols, rows)
        expected[true, 1..-2] = 1
        (@im.narray == expected).should be_true
      end

      it "should expand the number of rows as expected by :even bordering (asymmetric situation)" do
        @im.set_resolution(cols=4, rows=5)
        @im.rows.should eql rows
        @im.columns.should eql cols
        @im.narray.shape.should eql [cols, rows]
        expected = NArray.int(cols, rows)
        expected[true, 1..-1] = 1
        (@im.narray == expected).should be_true
      end

      it "should expand the number of rows as expected by :top bordering" do
        @im.set_resolution(cols=4, rows=6, :ver => :top)
        @im.rows.should eql rows
        @im.columns.should eql cols
        @im.narray.shape.should eql [cols, rows]
        expected = NArray.int(cols, rows)
        expected[true, 2..-1] = 1
        (@im.narray == expected).should be_true
      end

      it "should expand the number of rows as expected by :bottom bordering" do
        @im.set_resolution(cols=4, rows=6, :ver => :bottom)
        @im.rows.should eql rows
        @im.columns.should eql cols
        @im.narray.shape.should eql [cols, rows]
        expected = NArray.int(cols, rows)
        expected[true, 0..-3] = 1
        (@im.narray == expected).should be_true
      end

      it "should both expand the rows as expected by :bottom bordering and reduce the columns as expected by :left cropping" do
        @im.narray[0..1, true] = -1
        @im.set_resolution(cols=2, rows=6, :hor => :left, :ver => :bottom)
        @im.rows.should eql rows
        @im.columns.should eql cols
        @im.narray.shape.should eql [cols, rows]
        expected = NArray.int(cols, rows)
        expected[true, 0..-3] = 1
        (@im.narray == expected).should be_true
      end

    end


    context "#to_image" do

      it "should return itself" do
        @im.to_image.equal?(@im).should be_true
      end

    end

  end

end
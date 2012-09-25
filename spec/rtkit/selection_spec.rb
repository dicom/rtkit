# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe Selection do

    before :each do
      @sop = '1.245.123'
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.345.789', 'CT', @f, @st)
      @ss = StructureSet.new('1.765.12', @is)
      @roi = ROI.new("Brain", 1, @f, @ss)
      @image = SliceImage.new(@sop, 9.0, @is)
      @image.cosines = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0]
      @image.col_spacing = 1.0
      @image.row_spacing = 1.0
      @image.pos_x = 0.0
      @image.pos_y = 0.0
      @columns = 10
      @rows = 10
      @narray = NArray.byte(@columns, @rows)
      @bin = BinImage.new(@narray, @image)
      @indices = [42, 24, 5]
      @sel = Selection.new(@bin)
    end

    context "::create_from_array" do

      it "should raise an ArgumentError when a non-array is passed as the 'indices' argument" do
        expect {Selection.create_from_array('not-an-array', @bin)}.to raise_error(ArgumentError, /'indices'/)
      end

      it "should raise an ArgumentError when an array containing non-integers is passed as the 'indices' argument" do
        expect {Selection.create_from_array([2, nil, 4], @bin)}.to raise_error(ArgumentError, /'indices'/)
      end

      it "should raise an ArgumentError when a non-BinImage is passed as the 'bin_image' argument" do
        expect {Selection.create_from_array(@indices, 'not-a-BinImage')}.to raise_error(ArgumentError, /'bin_image'/)
      end

      it "should return a Selection instance" do
        s = Selection.create_from_array(@indices, @bin)
        s.class.should eql Selection
      end

      it "should pass the indices array to the indices attribute" do
        s = Selection.create_from_array(@indices, @bin)
        s.indices.should eql @indices
      end

      it "should pass the indices NArray to the indices attribute, converted to an array" do
        s = Selection.create_from_array(NArray[1, 2, 3, 4], @bin)
        s.indices.should eql [1, 2, 3, 4]
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-BinImage is passed as the 'bin_image' argument" do
        expect {Selection.new('not-a-BinImage')}.to raise_error(ArgumentError, /'bin_image'/)
      end

      it "should pass the 'bin_image' argument to the 'bin_image' attribute" do
        @sel.bin_image.should eql @bin
      end

      it "should by default set the 'indices' attribute as an empty array" do
        @sel.indices.should eql Array.new
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        sel_other = Selection.new(@bin)
        (@sel == sel_other).should be_true
      end

      it "should be false when comparing two instances having different attributes" do
        sel_other = Selection.new(@bin)
        sel_other.add_indices([9,12])
        (@sel == sel_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@sel == 42).should be_false
      end

    end


    context "#add_indices" do

      it "should raise an ArgumentError when a non-array is passed as the 'indices' argument" do
        expect {@sel.add_indices('not-an-array')}.to raise_error(ArgumentError, /'indices'/)
      end

      it "should raise an ArgumentError when an array containing non-integers is passed as the 'indices' argument" do
        expect {@sel.add_indices([4, nil, 2])}.to raise_error(ArgumentError, /'indices'/)
      end

      it "should add the indices to the empty Selection instance" do
        arr = [42, 24]
        @sel.add_indices(arr)
        @sel.indices.should eql arr
      end

      it "should add the indices to the Selection instance already containing indices" do
        arr = [50, 3]
        @sel.add_indices(@indices)
        @sel.add_indices(arr)
        @sel.indices.should eql [*@indices, *arr]
      end

      it "should add the NArray indices to the Selection instance" do
        narr = NArray[50, 3]
        @sel.add_indices(@indices)
        @sel.add_indices(narr)
        @sel.indices.should eql [*@indices, *narr.to_a]
      end

    end


    context "#columns" do

      it "should return an empty array when called on an 'empty' selection" do
        @sel.columns.should eql Array.new
      end

      it "should return an array containing the expected column indices" do
        columns, rows = 3, 5
        narray = NArray.byte(columns, rows)
        bin = BinImage.new(narray, @image)
        sel = Selection.create_from_array([2, 4, 6, 10, 14], bin)
        sel.columns.should eql [2, 1, 0, 1, 2]
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        sel_other = Selection.new(@bin)
        @sel.eql?(sel_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        sel_other = Selection.new(@bin)
        sel_other.add_indices([9,12])
        @sel.eql?(sel_other).should be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        sel_other = Selection.new(@bin)
        @sel.hash.should be_a Fixnum
        @sel.hash.should eql sel_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        sel_other = Selection.new(@bin)
        sel_other.add_indices([9,12])
        @sel.hash.should_not eql sel_other.hash
      end

    end


    context "#length" do

      it "should return the length of this empty selection" do
        @sel.length.should eql 0
      end

      it "should return the length of this selection" do
        arr = [50, 3, 4, 5, 10]
        @sel.add_indices(arr)
        @sel.length.should eql arr.length
      end

    end


    context "#rows" do

      it "should return an empty array when called on an 'empty' selection" do
        @sel.rows.should eql Array.new
      end

      it "should return an array containing the expected row indices" do
        columns, rows = 3, 5
        narray = NArray.byte(columns, rows)
        bin = BinImage.new(narray, @image)
        sel = Selection.create_from_array([2, 4, 6, 10, 14], bin)
        sel.rows.should eql [0, 1, 2, 3, 4]
      end

    end


    context "#shift" do

      it "should raise an ArgumentError when a non-integer is passed as the 'delta_col' argument" do
        expect {@sel.shift('2', 1)}.to raise_error(ArgumentError, /'delta_col'/)
      end

      it "should raise an ArgumentError when a non-integer is passed as the 'delta_row' argument" do
        expect {@sel.shift(2, 1.5)}.to raise_error(ArgumentError, /'delta_row'/)
      end

      it "should not change the indices array when executed on an 'empty' selection" do
        @sel.shift(-1, -1)
        @sel.indices.should eql Array.new
      end

      it "should shift the indices as expected (negative)" do
        columns, rows = 3, 5
        narray = NArray.byte(columns, rows)
        bin = BinImage.new(narray, @image)
        sel = Selection.create_from_array([4, 8, 10], bin)
        sel.shift(-1, -1)
        sel.indices.should eql [0, 4, 6]
      end

      it "should shift the indices as expected (positive)" do
        columns, rows = 3, 5
        narray = NArray.byte(columns, rows)
        bin = BinImage.new(narray, @image)
        sel = Selection.create_from_array([0, 4, 6], bin)
        sel.shift(1, 1)
        sel.indices.should eql [4, 8, 10]
      end

    end


    context "#shift_and_crop" do

      it "should raise an ArgumentError when a non-integer is passed as the 'delta_col' argument" do
        expect {@sel.shift_and_crop('2', 1)}.to raise_error(ArgumentError, /'delta_col'/)
      end

      it "should raise an ArgumentError when a non-integer is passed as the 'delta_row' argument" do
        expect {@sel.shift_and_crop(2, 1.5)}.to raise_error(ArgumentError, /'delta_row'/)
      end

      it "should not change the indices array when executed on an 'empty' selection" do
        @sel.shift_and_crop(-1, -1)
        @sel.indices.should eql Array.new
      end

      it "should not change the indices array when executed with zero shifts" do
        @sel.add_indices(@indices)
        @sel.shift_and_crop(0, 0)
        @sel.indices.should eql @indices
      end

      it "should shift the indices as expected (negative)" do
        columns, rows = 4, 5
        narray = NArray.byte(columns, rows)
        bin = BinImage.new(narray, @image)
        sel = Selection.create_from_array([5, 6, 10], bin)
        sel.shift_and_crop(-1, -1)
        sel.indices.should eql [0, 1, 3]
      end

      it "should shift the indices as expected (positive)" do
        columns, rows = 4, 5
        narray = NArray.byte(columns, rows)
        bin = BinImage.new(narray, @image)
        sel = Selection.create_from_array([5, 6, 10], bin)
        sel.shift_and_crop(1, 1)
        sel.indices.should eql [0, 1, 3]
      end

    end


    context "#shift_columns" do

      it "should raise an ArgumentError when a non-integer is passed as the 'delta' argument" do
        expect {@sel.shift_columns('2')}.to raise_error(ArgumentError, /'delta'/)
      end

      it "should not change the indices array when executed on an 'empty' selection" do
        @sel.shift_columns(-1)
        @sel.indices.should eql Array.new
      end

      it "should shift the indices as expected (negative)" do
        columns, rows = 3, 5
        narray = NArray.byte(columns, rows)
        bin = BinImage.new(narray, @image)
        sel = Selection.create_from_array([4, 8, 10], bin)
        sel.shift_columns(-1)
        sel.indices.should eql [3, 7, 9]
      end

      it "should shift the indices as expected (positive)" do
        columns, rows = 3, 5
        narray = NArray.byte(columns, rows)
        bin = BinImage.new(narray, @image)
        sel = Selection.create_from_array([0, 4, 6], bin)
        sel.shift_columns(1)
        sel.indices.should eql [1, 5, 7]
      end

    end


    context "#shift_rows" do

      it "should raise an ArgumentError when a non-integer is passed as the 'delta' argument" do
        expect {@sel.shift_rows('2')}.to raise_error(ArgumentError, /'delta'/)
      end

      it "should not change the indices array when executed on an 'empty' selection" do
        @sel.shift_rows(-1)
        @sel.indices.should eql Array.new
      end

      it "should shift the indices as expected (negative)" do
        columns, rows = 3, 5
        narray = NArray.byte(columns, rows)
        bin = BinImage.new(narray, @image)
        sel = Selection.create_from_array([4, 8, 10], bin)
        sel.shift_rows(-1)
        sel.indices.should eql [1, 5, 7]
      end

      it "should shift the indices as expected (positive)" do
        columns, rows = 3, 5
        narray = NArray.byte(columns, rows)
        bin = BinImage.new(narray, @image)
        sel = Selection.create_from_array([0, 4, 6], bin)
        sel.shift_rows(1)
        sel.indices.should eql [3, 7, 9]
      end

    end


    context "#to_selection" do

      it "should return itself" do
        @sel.to_selection.equal?(@sel).should be_true
      end

    end

  end

end
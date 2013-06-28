# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe Contour do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.345.789', 'CT', @f, @st)
      @ss = StructureSet.new('1.765.12', @is)
      @roi = ROI.new("Brain", 1, @f, @ss)
      @s = Slice.new("1.567.898", @roi)
      @c = Contour.new(@s)
      @x = [-50.0,50.0]
      @y = [40.0,-40.0]
      @z = [0.0,100.0]
      @n = 4
      @t = 'Custom'
    end


    context "::create_from_coordinates" do

      it "should raise an ArgumentError when a non-Array is passed as the 'x' argument" do
        expect {Contour.create_from_coordinates('not-a-array', @y, @z, @s)}.to raise_error(ArgumentError, /x/)
      end

      it "should raise an ArgumentError when a non-Array is passed as the 'y' argument" do
        expect {Contour.create_from_coordinates(@x, 'not-a-array', @z, @s)}.to raise_error(ArgumentError, /y/)
      end

      it "should raise an ArgumentError when a non-Array is passed as the 'z' argument" do
        expect {Contour.create_from_coordinates(@x, @y, 'not-a-array', @s)}.to raise_error(ArgumentError, /z/)
      end

      it "should raise an ArgumentError when a non-Slice is passed as the 'slice' argument" do
        expect {Contour.create_from_coordinates(@x, @y, @z, 'not-a-Slice')}.to raise_error(ArgumentError, /slice/)
      end

      it "should raise an ArgumentError when the coordinate arrays passed as arguments are of unequal length" do
        expect {Contour.create_from_coordinates(@x, [2.0], @z, @s)}.to raise_error(ArgumentError, /length/)
      end

      it "should create a 'coordinates' array with equal length to the number of coordinates given in the input arrays" do
        c = Contour.create_from_coordinates(@x, @y, @z, @s)
        c.coordinates.length.should eql @x.length
      end

      it "should create Coordinate instances in such a way that the attributes of the first Coordinate instance matches the first values of the input arrays" do
        c = Contour.create_from_coordinates(@x, @y, @z, @s)
        [c.coordinates.first.x, c.coordinates.first.y, c.coordinates.first.z].should eql [@x.first, @y.first, @z.first]
      end

      it "should create Coordinate instances in such a way that the attributes of the last Coordinate instance matches the last values of the input arrays" do
        c = Contour.create_from_coordinates(@x, @y, @z, @s)
        [c.coordinates.last.x, c.coordinates.last.y, c.coordinates.last.z].should eql [@x.last, @y.last, @z.last]
      end

      it "should set the Contour's 'number' attribute to one more than the referenced Slice's ROI's total number of referenced Contour instances" do
        expected_number = @s.roi.num_contours + 1
        c = Contour.create_from_coordinates(@x, @y, @z, @s)
        c.number.should eql expected_number
      end

    end


    context "::create_from_item" do

      before :each do
        dcm = DICOM::DObject.read(FILE_STRUCT)
        @item = dcm['3006,0039'][0]['3006,0040'][0]
      end

      it "should raise an ArgumentError when a non-item is passed as the 'contour_item' argument" do
        expect {Contour.create_from_item('not-an-item', @s)}.to raise_error(ArgumentError, /contour_item/)
      end

      it "should raise an ArgumentError when a non-Slice is passed as the 'slice' argument" do
        expect {Contour.create_from_item(@item, 'not-a-Slice')}.to raise_error(ArgumentError, /slice/)
      end

      it "should raise an ArgumentError when the item argument does not contain a Contour Data Element Value" do
        expect {Contour.create_from_item(DICOM::Item.new, @s)}.to raise_error(ArgumentError, /Contour Data/)
      end

      it "should create a 'coordinates' array with equal length to the number of coordinates triplets given in Item's Contour Data Element" do
        c = Contour.create_from_item(@item, @s)
        c.coordinates.length.should eql @item.value('3006,0050').split("\\").length / 3
      end

      it "should create Coordinate instances in such a way that the attributes of the first Coordinate instance matches the first coordinate triplet given in the Item's Contour Data Element" do
        c = Contour.create_from_item(@item, @s)
        [c.coordinates.first.x, c.coordinates.first.y, c.coordinates.first.z].should eql @item.value('3006,0050').split("\\").collect {|c| c.to_f}[0..2]
      end

      it "should create Coordinate instances in such a way that the attributes of the last Coordinate instance matches the last coordinate triplet given in the Item's Contour Data Element" do
        c = Contour.create_from_item(@item, @s)
        [c.coordinates.last.x, c.coordinates.last.y, c.coordinates.last.z].should eql @item.value('3006,0050').split("\\").collect {|c| c.to_f}[-3..-1]
      end

      it "should set the Contour's 'number' attribute to the value given by the Item's Contour Number Element" do
        c = Contour.create_from_item(@item, @s)
        c.number.should eql @item.value('3006,0048').to_i
      end

      it "should set the Contour's 'number' attribute to the value given by the Item's Contour Geometric Type Element" do
        c = Contour.create_from_item(@item, @s)
        c.type.should eql @item.value('3006,0042')
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-Slice is passed as the 'slice' argument" do
        expect {Contour.new('not-a-Slice')}.to raise_error(ArgumentError, /slice/)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :type argument" do
        expect {Contour.new(@s, :type => 42)}.to raise_error(ArgumentError, /:type/)
      end

      it "should raise an ArgumentError when a non-Integer is passed as an optional :number argument" do
        expect {Contour.new(@s, :number => '42')}.to raise_error(ArgumentError, /:number/)
      end

      it "should pass the 'slice' argument to the 'slice' attribute" do
        @c.slice.should eql @s
      end

      it "should pass the optional :type argument to the 'type' attribute" do
        c = Contour.new(@s, :type => @t)
        c.type.should eql @t
      end

      it "should pass the optional :number argument to the 'number' attribute" do
        c = Contour.new(@s, :number => @n)
        c.number.should eql @n
      end

      it "should by default set the 'type' attribute to 'CLOSED_PLANAR'" do
        @c.type.should eql 'CLOSED_PLANAR'
      end

      it "should set the 'coordinates' attribute as an empty array when creating a new Contour" do
        @c.coordinates.should eql Array.new
      end

      it "should add the Contour instance (once) to the referenced Slice" do
        @s.contours.length.should eql 1
        @s.contours.first.should eql @c
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        c_other = Contour.new(@s)
        (@c == c_other).should be_true
      end

      it "should be false when comparing two instances having different attributes" do
        c_other = Contour.create_from_coordinates(@x, @y, @z, @s)
        (@c == c_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@c == 42).should be_false
      end

    end


    context "#add_coordinate" do

      it "should raise an ArgumentError when a non-Coordinate is passed as the 'coordinate' argument" do
        expect {@c.add_coordinate('not-a-coordinate')}.to raise_error(ArgumentError, /coordinate/)
      end

      it "should add the Coordinate to the empty Contour instance" do
        c_other = Contour.new(@s)
        coord = Coordinate.new(x=-42.0, y=42.0, z=4.2, c_other)
        @c.add_coordinate(coord)
        @c.coordinates.size.should eql 1
        [@c.coordinates.first.x, @c.coordinates.first.y, @c.coordinates.first.z].should eql [x, y, z]
      end

      it "should add the Coordinate to the Contour instance already containing coordinates" do
        c = Contour.create_from_coordinates(@x, @y, @z, @s)
        previous_size = c.coordinates.size
        coord = Coordinate.new(x=-42.0, y=42.0, z=4.2, c)
        c.coordinates.size.should eql previous_size + 1
        [c.coordinates.last.x, c.coordinates.last.y, c.coordinates.last.z].should eql [x, y, z]
      end

      it "should not add multiple entries of the same Coordinate" do
        coord = Coordinate.new(x=-42.0, y=42.0, z=4.2, @c)
        @c.add_coordinate(coord)
        @c.coordinates.size.should eql 1
        @c.coordinates.first.should eql coord
      end

    end


    context "#contour_data" do

      it "should return an empty string when called on a Contour containing no coordinates" do
        c = Contour.new(@s)
        c.contour_data.should eql ''
      end

      it "should return a properly formatted Contour Data string" do
        c = Contour.new(@s)
        coord = Coordinate.new(x=-42.0, y=42.0, z=4.2, c)
        c.contour_data.should eql [x, y, z].join("\\")
      end

    end


    context "#coords" do

      it "should return empty arrays when called on a Contour containing no coordinates" do
        c = Contour.new(@s)
        c.coords.should eql [[], [], []]
      end

      it "should return the proper x, y, and z arrays when called on a Contour with coordinates" do
        c = Contour.new(@s)
        c1 = Coordinate.new(x1=-42.0, y1=42.0, z1=4.2, c)
        c2 = Coordinate.new(x2=-24.0, y2=24.0, z2=2.4, c)
        c.coords.should eql [[x1, x2], [y1, y2], [z1, z2]]
      end

    end


    context "#create_coordinates" do

      it "should raise an ArgumentError when an argument is passed and it is not a string" do
        c = Contour.new(@s)
        expect {c.create_coordinates(42.0)}.to raise_error(ArgumentError, /contour_data/)
      end

      it "should do nothing when given nil as argument" do
        c = Contour.new(@s)
        c.create_coordinates(nil)
        c.coordinates.size.should eql 0
      end

      it "should do nothing when given an empty string as argument" do
        c = Contour.new(@s)
        c.create_coordinates('')
        c.coordinates.size.should eql 0
      end

      it "should create coordinates when given a Contour Data string" do
        c = Contour.new(@s)
        c.create_coordinates("1.0\\2.0\\3.0\\11.0\\22.0\\33.0")
        c.coords.should eql [[1.0, 11.0], [2.0, 22.0], [3.0, 33.0]]
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        c_other = Contour.new(@s)
        @c.eql?(c_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        c_other = Contour.create_from_coordinates(@x, @y, @z, @s)
        @c.eql?(c_other).should be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        c_other = Contour.new(@s)
        @c.hash.should be_a Fixnum
        @c.hash.should eql c_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        c_other = Contour.create_from_coordinates(@x, @y, @z, @s)
        @c.hash.should_not eql c_other.hash
      end

    end


    context "#size" do

      it "should return 0 when called on an empty Contour instance" do
        c = Contour.new(@s)
        c.coordinates.size.should eql 0
      end

      it "should return 2 when called on a Contour instance containing two coordinates" do
        c = Contour.create_from_coordinates(@x, @y, @z, @s)
        c.coordinates.size.should eql 2
      end

    end


    context "#to_contour" do

      it "should return itself" do
        @c.to_contour.equal?(@c).should be_true
      end

    end


    context "#to_item" do

      it "should return a properly constructed Contour Sequence Item" do
        d = DataSet.read(DIR_SIMPLE_PHANTOM_CONTOURS)
        img_series = d.patient.study.image_series.first
        roi = img_series.struct.roi('External')
        c = roi.slices.last.contours.last # Checking the last Contour Sequence Item of the External ROI in this Structure Set.
        item = c.to_item
        item.count.should eql 5
        item.count_all.should eql 8
        item.value('3006,0042').should eql 'CLOSED_PLANAR'
        item.value('3006,0046').should eql '4'
        item.value('3006,0048').should eql '5'
        item.value('3006,0050').should eql '10.0\-40.0\-150.0\10.0\10.0\-150.0\-40.0\10.0\-150.0\-40.0\-40.0\-150.0'
        item['3006,0016'][0].value('0008,1150').should eql '1.2.840.10008.5.1.4.1.1.2'
        item['3006,0016'][0].value('0008,1155').should eql '1.3.6.1.4.1.2452.6.3088093158.1119034649.658647702.2446811209'
      end

    end


    context "#translate" do

      it "should call the translate method on all coordinates belonging to the contour, with the given offsets" do
        coord1 = Coordinate.new(1, 2, 3, @c)
        coord2 = Coordinate.new(-6, -5, 4, @c)
        x_offset = -5
        y_offset = 10.4
        z_offset = -99.0
        coord1.expects(:translate).with(x_offset, y_offset, z_offset)
        coord2.expects(:translate).with(x_offset, y_offset, z_offset)
        @c.translate(x_offset, y_offset, z_offset)
      end

    end

  end

end
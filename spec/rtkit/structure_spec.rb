# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe Structure do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.345.789', 'CT', @f, @st)
      @ss = StructureSet.new('1.765.12', @is)
      @name = 'Test'
      @number = 12
      @soi = Structure.new(@name, @number, @f, @ss)
      @sop = '1.245.123'
    end


    context "::create_from_items [with ROI]" do

      before :each do
        dcm = DICOM::DObject.read(FILE_STRUCT)
        @roi_item = dcm['3006,0020'][0]
        @contour_item = dcm['3006,0039'][0]
        @rt_item = dcm['3006,0080'][0]
      end

      it "should raise an ArgumentError when a non-Item is passed as the 'roi_item' argument" do
        expect {Structure.create_from_items('non-Item', @contour_item, @rt_item, @ss)}.to raise_error(ArgumentError, /roi_item/)
      end

      it "should raise an ArgumentError when a non-Item is passed as the 'contour_item' argument" do
        expect {Structure.create_from_items(@roi_item, 'non-Item', @rt_item, @ss)}.to raise_error(ArgumentError, /contour_item/)
      end

      it "should raise an ArgumentError when a non-Item is passed as the 'rt_item' argument" do
        expect {Structure.create_from_items(@roi_item, @contour_item, 'non-Item', @ss)}.to raise_error(ArgumentError, /rt_item/)
      end

      it "should raise an ArgumentError when a non-StructureSet is passed as the 'struct' argument" do
        expect {Structure.create_from_items(@roi_item, @contour_item, @rt_item, 'not-a-struct')}.to raise_error(ArgumentError, /struct/)
      end

      it "should return a ROI instance" do
        roi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(roi).to be_a ROI
      end

      it "should fill the 'slices' array attribute with Slices created from the items" do
        roi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(roi.slices.length).to eql @contour_item['3006,0040'].count
        expect(roi.slices.first.class).to eql Slice
      end

      it "should set the ROI's 'algorithm' attribute equal to that of the value found in the Structure Set ROI Item" do
        roi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(roi.algorithm).to eql @roi_item.value('3006,0036')
      end

      it "should set the ROI's 'name' attribute equal to that of the value found in the Structure Set ROI Item" do
        roi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(roi.name).to eql @roi_item.value('3006,0026')
      end

      it "should set the ROI's 'number' attribute equal to that of the value found in the Structure Set ROI Item" do
        roi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(roi.number).to eql @roi_item.value('3006,0022').to_i
      end

      it "should set the ROI's 'type' attribute equal to that of the value found in the RT ROI Observations Item" do
        roi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(roi.type).to eql @rt_item.value('3006,00A4')
      end

      it "should set the ROI's 'interpreter' attribute equal to that of the value found in the RT ROI Observations Item" do
        roi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        value = @contour_item.value('3006,00A6') || ""
        expect(roi.interpreter).to eql value
      end

      it "should set the ROI's 'color' attribute equal to that of the value found in the ROI Contour Item" do
        roi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(roi.color).to eql @contour_item.value('3006,002A')
      end

      it "should set the ROI's 'struct' attribute equal to the 'struct' argument" do
        roi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(roi.struct).to eql @ss
      end

      it "should create a referenced Frame instance who's UID matches the value of the Frame UID tag of the 'ROI Item'" do
        roi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(roi.frame.uid).to eql @roi_item.value('3006,0024')
      end

    end


    context "::create_from_items [with POI]" do

      before :each do
        dcm = DICOM::DObject.read(FILE_STRUCT)
        @roi_item = dcm['3006,0020'][3]
        @contour_item = dcm['3006,0039'][3]
        @rt_item = dcm['3006,0080'][3]
      end

      it "should raise an ArgumentError when a non-Item is passed as the 'roi_item' argument" do
        expect {Structure.create_from_items('non-Item', @contour_item, @rt_item, @ss)}.to raise_error(ArgumentError, /roi_item/)
      end

      it "should raise an ArgumentError when a non-Item is passed as the 'contour_item' argument" do
        expect {Structure.create_from_items(@roi_item, 'non-Item', @rt_item, @ss)}.to raise_error(ArgumentError, /contour_item/)
      end

      it "should raise an ArgumentError when a non-Item is passed as the 'rt_item' argument" do
        expect {Structure.create_from_items(@roi_item, @contour_item, 'non-Item', @ss)}.to raise_error(ArgumentError, /rt_item/)
      end

      it "should raise an ArgumentError when a non-StructureSet is passed as the 'struct' argument" do
        expect {Structure.create_from_items(@roi_item, @contour_item, @rt_item, 'not-a-struct')}.to raise_error(ArgumentError, /struct/)
      end

      it "should return a POI instance" do
        poi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(poi).to be_a POI
      end

      it "should create a coordinate extracted from the contour item" do
        poi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(poi.coordinate.to_s.split("\\").collect {|val| val.to_f.round(1)}).to eql @contour_item['3006,0040'][0].value('3006,0050').split("\\").collect {|val| val.to_f.round(1)}
      end

      it "should set the POI's 'uid' attribute equal to that of the value found in the ROI Contour Item" do
        poi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(poi.uid).to eql @contour_item['3006,0040'][0]['3006,0016'][0].value('0008,1155')
      end

      it "should set the POI's 'algorithm' attribute equal to that of the value found in the Structure Set ROI Item" do
        poi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(poi.algorithm).to eql @roi_item.value('3006,0036')
      end

      it "should set the POI's 'name' attribute equal to that of the value found in the Structure Set ROI Item" do
        poi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(poi.name).to eql @roi_item.value('3006,0026')
      end

      it "should set the POI's 'number' attribute equal to that of the value found in the Structure Set ROI Item" do
        poi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(poi.number).to eql @roi_item.value('3006,0022').to_i
      end

      it "should set the POI's 'type' attribute equal to that of the value found in the RT ROI Observations Item" do
        poi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(poi.type).to eql @rt_item.value('3006,00A4')
      end

      it "should set the POI's 'interpreter' attribute equal to that of the value found in the RT ROI Observations Item" do
        poi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        value = @contour_item.value('3006,00A6') || ""
        expect(poi.interpreter).to eql value
      end

      it "should set the POI's 'color' attribute equal to that of the value found in the ROI Contour Item" do
        poi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(poi.color).to eql @contour_item.value('3006,002A')
      end

      it "should set the POI's 'struct' attribute equal to the 'struct' argument" do
        poi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(poi.struct).to eql @ss
      end

      it "should create a referenced Frame instance who's UID matches the value of the Frame UID tag of the 'ROI Item'" do
        poi = Structure.create_from_items(@roi_item, @contour_item, @rt_item, @ss)
        expect(poi.frame.uid).to eql @roi_item.value('3006,0024')
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-String is passed as a 'name' argument" do
        expect {Structure.new(42, @number, @f, @ss)}.to raise_error(ArgumentError, /name/)
      end

      it "should raise an ArgumentError when a non-Integer is passed as a 'number' argument" do
        expect {Structure.new(@name, 'NaN', @f, @ss)}.to raise_error(ArgumentError, /number/)
      end

      it "should raise an ArgumentError when a non-Frame is passed as a 'frame' argument" do
        expect {Structure.new(@name, @number, 'not-a-frame', @ss)}.to raise_error(ArgumentError, /frame/)
      end

      it "should raise an ArgumentError when a non-StructureSet is passed as a 'struct' argument" do
        expect {Structure.new(@name, @number, @f, 'not-a-struct')}.to raise_error(ArgumentError, /struct/)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :algorithm argument" do
        expect {Structure.new(@name, @number, @f, @ss, :algorithm => 42)}.to raise_error(ArgumentError, /:algorithm/)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :type argument" do
        expect {Structure.new(@name, @number, @f, @ss, :type => 42)}.to raise_error(ArgumentError, /:type/)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :interpreter argument" do
        expect {Structure.new(@name, @number, @f, @ss, :interpreter => 42)}.to raise_error(ArgumentError, /:interpreter/)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :color argument" do
        expect {Structure.new(@name, @number, @f, @ss, :color => 42)}.to raise_error(ArgumentError, /:color/)
      end

      it "should pass the 'name' argument to the 'name' attribute" do
        expect(@soi.name).to eql @name
      end

      it "should pass the 'number' argument to the 'number' attribute" do
        expect(@soi.number).to eql @number
      end

      it "should pass the 'frame' argument to the 'frame' attribute" do
        expect(@soi.frame).to eql @f
      end

      it "should pass the 'struct' argument to the 'struct' attribute" do
        expect(@soi.struct).to eql @ss
      end

      it "should by default set the 'algorithm' attribute to 'Automatic'" do
        expect(@soi.algorithm).to eql 'Automatic'
      end

      it "should by default set the 'type' attribute to a 'CONTROL'" do
        expect(@soi.type).to eql 'CONTROL'
      end

      it "should by default set the 'interpreter' attribute to 'RTKIT'" do
        expect(@soi.interpreter).to eql 'RTKIT'
      end

      it "should by default set the 'color' attribute to a proper color string" do
        expect(@soi.color.class).to eql String
        expect(@soi.color.split("\\").length).to eql 3
      end

      it "should not add the Structure instance itself to the referenced StructureSet" do
        expect(@ss.structures.length).to eql 0
      end

      it "should not add the Structure instance itself to the referenced Frame" do
        expect(@f.structures.length).to eql 0
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        soi = Structure.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        soi_other = Structure.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        expect(soi == soi_other).to be_true
      end

      it "should be false when comparing two instances having different attributes" do
        soi_other = Structure.new('Other ROI', @number, @f, @ss)
        expect(@soi == soi_other).to be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@soi == 42).to be_false
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        soi = Structure.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        soi_other = Structure.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        expect(soi.eql?(soi_other)).to be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        soi_other = Structure.new('Other ROI', @number, @f, @ss)
        expect(@soi.eql?(soi_other)).to be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        soi = Structure.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        soi_other = Structure.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        expect(soi.hash).to be_a Fixnum
        expect(soi.hash).to eql soi_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        soi_other = Structure.new('Other ROI', @number, @f, @ss)
        expect(@soi.hash).not_to eql soi_other.hash
      end

    end


    context "#to_structure" do

      it "should return itself" do
        expect(@soi.to_structure.equal?(@soi)).to be_true
      end

    end


  end

end
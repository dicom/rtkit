# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe POI do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.345.789', 'CT', @f, @st)
      @ss = StructureSet.new('1.765.12', @is)
      @name = 'Test'
      @number = 12
      @poi = POI.new(@name, @number, @f, @ss)
      @sop = '1.245.123'
    end



    context "::new" do

      it "should raise an ArgumentError when a non-String is passed as a 'name' argument" do
        expect {POI.new(42, @number, @f, @ss)}.to raise_error(ArgumentError, /name/)
      end

      it "should raise an ArgumentError when a non-Integer is passed as a 'number' argument" do
        expect {POI.new(@name, 'NaN', @f, @ss)}.to raise_error(ArgumentError, /number/)
      end

      it "should raise an ArgumentError when a non-Frame is passed as a 'frame' argument" do
        expect {POI.new(@name, @number, 'not-a-frame', @ss)}.to raise_error(ArgumentError, /frame/)
      end

      it "should raise an ArgumentError when a non-StructureSet is passed as a 'struct' argument" do
        expect {POI.new(@name, @number, @f, 'not-a-struct')}.to raise_error(ArgumentError, /struct/)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :algorithm argument" do
        expect {POI.new(@name, @number, @f, @ss, :algorithm => 42)}.to raise_error(ArgumentError, /:algorithm/)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :type argument" do
        expect {POI.new(@name, @number, @f, @ss, :type => 42)}.to raise_error(ArgumentError, /:type/)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :interpreter argument" do
        expect {POI.new(@name, @number, @f, @ss, :interpreter => 42)}.to raise_error(ArgumentError, /:interpreter/)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :color argument" do
        expect {POI.new(@name, @number, @f, @ss, :color => 42)}.to raise_error(ArgumentError, /:color/)
      end

      it "should pass the 'name' argument to the 'name' attribute" do
        expect(@poi.name).to eql @name
      end

      it "should pass the 'number' argument to the 'number' attribute" do
        expect(@poi.number).to eql @number
      end

      it "should pass the 'frame' argument to the 'frame' attribute" do
        expect(@poi.frame).to eql @f
      end

      it "should pass the 'struct' argument to the 'struct' attribute" do
        expect(@poi.struct).to eql @ss
      end

      it "should by default set the 'coordinate' attribute to nil" do
        expect(@poi.coordinate).to be_nil
      end

      it "should by default set the 'image' attribute to nil" do
        expect(@poi.image).to be_nil
      end

      it "should by default set the 'algorithm' attribute to 'Automatic'" do
        expect(@poi.algorithm).to eql 'Automatic'
      end

      it "should by default set the 'type' attribute to a 'CONTROL'" do
        expect(@poi.type).to eql 'CONTROL'
      end

      it "should by default set the 'interpreter' attribute to 'RTKIT'" do
        expect(@poi.interpreter).to eql 'RTKIT'
      end

      it "should by default set the 'color' attribute to a proper color string" do
        expect(@poi.color.class).to eql String
        expect(@poi.color.split("\\").length).to eql 3
      end

      it "should add the POI instance (once) to the referenced StructureSet" do
        expect(@ss.structures.length).to eql 1
        expect(@ss.structure(@poi.name)).to eql @poi
      end

      it "should add the POI instance (once) to the referenced Frame" do
        expect(@f.structures.length).to eql 1
        expect(@f.structure(@poi.name)).to eql @poi
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        poi = POI.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        poi_other = POI.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        expect(poi == poi_other).to be true
      end

      it "should be false when comparing two instances having different attributes" do
        poi_other = POI.new('Other POI', @number, @f, @ss)
        expect(@poi == poi_other).to be false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@poi == 42).to be_falsey
      end

    end


    context "#contour_item" do

      before :each do
        @poi = POI.new(@name, @number, @f, @ss)
      end

      it "should return a ROI Contour Sequence Item properly populated with values from the POI instance" do
        item = @poi.contour_item
        expect(item.class).to eql DICOM::Item
        expect(item.count).to eql 3
        expect(item.value('3006,002A')).to eql @poi.color
        expect(item.value('3006,0084')).to eql @poi.number.to_s
        expect(item['3006,0040'][0].value('3006,0042')).to eql 'POINT'
        expect(item['3006,0040'][0].value('3006,0046')).to eql '1'
        expect(item['3006,0040'][0].value('3006,0048')).to eql @poi.number.to_s
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        poi = POI.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        poi_other = POI.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        expect(poi.eql?(poi_other)).to be true
      end

      it "should be false when comparing two instances having different attribute values" do
        POI_other = POI.new('Other POI', @number, @f, @ss)
        expect(@POI.eql?(POI_other)).to be false
      end

    end


    context "#frame=()" do

      it "should raise an when a non-Frame is passed" do
        expect {@poi.frame = 'not-a-frame'}.to raise_error(/to_frame/)
      end

      it "should assign the new frame to the POI" do
        f_other = Frame.new('1.787.434', @p)
        @poi.frame = f_other
        expect(@poi.frame).to eql f_other
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        poi = POI.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        poi_other = POI.new(@name, @number, @f, @ss, :color => "0\\0\\0")
        expect(poi.hash).to be_a Fixnum
        expect(poi.hash).to eql poi_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        poi_other = POI.new('Other POI', @number, @f, @ss)
        expect(@poi.hash).not_to eql poi_other.hash
      end

    end


    context "#obs_item" do

      it "should return a RT ROI Observations Sequence Item properly populated with values from the POI instance" do
        poi = POI.new(@name, @number, @f, @ss)
        item = poi.obs_item
        expect(item.class).to eql DICOM::Item
        expect(item.count).to eql 4
        expect(item.value('3006,0082')).to eql poi.number.to_s
        expect(item.value('3006,0084')).to eql poi.number.to_s
        expect(item.value('3006,00A4')).to eql poi.type
        expect(item.value('3006,00A6')).to eql poi.interpreter
      end

    end


    context "#remove_references" do

      it "should nullify the 'frame' and 'struct' attributes of the POI instance" do
        poi = POI.new(@name, @number, @f, @ss)
        poi.remove_references
        expect(poi.frame).to be_nil
        expect(poi.struct).to be_nil
      end

    end


    context "#ss_item" do

      it "should return a Structure Set ROI Sequence Item properly populated with values from the POI instance" do
        poi = POI.new(@name, @number, @f, @ss)
        item = poi.ss_item
        expect(item.class).to eql DICOM::Item
        expect(item.count).to eql 4
        expect(item.value('3006,0022')).to eql poi.number.to_s
        expect(item.value('3006,0024')).to eql poi.frame.uid
        expect(item.value('3006,0026')).to eql poi.name
        expect(item.value('3006,0036')).to eql poi.algorithm
      end

    end


    context "#to_poi" do

      it "should return itself" do
        expect(@poi.to_poi.equal?(@poi)).to be true
      end

    end


    context "#translate" do

      it "should call the translate method on the POI's coordinate instance" do
        c = Coordinate.new(0, 2, -4)
        @poi.coordinate = c
        x_offset = -5
        y_offset = 10.4
        z_offset = -99.0
        c.expects(:translate).with(x_offset, y_offset, z_offset)
        @poi.translate(x_offset, y_offset, z_offset)
      end

    end

  end

end
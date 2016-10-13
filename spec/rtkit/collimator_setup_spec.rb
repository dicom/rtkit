# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe CollimatorSetup do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.987.3', 'CT', @f, @st)
      @ss = StructureSet.new('1.765.354', @is)
      @plan = Plan.new('1.345.789', @ss)
      @beam = Beam.new('AP', 1, 'Linac', 100.0, @plan)
      @cp = ControlPoint.new(2, 1.0, @beam)
      @type = 'ASYMX'
      @pos = [[-10.0, 15.0]]
      @coll = CollimatorSetup.new(@type, @pos, @cp)
    end

    context "::create_from_item" do

      before :each do
        dcm = DICOM::DObject.read(FILE_PLAN)
        @coll_item = dcm['300A,00B0'][0]['300A,0111'][0]['300A,011A'][0]
      end

      it "should raise an ArgumentError when a non-Item is passed as the 'coll_item' argument" do
        expect {CollimatorSetup.create_from_item('non-Item', @cp)}.to raise_error(ArgumentError, /'coll_item'/)
      end

      it "should raise an ArgumentError when a non-ControlPoint is passed as the 'control_point' argument" do
        expect {CollimatorSetup.create_from_item(@coll_item, 'not-a-cp')}.to raise_error(ArgumentError, /'control_point'/)
      end

      it "should set the CollimatorSetup's 'type' attribute equal to the value found in the Item" do
        coll = CollimatorSetup.create_from_item(@coll_item, @cp)
        expect(coll.type).to eql @coll_item.value('300A,00B8')
      end

      it "should set the CollimatorSetup's 'positions' attribute equal to the value found in the Item" do
        coll = CollimatorSetup.create_from_item(@coll_item, @cp)
        expect(coll.positions).to eql [@coll_item.value('300A,011C').split("\\").collect{|s| s.to_f}]
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a value is not given as a 'type' argument" do
        expect {CollimatorSetup.new(nil, @pos, @cp)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a value is not given as a 'positions' argument" do
        expect {CollimatorSetup.new(@type, nil, @cp)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-ControlPoint is passed as a 'control_point' argument" do
        expect {CollimatorSetup.new(@type, @pos, 'not-a-cp')}.to raise_error(ArgumentError, /'control_point'/)
      end

      it "should pass the 'type' argument to the 'type' attribute" do
        expect(@coll.type).to eql @type
      end

      it "should pass the 'positions' argument to the 'positions' attribute" do
        expect(@coll.positions).to eql @pos
      end

      it "should add the CollimatorSetup instance to the referenced ControlPoint" do
        expect(@cp.collimator).to eql @coll
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        coll_other = CollimatorSetup.new(@type, @pos, @cp)
        expect(@coll == coll_other).to be true
      end

      it "should be false when comparing two instances having different attributes" do
        coll_other = CollimatorSetup.new('MLCY', @pos, @cp)
        expect(@coll == coll_other).to be false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@coll == 42).to be_falsey
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        coll_other = CollimatorSetup.new(@type, @pos, @cp)
        expect(@coll.eql?(coll_other)).to be true
      end

      it "should be false when comparing two instances having different attribute values" do
        coll_other = CollimatorSetup.new('MLCY', @pos, @cp)
        expect(@coll.eql?(coll_other)).to be false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        coll_other = CollimatorSetup.new(@type, @pos, @cp)
        expect(@coll.hash).to be_a Fixnum
        expect(@coll.hash).to eql coll_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        coll_other = CollimatorSetup.new('MLCY', @pos, @cp)
        expect(@coll.hash).not_to eql coll_other.hash
      end

    end


    context "#positions=()" do

      it "should raise an ArgumentError when a value is not given" do
        expect {@coll.positions = nil}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = [[-50, 45.0]]
        @coll.positions = value
        expect(@coll.positions).to eql value
      end

      it "should convert the string containing one pair of values to an array" do
        value = "-50.0\\45.5"
        @coll.positions = value
        expect(@coll.positions).to eql [[-50.0, 45.5]]
      end

      it "should convert the string containing two pairs of values to an array" do
        value = "-50.0\\-50.5\\40.5\\40.0"
        @coll.positions = value
        expect(@coll.positions).to eql [[-50.0, 40.5], [-50.5, 40.0]]
      end

    end


    context "#to_collimator_setup" do

      it "should return itself" do
        expect(@coll.to_collimator_setup.equal?(@coll)).to be true
      end

    end


    context "#to_item" do

      it "should return a Beam Limiting Device Position Sequence Item properly populated with values from the CollimatorSetup instance" do
        dcm = DICOM::DObject.read(FILE_PLAN)
        coll_item = dcm['300A,00B0'][0]['300A,0111'][0]['300A,011A'][0]
        coll = CollimatorSetup.create_from_item(coll_item, @cp)
        item = coll.to_item
        expect(item.count).to eql 2
        expect(item.value('300A,00B8')).to eql coll_item.value('300A,00B8')
        expect(item.value('300A,011C').split("\\").collect{|s| s.to_f}).to eql coll_item.value('300A,011C').split("\\").collect{|s| s.to_f}
      end

    end

    context "#type=()" do

      it "should raise an ArgumentError when a value is not given" do
        expect {@coll.type = nil}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = 'MLCX'
        @coll.type = value
        expect(@coll.type).to eql value
      end

    end

  end

end
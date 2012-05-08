# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe Collimator do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.987.3', 'CT', @f, @st)
      @ss = StructureSet.new('1.765.354', @is)
      @plan = Plan.new('1.345.789', @ss)
      @beam = Beam.new('AP', 1, 'Linac', 100.0, @plan)
      @type = 'ASYMX'
      @num = 1
      @boundaries = [-100.0, 0.0, 100.0]
      @coll = Collimator.new(@type, @num, @beam)
    end

    context "::create_from_item" do

      before :each do
        dcm = DICOM::DObject.read(FILE_PLAN)
        @coll_item = dcm['300A,00B0'][0]['300A,00B6'][0]
      end

      it "should raise an ArgumentError when a non-Item is passed as the 'coll_item' argument" do
        expect {Collimator.create_from_item('non-Item', @beam)}.to raise_error(ArgumentError, /'coll_item'/)
      end

      it "should raise an ArgumentError when a non-Beam is passed as the 'beam' argument" do
        expect {Collimator.create_from_item(@coll_item, 'not-a-beam')}.to raise_error(ArgumentError, /'beam'/)
      end

      it "should set the Collimator's 'type' attribute equal to the value found in the Item" do
        coll = Collimator.create_from_item(@coll_item, @beam)
        coll.type.should eql @coll_item.value('300A,00B8')
      end

      it "should set the Collimator's 'type' attribute equal to the value found in the Item" do
        coll = Collimator.create_from_item(@coll_item, @beam)
        coll.num_pairs.should eql @coll_item.value('300A,00BC').to_i
      end

      it "should set the Collimator's 'boundaries' attribute from the value found in the Item" do
        @coll_item.add(DICOM::Element.new('300A,00BE', "-50.0\\0.0\\50.0"))
        coll = Collimator.create_from_item(@coll_item, @beam)
        coll.boundaries.should eql [-50.0, 0.0, 50.0]
      end

      it "should set the Collimator's 'boundaries' attribute as nil when the Item doesn't contain it" do
        coll = Collimator.create_from_item(@coll_item, @beam)
        coll.boundaries.should be_nil
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a value is not given as a 'type' argument" do
        expect {Collimator.new(nil, @num, @beam)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a value is not given as a 'num_pairs' argument" do
        expect {Collimator.new(@type, nil, @beam)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-Beam is passed as a 'beam' argument" do
        expect {Collimator.new(@type, @num, 'not-a-beam')}.to raise_error(ArgumentError, /'beam'/)
      end

      it "should pass the 'type' argument to the 'type' attribute" do
        @coll.type.should eql @type
      end

      it "should pass the 'num_pairs' argument to the 'num_pairs' attribute" do
        @coll.num_pairs.should eql @num
      end

      it "should pass the 'boundaries' option to the 'boundaries' attribute" do
        coll = Collimator.new(@type, @num, @beam, :boundaries => @boundaries)
        coll.boundaries.should eql @boundaries
      end

      it "should add the Collimator instance to the referenced Beam" do
        @beam.collimator.should eql @coll
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        coll_other = Collimator.new(@type, @num, @beam)
        (@coll == coll_other).should be_true
      end

      it "should be false when comparing two instances having different attributes" do
        coll_other = Collimator.new('MLCY', @num, @beam)
        (@coll == coll_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@coll == 42).should be_false
      end

    end


    context "#boundaries=()" do

      it "should assign nil to the referenced attribute" do
        value = nil
        @coll.boundaries = value
        @coll.boundaries.should eql value
      end

      it "should assign the value to the referenced attribute" do
        value = [-50, 0.0, 50.0]
        @coll.boundaries = value
        @coll.boundaries.should eql value
      end

      it "should convert the string containing a set of values to an array" do
        value = "-50.0\\0.0\\50.0"
        @coll.boundaries = value
        @coll.boundaries.should eql [-50.0, 0.0, 50.0]
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        coll_other = Collimator.new(@type, @num, @beam)
        @coll.eql?(coll_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        coll_other = Collimator.new('MLCY', @num, @beam)
        @coll.eql?(coll_other).should be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        coll_other = Collimator.new(@type, @num, @beam)
        @coll.hash.should be_a Fixnum
        @coll.hash.should eql coll_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        coll_other = Collimator.new('MLCY', @num, @beam)
        @coll.hash.should_not eql coll_other.hash
      end

    end


    context "#num_pairs=()" do

      it "should raise an ArgumentError when a value is not given" do
        expect {@coll.num_pairs = nil}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = 4
        @coll.num_pairs = value
        @coll.num_pairs.should eql value
      end

    end


    context "#to_collimator" do

      it "should return itself" do
        @coll.to_collimator.equal?(@coll).should be_true
      end

    end


    context "#type=()" do

      it "should raise an ArgumentError when a value is not given" do
        expect {@coll.type = nil}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = 'MLCX'
        @coll.type = value
        @coll.type.should eql value
      end

    end


=begin
    context "#to_item" do

      it "should return a Beam Limiting Device Position Sequence Item properly populated with values from the Collimator instance" do
        dcm = DICOM::DObject.read(FILE_PLAN)
        coll_item = dcm['300A,00B0'][0]['300A,0111'][0]['300A,011A'][0]
        coll = Collimator.create_from_item(coll_item, @beam)
        item = coll.to_item
        item.count.should eql 2
        item.value('300A,00B8').should eql coll_item.value('300A,00B8')
        item.value('300A,011C').split("\\").collect{|s| s.to_f}.should eql coll_item.value('300A,011C').split("\\").collect{|s| s.to_f}
      end

    end
=end

  end

end
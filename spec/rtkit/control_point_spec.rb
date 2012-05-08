# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe ControlPoint do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.987.3', 'CT', @f, @st)
      @cps = StructureSet.new('1.765.354', @is)
      @plan = Plan.new('1.345.789', @cps)
      @beam = Beam.new('AP', 1, 'Linac', 100.0, @plan)
      @index = 2
      @cum_meterset = 1.0
      @cp = ControlPoint.new(@index, @cum_meterset, @beam)
    end

    context "::create_from_item" do

      before :each do
        dcm = DICOM::DObject.read(FILE_PLAN)
        @cp_item = dcm['300A,00B0'][0]['300A,0111'][0]
      end

      it "should raise an ArgumentError when a non-Item is passed as the 'cp_item' argument" do
        expect {ControlPoint.create_from_item('non-Item', @beam)}.to raise_error(ArgumentError, /'cp_item'/)
      end

      it "should raise an ArgumentError when a non-Beam is passed as the 'beam' argument" do
        expect {ControlPoint.create_from_item(@cp_item, 'not-a-beam')}.to raise_error(ArgumentError, /'beam'/)
      end

      it "should set the ControlPoint's 'collimator_angle' attribute equal to the value found in the ControlPoint Item" do
        s = ControlPoint.create_from_item(@cp_item, @beam)
        s.collimator_angle.should eql @cp_item.value('300A,0120').to_f
      end

      it "should set the ControlPoint's 'collimator_direction' attribute equal to the value found in the ControlPoint Item" do
        s = ControlPoint.create_from_item(@cp_item, @beam)
        s.collimator_direction.should eql @cp_item.value('300A,0121')
      end

      it "should set the ControlPoint's 'cum_meterset' attribute equal to the value found in the ControlPoint Item" do
        s = ControlPoint.create_from_item(@cp_item, @beam)
        s.cum_meterset.should eql @cp_item.value('300A,0134').to_f
      end

      it "should set the ControlPoint's 'energy' attribute equal to the value found in the ControlPoint Item" do
        s = ControlPoint.create_from_item(@cp_item, @beam)
        s.energy.should eql @cp_item.value('300A,0114').to_f
      end

      it "should set the ControlPoint's 'gantry_angle' attribute equal to the value found in the ControlPoint Item" do
        s = ControlPoint.create_from_item(@cp_item, @beam)
        s.gantry_angle.should eql @cp_item.value('300A,011E').to_f
      end

      it "should set the ControlPoint's 'gantry_direction' attribute equal to the value found in the ControlPoint Item" do
        s = ControlPoint.create_from_item(@cp_item, @beam)
        s.gantry_direction.should eql @cp_item.value('300A,011F')
      end

      it "should set the ControlPoint's 'index' attribute equal to the value found in the ControlPoint Item" do
        s = ControlPoint.create_from_item(@cp_item, @beam)
        s.index.should eql @cp_item.value('300A,0112').to_i
      end

      it "should set the ControlPoint's 'iso' attribute equal to the value found in the ControlPoint Item" do
        s = ControlPoint.create_from_item(@cp_item, @beam)
        s.iso.should == @cp_item.value('300A,012C').to_coordinate
      end

      it "should set the ControlPoint's 'pedestal_angle' attribute equal to the value found in the ControlPoint Item" do
        s = ControlPoint.create_from_item(@cp_item, @beam)
        s.pedestal_angle.should eql @cp_item.value('300A,0122').to_f
      end

      it "should set the ControlPoint's 'pedestal_direction' attribute equal to the value found in the ControlPoint Item" do
        s = ControlPoint.create_from_item(@cp_item, @beam)
        s.pedestal_direction.should eql @cp_item.value('300A,0123')
      end

      it "should set the ControlPoint's 'ssd' attribute equal to the value found in the ControlPoint Item" do
        s = ControlPoint.create_from_item(@cp_item, @beam)
        s.ssd.should eql @cp_item.value('300A,0130').to_f
      end

      it "should set the ControlPoint's 'table_top_angle' attribute equal to the value found in the ControlPoint Item" do
        s = ControlPoint.create_from_item(@cp_item, @beam)
        s.table_top_angle.should eql @cp_item.value('300A,0125').to_f
      end

      it "should set the ControlPoint's 'table_top_direction' attribute equal to the value found in the ControlPoint Item" do
        s = ControlPoint.create_from_item(@cp_item, @beam)
        s.table_top_direction.should eql @cp_item.value('300A,0126')
      end

      it "should set the ControlPoint's 'table_top_lateral' attribute equal to the value found in the ControlPoint Item" do
        s = ControlPoint.create_from_item(@cp_item, @beam)
        s.table_top_lateral.should eql @cp_item.value('300A,012A').to_f
      end

      it "should set the ControlPoint's 'table_top_vertical' attribute equal to the value found in the ControlPoint Item" do
        s = ControlPoint.create_from_item(@cp_item, @beam)
        s.table_top_vertical.should eql @cp_item.value('300A,0128').to_f
      end

      it "should set the ControlPoint's 'table_top_longitudinal' attribute equal to the value found in the ControlPoint Item" do
        s = ControlPoint.create_from_item(@cp_item, @beam)
        s.table_top_longitudinal.should eql @cp_item.value('300A,0129').to_f
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a value is not given as a 'index' argument" do
        expect {ControlPoint.new(nil, @cum_meterset, @beam)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a value is not given as a 'cum_meterset' argument" do
        expect {ControlPoint.new(@index, nil, @beam)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-Beam is passed as a 'beam' argument" do
        expect {ControlPoint.new(@index, @cum_meterset, 'not-a-beam')}.to raise_error(ArgumentError, /'beam'/)
      end

      it "should pass the 'index' argument to the 'index' attribute" do
        @cp.index.should eql @index
      end

      it "should pass the 'cum_meterset' argument to the 'cum_meterset' attribute" do
        @cp.cum_meterset.should eql @cum_meterset
      end

      it "should by default set the 'collimators' attribute as an empty array" do
        @cp.collimators.should eql Array.new
      end

      it "should by default set the 'collimator_angle' attribute as nil" do
        @cp.collimator_angle.should be_nil
      end

      it "should by default set the 'collimator_direction' attribute as nil" do
        @cp.collimator_direction.should be_nil
      end

      it "should by default set the 'energy' attribute as nil" do
        @cp.energy.should be_nil
      end

      it "should by default set the 'gantry_angle' attribute as nil" do
        @cp.gantry_angle.should be_nil
      end

      it "should by default set the 'gantry_direction' attribute as nil" do
        @cp.gantry_direction.should be_nil
      end

      it "should by default set the 'iso' attribute as nil" do
        @cp.iso.should be_nil
      end

      it "should by default set the 'pedestal_angle' attribute as nil" do
        @cp.pedestal_angle.should be_nil
      end

      it "should by default set the 'pedestal_direction' attribute as nil" do
        @cp.pedestal_direction.should be_nil
      end

      it "should by default set the 'ssd' attribute as nil" do
        @cp.ssd.should be_nil
      end

      it "should by default set the 'table_top_angle' attribute as nil" do
        @cp.table_top_angle.should be_nil
      end

      it "should by default set the 'table_top_direction' attribute as nil" do
        @cp.table_top_direction.should be_nil
      end

      it "should by default set the 'table_top_lateral' attribute as nil" do
        @cp.table_top_lateral.should be_nil
      end

      it "should by default set the 'table_top_vertical' attribute as nil" do
        @cp.table_top_vertical.should be_nil
      end

      it "should by default set the 'table_top_longitudinal' attribute as nil" do
        @cp.table_top_longitudinal.should be_nil
      end

      it "should add the ControlPoint instance to the referenced Beam" do
        @beam.control_point.should eql @cp
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        cp_other = ControlPoint.new(@index, @cum_meterset, @beam)
        (@cp == cp_other).should be_true
      end

      it "should be false when comparing two instances having different attributes" do
        cp_other = ControlPoint.new(99, @cum_meterset, @beam)
        (@cp == cp_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@cp == 42).should be_false
      end

    end


    context "#add_collimator" do

      it "should raise an ArgumentError when trying to add an incompatible type" do
        expect {@cp.add_collimator('not-a-coll')}.to raise_error(ArgumentError, /'coll'/)
      end

      it "should add the Collimator to the empty ControlPoint instance" do
        cp_other = ControlPoint.new(3, 0.45, @beam)
        coll = CollimatorSetup.new('ASYMX', [[-10.0, 10.0]], cp_other)
        @cp.add_collimator(coll)
        @cp.collimators.size.should eql 1
        @cp.collimators.first.should eql coll
      end

      it "should add the Collimator to the ControlPoint instance already containing a Collimator" do
        cp_other = ControlPoint.new(3, 0.45, @beam)
        coll1 = CollimatorSetup.new('ASYMX', [[-10.0, 10.0]], @cp)
        coll2 = CollimatorSetup.new('ASYMY', [[-15.0, 15.0]], cp_other)
        @cp.add_collimator(coll2)
        @cp.collimators.size.should eql 2
        @cp.collimators.first.should eql coll1
        @cp.collimators.last.should eql coll2
      end

      it "should not add multiple entries of the same Collimator" do
        coll = CollimatorSetup.new('ASYMX', [[-10.0, 10.0]], @cp)
        @cp.add_collimator(coll)
        @cp.collimators.size.should eql 1
        @cp.collimators.first.should eql coll
      end

    end


    context "#collimator" do

      before :each do
        coll1 = CollimatorSetup.new('ASYMX', [[-10.0, 10.0]], @cp)
        coll2 = CollimatorSetup.new('ASYMY', [[-15.0, 15.0]], @cp)
      end

      it "should raise an ArgumentError if multiple arguments are passed" do
        expect {@cp.collimator(@sop, @sop)}.to raise_error(ArgumentError, /one/)
      end

      it "should return the first collimator setup when no arguments are used" do
        @cp.collimator.should eql @cp.collimators.first
      end

      it "should return the the matching CollimatorSetup when a type string is supplied" do
        type = "ASYMY"
        coll = @cp.collimator(type)
        coll.type.should eql type
      end

    end


    context "#collimator_angle=()" do

      it "should assign the value to the referenced attribute" do
        value = 45.0
        @cp.collimator_angle = value
        @cp.collimator_angle.should eql value
      end

    end


    context "#collimator_direction=()" do

      it "should assign the value to the referenced attribute" do
        value = 'CW'
        @cp.collimator_direction = value
        @cp.collimator_direction.should eql value
      end

    end


    context "#cum_meterset=()" do

      it "should assign the value to the referenced attribute" do
        value = 1.0
        @cp.cum_meterset = value
        @cp.cum_meterset.should eql value
      end

    end


    context "#energy=()" do

      it "should assign the value to the referenced attribute" do
        value = 6.0
        @cp.energy = value
        @cp.energy.should eql value
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        cp_other = ControlPoint.new(@index, @cum_meterset, @beam)
        @cp.eql?(cp_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        cp_other = ControlPoint.new(99, @cum_meterset, @beam)
        @cp.eql?(cp_other).should be_false
      end

    end


    context "#gantry_angle=()" do

      it "should assign the value to the referenced attribute" do
        value = 90.0
        @cp.gantry_angle = value
        @cp.gantry_angle.should eql value
      end

    end


    context "#gantry_direction=()" do

      it "should assign the value to the referenced attribute" do
        value = 'CCW'
        @cp.gantry_direction = value
        @cp.gantry_direction.should eql value
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        cp_other = ControlPoint.new(@index, @cum_meterset, @beam)
        @cp.hash.should be_a Fixnum
        @cp.hash.should eql cp_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        cp_other = ControlPoint.new(99, @cum_meterset, @beam)
        @cp.hash.should_not eql cp_other.hash
      end

    end


    context "#index=()" do

      it "should assign the value to the referenced attribute" do
        value = 3
        @cp.index = value
        @cp.index.should eql value
      end

    end


    context "#iso=()" do

      it "should assign the value to the referenced attribute" do
        value = "45.0\\-5.5\\0.0"
        @cp.iso = value
        @cp.iso.should eql value.to_coordinate
      end

    end


    context "#pedestal_angle=()" do

      it "should assign the value to the referenced attribute" do
        value = 33.3
        @cp.pedestal_angle = value
        @cp.pedestal_angle.should eql value
      end

    end


    context "#pedestal_direction=()" do

      it "should assign the value to the referenced attribute" do
        value = 'CW'
        @cp.pedestal_direction = value
        @cp.pedestal_direction.should eql value
      end

    end


    context "#ssd=()" do

      it "should assign the value to the referenced attribute" do
        value = 999.9
        @cp.ssd = value
        @cp.ssd.should eql value
      end

    end


    context "#table_top_angle=()" do

      it "should assign the value to the referenced attribute" do
        value = 0.0
        @cp.table_top_angle = value
        @cp.table_top_angle.should eql value
      end

    end


    context "#table_top_direction=()" do

      it "should assign the value to the referenced attribute" do
        value = 'CCW'
        @cp.table_top_direction = value
        @cp.table_top_direction.should eql value
      end

    end


    context "#table_top_lateral=()" do

      it "should assign the value to the referenced attribute" do
        value = 2.2
        @cp.table_top_lateral = value
        @cp.table_top_lateral.should eql value
      end

    end


    context "#table_top_longitudinal=()" do

      it "should assign the value to the referenced attribute" do
        value = 65.0
        @cp.table_top_longitudinal = value
        @cp.table_top_longitudinal.should eql value
      end

    end


    context "#table_top_vertical=()" do

      it "should assign the value to the referenced attribute" do
        value = -4.0
        @cp.table_top_vertical = value
        @cp.table_top_vertical.should eql value
      end

    end


    context "#to_control_point" do

      it "should return itself" do
        @cp.to_control_point.equal?(@cp).should be_true
      end

    end


=begin
    context "#to_item" do

      it "should return a ControlPoint Sequence Item properly populated with values from the ControlPoint instance" do
        cp = ControlPoint.new(@index, @cum_meterset, @beam)
        ssd = '950.0'
        cp.ssd = ssd
        item = cp.to_item
        item.class.should eql DICOM::Item
        item.count.should eql 3
        item.value('300A,0112').should eql @index
        item.value('300A,0130').should eql ssd
        item.value('300A,0134').should eql @cum_meterset
      end

    end
=end

  end

end
# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe Beam do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.987.3', 'CT', @f, @st)
      @ss = StructureSet.new('1.765.354', @is)
      @plan = Plan.new('1.345.789', @ss)
      @name = 'AP'
      @number = 4
      @machine = 'Linac'
      @meterset = 100.0
      @beam = Beam.new(@name, @number, @machine, @meterset, @plan)
    end


    context "::create_from_item" do

      before :each do
        dcm = DICOM::DObject.read(FILE_PLAN)
        @meterset = dcm['300A,0070'][0]['300C,0004'][0].value('300A,0086').to_f
        @beam_item = dcm['300A,00B0'][0]
      end

      it "should raise an ArgumentError when a non-Item is passed as the 'beam_item' argument" do
        expect {Beam.create_from_item('non-Item', @meterset, @plan)}.to raise_error(ArgumentError, /'beam_item'/)
      end

      it "should raise an ArgumentError when a non-Float is passed as the 'meterset' argument" do
        expect {Beam.create_from_item(@beam_item, '42.0', @plan)}.to raise_error(ArgumentError, /'meterset'/)
      end

      it "should raise an ArgumentError when a non-Plan is passed as the 'plan' argument" do
        expect {Beam.create_from_item(@beam_item, @meterset, 'not-a-plan')}.to raise_error(ArgumentError, /'plan'/)
      end
=begin
      it "should fill the 'control_points' array attribute with ControlPoints created from the beam item" do
        beam = Beam.create_from_item(@beam_item, @meterset, @plan)
        beam.control_points.length.should eql @beam_item['300A,0111'].count / 2
        beam.control_points.first.class.should eql ControlPoint
      end
=end
      it "should set the Beam's 'name' attribute equal to the value found in the Beam Item" do
        beam = Beam.create_from_item(@beam_item, @meterset, @plan)
        beam.name.should eql @beam_item.value('300A,00C2')
      end

      it "should set the Beam's 'number' attribute equal to the value found in the Beam Item" do
        beam = Beam.create_from_item(@beam_item, @meterset, @plan)
        beam.number.should eql @beam_item.value('300A,00C0').to_i
      end

      it "should set the Beam's 'machine' attribute equal to the value found in the Beam Item" do
        beam = Beam.create_from_item(@beam_item, @meterset, @plan)
        beam.machine.should eql @beam_item.value('300A,00B2')
      end

      it "should set the Beam's 'type' attribute equal to the value found in the Beam Item" do
        beam = Beam.create_from_item(@beam_item, @meterset, @plan)
        beam.type.should eql @beam_item.value('300A,00C4')
      end

      it "should set the Beam's 'delivery_type' attribute equal to the value found in the Beam Item" do
        beam = Beam.create_from_item(@beam_item, @meterset, @plan)
        beam.delivery_type.should eql @beam_item.value('300A,00CE')
      end

      it "should set the Beam's 'description' attribute equal to the value found in the Beam Item" do
        beam = Beam.create_from_item(@beam_item, @meterset, @plan)
        beam.description.should eql @beam_item.value('300A,00C3')
      end

      it "should set the Beam's 'rad_type' attribute equal to the value found in the Beam Item" do
        beam = Beam.create_from_item(@beam_item, @meterset, @plan)
        beam.rad_type.should eql @beam_item.value('300A,00C6')
      end

      it "should set the Beam's 'sad' attribute equal to the value found in the Beam Item" do
        beam = Beam.create_from_item(@beam_item, @meterset, @plan)
        beam.sad.should eql @beam_item.value('300A,00B4').to_f
      end

      it "should set the Beam's 'unit' attribute equal to the value found in the Beam Item" do
        beam = Beam.create_from_item(@beam_item, @meterset, @plan)
        beam.unit.should eql @beam_item.value('300A,00B3')
      end

      it "should set the 'meterset' argument as the Beam's 'meterset' attribute" do
        beam = Beam.create_from_item(@beam_item, @meterset, @plan)
        beam.meterset.should eql @meterset
      end

      it "should set the 'plan' argument as the Beam's 'plan' attribute" do
        beam = Beam.create_from_item(@beam_item, @meterset, @plan)
        beam.plan.should eql @plan
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-String is passed as a 'name' argument" do
        expect {Beam.new(42, @number, @machine, @meterset, @plan)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-Integer is passed as a 'number' argument" do
        expect {Beam.new(@name, 3.55, @machine, @meterset, @plan)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-String is passed as a 'machine' argument" do
        expect {Beam.new(@name, @number, false, @meterset, @plan)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-Float is passed as a 'meterset' argument" do
        expect {Beam.new(@name, @number, @machine, true, @plan)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-Plan is passed as a 'plan' argument" do
        expect {Beam.new(@name, @number, @machine, @meterset, 'not-a-plan')}.to raise_error(ArgumentError, /'plan'/)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :delivery_type argument" do
        expect {Beam.new(@name, @number, @machine, @meterset, @plan, :delivery_type => 42)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :type argument" do
        expect {Beam.new(@name, @number, @machine, @meterset, @plan, :type => 42)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :description argument" do
        expect {Beam.new(@name, @number, @machine, @meterset, @plan, :description => 42)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :rad_type argument" do
        expect {Beam.new(@name, @number, @machine, @meterset, @plan, :rad_type => 42)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-Float is passed as an optional :sad argument" do
        expect {Beam.new(@name, @number, @machine, @meterset, @plan, :sad => "asdf")}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :unit argument" do
        expect {Beam.new(@name, @number, @machine, @meterset, @plan, :unit => 42)}.to raise_error(ArgumentError)
      end

      it "should pass the 'name' argument to the 'name' attribute" do
        @beam.name.should eql @name
      end

      it "should pass the 'number' argument to the 'number' attribute" do
        @beam.number.should eql @number
      end

      it "should pass the 'machine' argument to the 'machine' attribute" do
        @beam.machine.should eql @machine
      end

      it "should pass the 'meterset' argument to the 'meterset' attribute" do
        @beam.meterset.should eql @meterset
      end

      it "should pass the 'plan' argument to the 'plan' attribute" do
        @beam.plan.should eql @plan
      end

      it "should by default set the 'control_points' attribute to an empty array" do
        @beam.control_points.should eql Array.new
      end

      it "should by default set the 'type' attribute to 'STATIC'" do
        @beam.type.should eql 'STATIC'
      end

      it "should by default set the 'delivery_type' attribute to 'TREATMENT'" do
        @beam.delivery_type.should eql 'TREATMENT'
      end

      it "should by default set the 'description' attribute equal to the 'name' attribute" do
        @beam.description.should eql @name
      end

      it "should by default set the 'rad_type' attribute to 'PHOTON'" do
        @beam.rad_type.should eql 'PHOTON'
      end

      it "should by default set the 'sad' attribute to 1000.0" do
        @beam.sad.should eql 1000.0
      end

      it "should by default set the 'unit' attribute to 'MU'" do
        @beam.unit.should eql 'MU'
      end

      it "should add the Beam instance (once) to the referenced Plan" do
        @plan.beams.length.should eql 1
        @plan.beams.first.should eql @beam
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        beam_other = Beam.new(@name, @number, @machine, @meterset, @plan)
        (@beam == beam_other).should be_true
      end

      it "should be false when comparing two instances having different attributes" do
        beam_other = Beam.new("Other beam", @number, @machine, @meterset, @plan)
        (@beam == beam_other).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        (@beam == 42).should be_false
      end

    end


    context "#add_control_point" do

      it "should raise an ArgumentError when a non-ControlPoint is passed as the 'cp' argument" do
        expect {@beam.add_control_point('not-a-cp')}.to raise_error(ArgumentError, /'cp'/)
      end
=begin
      it "should add the ControlPoint to the empty Beam instance" do
        beam_other = Beam.new('PA', 6, 'Unit2', 66.6, @plan)
        cp = ControlPoint.new(1, beam_other)
        @beam.add_control_point(cp)
        @beam.control_points.size.should eql 1
        @beam.control_points.first.should eql cp
      end

      it "should add the ControlPoint to the Beam instance already containing a ControlPoint" do
        beam_other = Beam.new('PA', 6, 'Unit2', 66.6, @plan)
        cp1 = ControlPoint.new(1, @beam)
        cp2 = ControlPoint.new(2, beam_other)
        @beam.add_control_point(cp2)
        @beam.control_points.size.should eql 2
        @beam.control_points.first.should eql cp1
        @beam.control_points.last.should eql cp2
      end

      it "should not add multiple entries of the same ControlPoint" do
        cp = ControlPoint.new(1, @beam)
        @beam.add_control_point(cp)
        @beam.control_points.size.should eql 1
        @beam.control_points.first.should eql cp
      end
=end
    end


=begin
    context "#beam_item" do

      it "should return a Beam Sequence Item properly populated with values from the Beam instance" do
        beam = Beam.new(@name, @number, @f, @ss)
        item = beam.obs_item
        item.class.should eql DICOM::Item
        item.count.should eql 4
        item.value('3006,0082').should eql beam.number.to_s
        item.value('3006,0084').should eql beam.number.to_s
        item.value('3006,00A4').should eql beam.type
        item.value('3006,00A6').should eql beam.interpreter
      end

    end
=end


    context "#delivery_type=()" do

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@beam.delivery_type = 42}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = 'TREAT'
        @beam.delivery_type = value
        @beam.delivery_type.should eql value
      end

    end


    context "#description=()" do

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@beam.description = 42}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = 'Test'
        @beam.description = value
        @beam.description.should eql value
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        beam_other = Beam.new(@name, @number, @machine, @meterset, @plan)
        @beam.eql?(beam_other).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        beam_other = Beam.new("Other beam", @number, @machine, @meterset, @plan)
        @beam.eql?(beam_other).should be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        beam_other = Beam.new(@name, @number, @machine, @meterset, @plan)
        @beam.hash.should be_a Fixnum
        @beam.hash.should eql beam_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        beam_other = Beam.new("Other beam", @number, @machine, @meterset, @plan)
        @beam.hash.should_not eql beam_other.hash
      end

    end


    context "#machine=()" do

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@beam.machine = 42}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = 'Unit03'
        @beam.machine = value
        @beam.machine.should eql value
      end

    end


    context "#meterset=()" do

      it "should raise an ArgumentError when a non-Float is passed as an argument" do
        expect {@beam.meterset = 'asdf'}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = 33.3
        @beam.meterset = value
        @beam.meterset.should eql value
      end

    end


    context "#name=()" do

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@beam.name = 42}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = 'Left'
        @beam.name = value
        @beam.name.should eql value
      end

    end


    context "#number=()" do

      it "should raise an ArgumentError when a non-Integer is passed as an argument" do
        expect {@beam.number = 'asdf'}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = 8
        @beam.number = value
        @beam.number.should eql value
      end

    end


    context "#rad_type=()" do

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@beam.rad_type = 42}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = 'TREAT'
        @beam.rad_type = value
        @beam.rad_type.should eql value
      end

    end

=begin
    context "#ref_beam_item" do

      it "should return a Referenced Beam Sequence Item properly populated with values from the Beam instance" do
        beam = Beam.new(@name, @number, @f, @ss)
        item = beam.ss_item
        item.class.should eql DICOM::Item
        item.count.should eql 4
        item.value('3006,0022').should eql beam.number.to_s
        item.value('3006,0024').should eql beam.frame.uid
        item.value('3006,0026').should eql beam.name
        item.value('3006,0036').should eql beam.algorithm
      end

    end
=end


    context "#sad=()" do

      it "should raise an ArgumentError when a non-Float is passed as an argument" do
        expect {@beam.sad = 'asdf'}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = 900.0
        @beam.sad = value
        @beam.sad.should eql value
      end

    end


    context "#type=()" do

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@beam.type = 42}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = 'DYNAMIC'
        @beam.type = value
        @beam.type.should eql value
      end

    end


    context "#to_beam" do

      it "should return itself" do
        @beam.to_beam.equal?(@beam).should be_true
      end

    end


    context "#unit=()" do

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@beam.unit = 42}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = 'MINUTE'
        @beam.unit = value
        @beam.unit.should eql value
      end

    end

  end

end
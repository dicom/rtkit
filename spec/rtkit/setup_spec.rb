# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe Setup do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @is = ImageSeries.new('1.987.3', 'CT', @f, @st)
      @ss = StructureSet.new('1.765.354', @is)
      @plan = Plan.new('1.345.789', @ss)
      @position = 'HFS'
      @number = 1
      @s = Setup.new(@position, @number, @plan)
    end

    context "::create_from_item" do

      before :each do
        dcm = DICOM::DObject.read(FILE_PLAN)
        @setup_item = dcm['300A,0180'][0]
      end

      it "should raise an ArgumentError when a non-Item is passed as the 'setup_item' argument" do
        expect {Setup.create_from_item('non-Item', @plan)}.to raise_error(ArgumentError, /'setup_item'/)
      end

      it "should raise an ArgumentError when a non-Plan is passed as the 'plan' argument" do
        expect {Setup.create_from_item(@setup_item, 'not-a-plan')}.to raise_error(ArgumentError, /'plan'/)
      end

      it "should set the Setup's 'position' attribute equal to the value found in the Setup Item" do
        s = Setup.create_from_item(@setup_item, @plan)
        expect(s.position).to eql @setup_item.value('0018,5100')
      end

      it "should set the Setup's 'number' attribute equal to the value found in the Setup Item" do
        s = Setup.create_from_item(@setup_item, @plan)
        expect(s.number).to eql @setup_item.value('300A,0182').to_i
      end

      it "should set the Setup's 'technique' attribute equal to the value found in the Setup Item" do
        s = Setup.create_from_item(@setup_item, @plan)
        expect(s.technique).to eql @setup_item.value('300A,01B0')
      end

      it "should set the Setup's 'offset_vertical' attribute equal to the value found in the Setup Item" do
        s = Setup.create_from_item(@setup_item, @plan)
        expect(s.offset_vertical).to eql @setup_item.value('300A,01D2').to_f
      end

      it "should set the Setup's 'offset_longitudinal' attribute equal to the value found in the Setup Item" do
        s = Setup.create_from_item(@setup_item, @plan)
        expect(s.offset_longitudinal).to eql @setup_item.value('300A,01D4').to_f
      end

      it "should set the Setup's 'offset_lateral' attribute equal to the value found in the Setup Item" do
        s = Setup.create_from_item(@setup_item, @plan)
        expect(s.offset_lateral).to eql @setup_item.value('300A,01D6').to_f
      end

      it "should set the 'plan' argument as the Setup's 'plan' attribute" do
        s = Setup.create_from_item(@setup_item, @plan)
        expect(s.plan).to eql @plan
      end

    end


    context "::new" do

      it "should raise an ArgumentError when a non-String is passed as a 'position' argument" do
        expect {Setup.new(42, @number, @plan)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-Integer is passed as a 'number' argument" do
        expect {Setup.new(@position, '33.3', @plan)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-Plan is passed as a 'plan' argument" do
        expect {Setup.new(@position, @number, 'not-a-plan')}.to raise_error(ArgumentError, /'plan'/)
      end

      it "should raise an ArgumentError when a non-String is passed as an optional :technique argument" do
        expect {Setup.new(@position, @number, @plan, :technique => 42)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-Float is passed as an optional :offset_vertical argument" do
        expect {Setup.new(@position, @number, @plan, :offset_vertical => 42)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-Float is passed as an optional :offset_longitudinal argument" do
        expect {Setup.new(@position, @number, @plan, :offset_longitudinal => 42)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-Float is passed as an optional :offset_lateral argument" do
        expect {Setup.new(@position, @number, @plan, :offset_lateral => 42)}.to raise_error(ArgumentError)
      end

      it "should pass the 'position' argument to the 'position' attribute" do
        expect(@s.position).to eql @position
      end

      it "should pass the 'number' argument to the 'number' attribute" do
        expect(@s.number).to eql @number
      end

      it "should by default set the 'technique' attribute as nil" do
        expect(@s.technique).to be_nil
      end

      it "should by default set the 'offset_vertical' attribute as nil" do
        expect(@s.offset_vertical).to be_nil
      end

      it "should by default set the 'offset_longitudinal' attribute as nil" do
        expect(@s.offset_longitudinal).to be_nil
      end

      it "should by default set the 'offset_lateral' attribute as nil" do
        expect(@s.offset_lateral).to be_nil
      end

      it "should add the Setup instance to the referenced Plan" do
        expect(@plan.setup).to eql @s
      end

    end


    context "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        s_other = Setup.new(@position, @number, @plan)
        expect(@s == s_other).to be_true
      end

      it "should be false when comparing two instances having different attributes" do
        s_other = Setup.new('FFP', @number, @plan)
        expect(@s == s_other).to be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        expect(@s == 42).to be_false
      end

    end


    context "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        s_other = Setup.new(@position, @number, @plan)
        expect(@s.eql?(s_other)).to be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        s_other = Setup.new('FFP', @number, @plan)
        expect(@s.eql?(s_other)).to be_false
      end

    end


    context "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        s_other = Setup.new(@position, @number, @plan)
        expect(@s.hash).to be_a Fixnum
        expect(@s.hash).to eql s_other.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        s_other = Setup.new('FFP', @number, @plan)
        expect(@s.hash).not_to eql s_other.hash
      end

    end


    context "#number=()" do

      it "should raise an ArgumentError when a non-Integer is passed as an argument" do
        expect {@s.number = '1.0'}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = 420
        @s.number = value
        expect(@s.number).to eql value
      end

    end


    context "#offset_lateral=()" do

      it "should raise an ArgumentError when a non-Float is passed as an argument" do
        expect {@s.offset_lateral = 'ss'}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = -4.0
        @s.offset_lateral = value
        expect(@s.offset_lateral).to eql value
      end

    end


    context "#offset_longitudinal=()" do

      it "should raise an ArgumentError when a non-Float is passed as an argument" do
        expect {@s.offset_longitudinal = 'ss'}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = 6.0
        @s.offset_longitudinal = value
        expect(@s.offset_longitudinal).to eql value
      end

    end


    context "#offset_vertical=()" do

      it "should raise an ArgumentError when a non-Float is passed as an argument" do
        expect {@s.offset_vertical = 'ss'}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = 42.0
        @s.offset_vertical = value
        expect(@s.offset_vertical).to eql value
      end

    end


    context "#position=()" do

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@s.position = 42}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = 'FFP'
        @s.position = value
        expect(@s.position).to eql value
      end

    end


    context "#technique=()" do

      it "should raise an ArgumentError when a non-String is passed as an argument" do
        expect {@s.technique = 42}.to raise_error(ArgumentError)
      end

      it "should assign the value to the referenced attribute" do
        value = 'FIXED_SSD'
        @s.technique = value
        expect(@s.technique).to eql value
      end

    end


=begin
    context "#to_item" do

      it "should return a Patient Setup Sequence Item properly populated with values from the Setup instance" do
        s = Setup.new(@position, @number, @plan)
        s.technique = 'SSD'
        item = s.to_item
        item.class.should eql DICOM::Item
        item.count.should eql 3
        item.value('0018,5100').should eql @position
        item.value('300A,0182').should eql @number
        item.value('300A,01B0').should eql 'SSD'
      end

    end
=end


    context "#to_setup" do

      it "should return itself" do
        expect(@s.to_setup.equal?(@s)).to be_true
      end

    end

  end

end
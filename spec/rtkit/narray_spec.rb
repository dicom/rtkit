# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe NArray do

    context "#expand_vector" do

      it "should raise an error when given a non-NArray" do
        n1 = NArray.int(0)
        n2 = Array.new(3)
        expect {n1.expand_vector(n2)}.to raise_error(ArgumentError, /NArray/)
      end

      it "should raise an error when self has more than one dimensions" do
        n1 = NArray.int(2, 3)
        n2 = NArray.int(2)
        expect {n1.expand_vector(n2)}.to raise_error(ArgumentError, /vector/)
      end

      it "should raise an error when other has more than two dimensions" do
        n1 = NArray.int(2)
        n2 = NArray.int(2, 3)
        expect {n1.expand_vector(n2)}.to raise_error(ArgumentError, /vector/)
      end

      it "should return an NArray with the same type as self" do
        n1a = NArray.int(2).indgen!
        n2 = NArray.int(3).indgen! + 2
        expect(n1a.expand_vector(n2).typecode).to eql n1a.typecode
        n1b = NArray.sfloat(2).indgen!
        expect(n1b.expand_vector(n2).typecode).to eql n1b.typecode
      end

      it "should return a properly expanded vector when called on two non-zero-length vectors" do
        n1 = NArray.int(2).indgen!
        n2 = NArray.int(3).indgen! + 2
        expect(n1.expand_vector(n2) == NArray.int(5).indgen!).to be_true
      end

      it "should return other when the first vector is empty" do
        n1 = NArray.int(0)
        n2 = NArray.int(3).indgen!
        expect(n1.expand_vector(n2) == n2).to be_true
      end

      it "should return self when the other vector is empty" do
        n1 = NArray.int(3).indgen!
        n2 = NArray.int(0)
        expect(n1.expand_vector(n2) == n1).to be_true
      end

      it "should scale well (i.e. not throw a stack level to deep error on large arrays)" do
        n1 = NArray.int(100000)
        n2 = NArray.int(100000)
        n1.expand_vector(n2)
      end

    end


    context "#segmented?" do

      it "should return false on a purely zero-valued NArray" do
        narr = NArray.byte(5, 5)
        expect(narr.segmented?).to be_false
      end

      it "should return true on a purely unity-valued NArray" do
        narr = NArray.byte(5, 5).fill(1)
        expect(narr.segmented?).to be_true
      end

      it "should return false on an NArray containing one positive pixel value" do
        narr = NArray.byte(5, 5)
        narr[2] = 1
        expect(narr.segmented?).to be_false
      end

      it "should return false on an NArray containing two positive pixel values" do
        narr = NArray.byte(5, 5)
        narr[2..3] = 1
        expect(narr.segmented?).to be_false
      end

      it "should return true on an NArray containing three positive pixel values" do
        narr = NArray.byte(5, 5)
        narr[[0,1,5]] = 1
        expect(narr.segmented?).to be_true
      end

    end

  end

end
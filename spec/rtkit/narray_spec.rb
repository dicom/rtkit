# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe NArray do

    context "#segmented?" do

      it "should return false on a purely zero-valued NArray" do
        narr = NArray.byte(5, 5)
        narr.segmented?.should be_false
      end

      it "should return true on a purely unity-valued NArray" do
        narr = NArray.byte(5, 5).fill(1)
        narr.segmented?.should be_true
      end

      it "should return false on an NArray containing one positive pixel value" do
        narr = NArray.byte(5, 5)
        narr[2] = 1
        narr.segmented?.should be_false
      end

      it "should return false on an NArray containing two positive pixel values" do
        narr = NArray.byte(5, 5)
        narr[2..3] = 1
        narr.segmented?.should be_false
      end

      it "should return true on an NArray containing three positive pixel values" do
        narr = NArray.byte(5, 5)
        narr[[0,1,5]] = 1
        narr.segmented?.should be_true
      end

    end

  end

end
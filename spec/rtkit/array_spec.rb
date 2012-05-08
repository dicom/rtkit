# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe Array do

    context "#most_common_value" do

      it "should return the most common value in this array of integers" do
        array = [9,9,1,2,2,2,3,3,4,4,5,6,6,7]
        array.most_common_value.should eql 2
      end

      it "should return the single value in an array containing only one element" do
        array = [7]
        array.most_common_value.should eql 7
      end

    end


    context "#sort_by_order" do

      #it "should return false on a purely zero-valued NArray" do
        #narr = NArray.byte(5, 5)
        #narr.segmented?.should be_false
      #end

    end

  end

end
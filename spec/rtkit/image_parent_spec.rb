# encoding: ASCII-8BIT

require 'spec_helper'


module RTKIT

  describe ImageSeries do

    before :each do
      @ds = DataSet.new
      @p = Patient.new('John', '12345', @ds)
      @st = Study.new('1.456.789', @p)
      @f = Frame.new('1.4321', @p)
      @uid = '1.345.789'
      @modality = 'CT'
      @class_uid = '1.2.840.10008.5.1.4.1.1.2'
      @is = ImageSeries.new(@uid, @modality, @f, @st)
    end


    context "#slice_spacing" do

      it "should return nil when the image series contain no images" do
        @is.slice_spacing.should be_nil
      end

      it "should return nil when the image series contain only one image" do
        @im = SliceImage.new('1.234', 5.0, @is)
        @is.slice_spacing.should be_nil
      end

      it "should return the expected slice spacing on an image series containing two images" do
        @im1 = SliceImage.new('1.234', 5.0, @is)
        @im2 = SliceImage.new('1.235', 10.0, @is)
        @is.slice_spacing.should eql 5.0
      end

      it "should return the expected slice spacing on an image series containing multiple images" do
        @im1 = SliceImage.new('1.234', -15.0, @is)
        @im2 = SliceImage.new('1.235', -10.0, @is)
        @im3 = SliceImage.new('1.236', -5.0, @is)
        @im4 = SliceImage.new('1.237', 0.0, @is)
        @im5 = SliceImage.new('1.238', 5.0, @is)
        @is.slice_spacing.should eql 5.0
      end

      it "should return the most frequent slice spacing on an image series containing a missing image" do
        @im1 = SliceImage.new('1.234', -15.0, @is)
        @im2 = SliceImage.new('1.235', -10.0, @is)
        @im3 = SliceImage.new('1.236', -5.0, @is)
        @im4 = SliceImage.new('1.237', 0.0, @is)
        @im5 = SliceImage.new('1.238', 10.0, @is)
        @is.slice_spacing.should eql 5.0
      end

      it "should return the expected slice spacing on an image series where images have been added in a different order than their slice positions" do
        @im1 = SliceImage.new('1.234', -15.0, @is)
        @im2 = SliceImage.new('1.235', 15.0, @is)
        @im4 = SliceImage.new('1.237', 0.0, @is)
        @im5 = SliceImage.new('1.238', 30.0, @is)
        @is.slice_spacing.should eql 15.0
      end

    end

  end

end
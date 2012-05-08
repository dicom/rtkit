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
        @im = Image.new('1.234', @is)
        @im.pos_slice = 5.0
        @is.slice_spacing.should be_nil
      end

      it "should return the expected slice spacing on an image series containing two images" do
        @im1 = Image.new('1.234', @is)
        @im2 = Image.new('1.235', @is)
        @im1.pos_slice = 5.0
        @im2.pos_slice = 10.0
        @is.slice_spacing.should eql 5.0
      end

      it "should return the expected slice spacing on an image series containing multiple images" do
        @im1 = Image.new('1.234', @is)
        @im2 = Image.new('1.235', @is)
        @im3 = Image.new('1.236', @is)
        @im4 = Image.new('1.237', @is)
        @im5 = Image.new('1.238', @is)
        @im1.pos_slice = -15.0
        @im2.pos_slice = -10.0
        @im3.pos_slice = -5.0
        @im4.pos_slice = 0.0
        @im5.pos_slice = 5.0
        @is.slice_spacing.should eql 5.0
      end

      it "should return the most frequent slice spacing on an image series containing a missing image" do
        @im1 = Image.new('1.234', @is)
        @im2 = Image.new('1.235', @is)
        @im3 = Image.new('1.236', @is)
        @im4 = Image.new('1.237', @is)
        @im5 = Image.new('1.238', @is)
        @im1.pos_slice = -15.0
        @im2.pos_slice = -10.0
        @im3.pos_slice = -5.0
        @im4.pos_slice = 0.0
        @im5.pos_slice = 10.0
        @is.slice_spacing.should eql 5.0
      end

    end

  end

end
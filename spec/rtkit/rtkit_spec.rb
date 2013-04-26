# encoding: UTF-8

require 'spec_helper'

module RTKIT

  describe self do

    context "#date_str" do

      it "should return a valid DICOM date string converted from the given Time object" do
        time = Time.new(2013, 04, 15, 12, 47, 53)
        str = RTKIT.date_str(time)
        str.should eql '20130415'
      end

    end


    context "#frame_uid" do

      it "should return a UID string" do
        uid = RTKIT.frame_uid
        uid.should be_a String
        uid.should match /^[0-9]+([\\.]+|[0-9]+)*$/
      end

    end


    context "#generate_uids" do

      it "should return a one-element array containing a valid UID string" do
        uids = RTKIT.generate_uids(prefix=1)
        uids.should be_a Array
        uids.length.should eql 1
        uids.first.should match /^[0-9]+([\\.]+|[0-9]+)*$/
      end

      it "should use the RTKIT root uid with the prefix argument, properly joined by dots" do
        prefix = '6'
        uids = RTKIT.generate_uids(prefix)
        uids.first.include?("#{RTKIT.dicom_root}.#{prefix}.").should be_true
      end

      it "should return an array of n UID strings" do
        prefix = '5'
        nr = 3
        uids = RTKIT.generate_uids(prefix, nr)
        uids.length.should eql 3
        uids.each_index do |i|
          uids[i].should match /^[0-9]+([\\.]+|[0-9]+)*$/
          uids[i][-1].should eql (i+1).to_s
        end
      end

    end


    context "#series_uid" do

      it "should return a UID string" do
        uid = RTKIT.series_uid
        uid.should be_a String
        uid.should match /^[0-9]+([\\.]+|[0-9]+)*$/
      end

    end


    context "#sop_uid" do

      it "should return a UID string" do
        uid = RTKIT.sop_uid
        uid.should be_a String
        uid.should match /^[0-9]+([\\.]+|[0-9]+)*$/
      end

    end


    context "#sop_uids" do

      it "should return an array of n UID strings" do
        nr = 3
        uids = RTKIT.sop_uids(nr)
        uids.length.should eql 3
        uids.each_index do |i|
          uids[i].should match /^[0-9]+([\\.]+|[0-9]+)*$/
          uids[i][-1].should eql (i+1).to_s
        end
      end

    end


    context "#study_uid" do

      it "should return a UID string" do
        uid = RTKIT.study_uid
        uid.should be_a String
        uid.should match /^[0-9]+([\\.]+|[0-9]+)*$/
      end

    end


    context "#time_str" do

      it "should return a valid DICOM time string converted from the given Time object" do
        time = Time.new(2013, 04, 15, 12, 47, 53)
        str = RTKIT.time_str(time)
        str.should eql '124753'
      end

    end

  end

end
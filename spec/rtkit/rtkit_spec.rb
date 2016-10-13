# encoding: UTF-8

require 'spec_helper'

module RTKIT

  describe self do

    context "#date_str" do

      it "should return a valid DICOM date string converted from the given Time object" do
        time = Time.new(2013, 04, 15, 12, 47, 53)
        str = RTKIT.date_str(time)
        expect(str).to eql '20130415'
      end

    end


    context "#frame_uid" do

      it "should return a UID string" do
        uid = RTKIT.frame_uid
        expect(uid).to be_a String
        expect(uid).to match /^[0-9]+([\\.]+|[0-9]+)*$/
      end

    end


    context "#generate_uids" do

      it "should return a one-element array containing a valid UID string" do
        uids = RTKIT.generate_uids(prefix=1)
        expect(uids).to be_a Array
        expect(uids.length).to eql 1
        expect(uids.first).to match /^[0-9]+([\\.]+|[0-9]+)*$/
      end

      it "should use the RTKIT root uid with the prefix argument, properly joined by dots" do
        prefix = '6'
        uids = RTKIT.generate_uids(prefix)
        expect(uids.first.include?("#{RTKIT.dicom_root}.#{prefix}.")).to be true
      end

      it "should return an array of n UID strings" do
        prefix = '5'
        nr = 3
        uids = RTKIT.generate_uids(prefix, nr)
        expect(uids.length).to eql 3
        uids.each_index do |i|
          expect(uids[i]).to match /^[0-9]+([\\.]+|[0-9]+)*$/
          expect(uids[i][-1]).to eql (i+1).to_s
        end
      end

    end


    context "#series_uid" do

      it "should return a UID string" do
        uid = RTKIT.series_uid
        expect(uid).to be_a String
        expect(uid).to match /^[0-9]+([\\.]+|[0-9]+)*$/
      end

    end


    context "#sop_uid" do

      it "should return a UID string" do
        uid = RTKIT.sop_uid
        expect(uid).to be_a String
        expect(uid).to match /^[0-9]+([\\.]+|[0-9]+)*$/
      end

    end


    context "#sop_uids" do

      it "should return an array of n UID strings" do
        nr = 3
        uids = RTKIT.sop_uids(nr)
        expect(uids.length).to eql 3
        uids.each_index do |i|
          expect(uids[i]).to match /^[0-9]+([\\.]+|[0-9]+)*$/
          expect(uids[i][-1]).to eql (i+1).to_s
        end
      end

    end


    context "#study_uid" do

      it "should return a UID string" do
        uid = RTKIT.study_uid
        expect(uid).to be_a String
        expect(uid).to match /^[0-9]+([\\.]+|[0-9]+)*$/
      end

    end


    context "#time_str" do

      it "should return a valid DICOM time string converted from the given Time object" do
        time = Time.new(2013, 04, 15, 12, 47, 53)
        str = RTKIT.time_str(time)
        expect(str).to eql '124753'
      end

    end

  end

end
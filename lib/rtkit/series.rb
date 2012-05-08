module RTKIT

  # Contains the DICOM data and methods related to a series.
  #
  # === Relations
  #
  # * A Series belongs to a Study.
  # * Some types of Series (e.g. CT, MR) have many Image instances.
  #
  class Series

    # The SOP Class UID.
    attr_reader :class_uid
    # The Series Date.
    attr_reader :date
    # The Series Description.
    attr_reader :description
    # The Modality of the Series.
    attr_reader :modality
    # The Series's Study reference.
    attr_reader :study
    # The Series Instance UID.
    attr_reader :series_uid
    # The Series Time.
    attr_reader :time

    # Creates a new Series instance. The Series Instance UID string is used to uniquely identify a Series.
    #
    # === Parameters
    #
    # * <tt>series_uid</tt> -- The Series Instance UID string.
    # * <tt>modality</tt> -- The Modality string of the Series, e.g. 'CT' or 'RTSTRUCT'.
    # * <tt>study</tt> -- The Study instance that this Series belongs to.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:class_uid</tt> -- String. The SOP Class UID (DICOM tag '0008,0016').
    # * <tt>:date</tt> -- String. The Series Date (DICOM tag '0008,0021').
    # * <tt>:time</tt> -- String. The Series Time (DICOM tag '0008,0031').
    # * <tt>:description</tt> -- String. The Series Description (DICOM tag '0008,103E').
    #
    def initialize(series_uid, modality, study, options={})
      raise ArgumentError, "Invalid argument 'uid'. Expected String, got #{series_uid.class}." unless series_uid.is_a?(String)
      raise ArgumentError, "Invalid argument 'modality'. Expected String, got #{modality.class}." unless modality.is_a?(String)
      raise ArgumentError, "Invalid argument 'study'. Expected Study, got #{study.class}." unless study.is_a?(Study)
      # Key attributes:
      @series_uid = series_uid
      @modality = modality
      @study = study
      # Optional attributes:
      @class_uid = options[:class_uid]
      @date = options[:date]
      @time = options[:time]
      @description = options[:description]
    end

    # Returns true if the series is of a modality which means it contains multiple images (CT, MR, RTImage, RTDose).
    # Returns false if not.
    #
    def image_modality?
      if IMAGE_MODALITIES.include?(@modality)
        return true
      else
        return false
      end
    end

    # Returns the unique identifier string, which for an ImageSeries is the Series Instance UID,
    # and for the other types of Series (e.g. StructureSet, Plan, etc) it is the SOP Instance UID.
    #
    def uid
      return @sop_uid || @series_uid
    end

  end
end
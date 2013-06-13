module RTKIT

  # Contains the DICOM data and methods related to a series.
  #
  # === Relations
  #
  # * A Series belongs to a Study.
  # * Some subclasses of Series (e.g. ImageSeries (CT, MR) or DoseVolume
  # (RTDose)) have many Image instances.
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

    # Creates a new Series instance. The Series Instance UID string is used to
    # uniquely identify a Series.
    #
    # @param [String] series_uid the Series Instance UID string
    # @param [String] modality the modality string of the series (e.g. 'CT', 'RTSTRUCT')
    # @param [Study] study the Study instance which this Series belongs to
    # @param [Hash] options the options to use for creating the Series
    # @option options [String] :class_uid the SOP class UID (DICOM tag '0008,0016')
    # @option options [String] :date the series date (DICOM tag '0008,0021')
    # @option options [String] :description the series description (DICOM tag '0008,103E')
    # @option options [String] :time the series time (DICOM tag '0008,0031')
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

    # Inserts general series, study and patient level attributes from this
    # instance, as well as from the related study, patient and frame instances
    # to a DICOM object.
    #
    # @param [DICOM::DObject] dcm a DICOM object typically belonging to an image instance of this series
    # @return [DICOM::DObject] a DICOM object with the relevant attributes added
    #
    def add_attributes_to_dcm(dcm)
      # Series level:
      dcm.add_element(SOP_CLASS, @class_uid)
      dcm.add_element(SERIES_UID, @series_uid)
      dcm.add_element(SERIES_NUMBER, '1')
      # Study level:
      dcm.add_element(STUDY_DATE, @study.date)
      dcm.add_element(STUDY_TIME, @study.time)
      dcm.add_element(STUDY_UID, @study.study_uid)
      dcm.add_element(STUDY_ID, @study.id)
      # Frame level:
      dcm.add_element(PATIENT_ORIENTATION, '')
      dcm.add_element(FRAME_OF_REF, @study.iseries.frame.uid)
      dcm.add_element(POS_REF_INDICATOR, '')
      # Patient level:
      dcm.add_element(PATIENTS_NAME, @study.patient.name)
      dcm.add_element(PATIENTS_ID, @study.patient.id)
      dcm.add_element(BIRTH_DATE, @study.patient.birth_date)
      dcm.add_element(SEX, @study.patient.sex)
    end

    # Checks whether this series is of a modality which means it contains image
    # instances (e.g. CT, MR, RTImage, RTDose)
    #
    # @return [Boolean] true if the series is of an image type modality
    #
    def image_modality?
      if IMAGE_MODALITIES.include?(@modality)
        return true
      else
        return false
      end
    end

    # Gives the unique identifier string, which for an image type series is the
    # series instance UID, and for the other types of series (e.g. structure
    # set) is the SOP instance UID.
    #
    # @return [String] the unique identifier string of this series
    #
    def uid
      return @sop_uid || @series_uid
    end

  end

end
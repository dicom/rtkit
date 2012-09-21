module RTKIT

  class << self

    #--
    # Module attributes:
    #++

    # The algorithm used for contouring a filled area.
    attr_accessor :contour_algorithm
    # The DICOM Root used when generation UIDs.
    attr_accessor :dicom_root

  end

  #--
  # Default variable settings:
  #++

  # The default contour algorithm (Not in use yet!).
  self.contour_algorithm = :basic

end
module RTKIT

  # Specific Character Set.
  SPECIFIC_CHARACTER_SET = '0008,0005'
  # Image Type.
  IMAGE_TYPE = '0008,0008'
  # Instance Creation Date.
  IMAGE_DATE = '0008,0012'
  # Instance Creation Time.
  IMAGE_TIME = '0008,0013'
  # SOP Class UID.
  SOP_CLASS = '0008,0016'
  # SOP Instance UID.
  SOP_UID = '0008,0018'
  # Study Date.
  STUDY_DATE = '0008,0020'
  # Series Date.
  SERIES_DATE = '0008,0021'
  # Study Time.
  STUDY_TIME = '0008,0030'
  # Series Time.
  SERIES_TIME = '0008,0031'
  # Accession Number.
  ACCESSION_NUMBER = '0008,0050'
  # Modality.
  MODALITY = '0008,0060'
  # Conversion Type.
  CONVERSION_TYPE = '0008,0064'
  # Manufacturer.
  MANUFACTURER = '0008,0070'
  # Timezone Offset From UTC.
  TIMEZONE_OFFSET_FROM_UTC = '0008,0201'
  # Study description.
  STUDY_DESCR = '0008,1030'
  # Series description.
  SERIES_DESCR = '0008,103E'
  # Manufacturer's Model Name.
  MANUFACTURERS_MODEL_NAME = '0008,1090'
  # Referenced SOP Class UID.
  REF_SOP_CLASS_UID = '0008,1150'
  # Referenced SOP Instance UID.
  REF_SOP_UID = '0008,1155'
  # Patient's Name.
  PATIENTS_NAME = '0010,0010'
  # Patient's Name.
  PATIENTS_ID = '0010,0020'
  # Patient's Name.
  BIRTH_DATE = '0010,0030'
  # Patient's Name.
  SEX = '0010,0040'
  # Software Version(s).
  SOFTWARE_VERSION = '0018,1020'
  # Patient Position.
  PATIENT_POSITION = '0018,5100'
  # Study Instance UID.
  STUDY_UID = '0020,000D'
  # Series Instance UID.
  SERIES_UID = '0020,000E'
  # Study ID.
  STUDY_ID = '0020,0010'
  # Series Number.
  SERIES_NUMBER = '0020,0011'
  # Patient Orientation.
  PATIENT_ORIENTATION = '0020,0020'
  # Image Position (Patient).
  IMAGE_POSITION = '0020,0032'
  # Image Orientation (Patient):
  IMAGE_ORIENTATION = '0020,0037'
  # Frame of Reference UID.
  FRAME_OF_REF = '0020,0052'
  # Position Reference Indicator.
  POS_REF_INDICATOR = '0020,1040'
  # Samples per Pixel.
  SAMPLES_PER_PIXEL = '0028,0002'
  # Photometric Interpretation.
  PHOTOMETRIC_INTERPRETATION = '0028,0004'
  # Number of Frames.
  NR_FRAMES = '0028,0008'
  # Rows.
  ROWS = '0028,0010'
  # Columns.
  COLUMNS = '0028,0011'
  # Pixel Spacing.
  SPACING = '0028,0030'
  # Bits Allocated.
  BITS_ALLOCATED = '0028,0100'
  # Bits Stored.
  BITS_STORED = '0028,0101'
  # High Bit.
  HIGH_BIT = '0028,0102'
  # Pixel Representation.
  PIXEL_REPRESENTATION = '0028,0103'
  # Window Center.
  WINDOW_CENTER = '0028,1050'
  # Window Width.
  WINDOW_WIDTH = '0028,1051'
  # RT Image Label.
  RT_IMAGE_LABEL = '3002,0002'
  # RT Image Name.
  RT_IMAGE_NAME = '3002,0003'
  # RT Image Description.
  RT_IMAGE_DESCRIPTION = '3002,0004'
  # RT Image Plane.
  RT_IMAGE_PLANE = '3002,000C'
  # X-Ray Image Receptor Translation.
  X_RAY_IMAGE_RECEPTOR_TRANSLATION = '3002,000D'
  # X-Ray Image Receptor Angle.
  X_RAY_IMAGE_RECEPTOR_ANGLE = '3002,000E'
  # Image Plane Pixel Spacing.
  IMAGE_PLANE_SPACING = '3002,0011'
  # RT Image Position.
  RT_IMAGE_POSITION = '3002,0012'
  # Radiation Machine Name.
  RADIATION_MACHINE_NAME = '3002,0020'
  # Radiation Machine SAD.
  RADIATION_MACHINE_SAD = '3002,0022'
  # Radiation Machine SSD.
  RADIATION_MACHINE_SSD = '3002,0024'
  # RT Image SID.
  RT_IMAGE_SID = '3002,0026'
  # Exposure Sequence.
  EXPOSURE_SEQUENCE = '3002,0030'
  # Grid Frame Offset Vector.
  GRID_FRAME_OFFSETS = '3004,000C'
  # Dose Grid Scaling.
  DOSE_GRID_SCALING = '3004,000E'
  # Referenced Frame of Reference Sequence.
  REF_FRAME_OF_REF_SQ = '3006,0010'
  # RT Referenced Study Sequence.
  RT_REF_STUDY_SQ = '3006,0012'
  # RT Referenced Series Sequence.
  RT_REF_SERIES_SQ = '3006,0014'
  # Contour Image Sequence.
  CONTOUR_IMAGE_SQ = '3006,0016'
  # Structure Set ROI Sequence.
  STRUCTURE_SET_ROI_SQ = '3006,0020'
  # ROI Number.
  ROI_NUMBER = '3006,0022'
  # Referenced Frame of Reference UID.
  REF_FRAME_OF_REF = '3006,0024'
  # ROI Name.
  ROI_NAME = '3006,0026'
  # ROI Display Color.
  ROI_COLOR = '3006,002A'
  # ROI Generation Algorithm.
  ROI_ALGORITHM = '3006,0036'
  # ROI Contour Sequence.
  ROI_CONTOUR_SQ = '3006,0039'
  # Contour Sequence.
  CONTOUR_SQ = '3006,0040'
  # Contour Geometric Type.
  CONTOUR_GEO_TYPE = '3006,0042'
  # Number of Contour Points.
  NR_CONTOUR_POINTS = '3006,0046'
  # Contour Number.
  CONTOUR_NUMBER = '3006,0048'
  # Contour Data.
  CONTOUR_DATA = '3006,0050'
  # RT ROI Observations Sequence.
  RT_ROI_OBS_SQ = '3006,0080'
  # Obervation Number.
  OBS_NUMBER = '3006,0082'
  # Referenced ROI Number.
  REF_ROI_NUMBER = '3006,0084'
  # RT ROI Interpreted Type.
  ROI_TYPE = '3006,00A4'
  # ROI Interpreter.
  ROI_INTERPRETER = '3006,00A6'
  # Frame of Reference Relationship Sequence.
  FRAME_OF_REF_REL_SQ = '3006,00C0'
  # RT Plan Label.
  RT_PLAN_LABEL = '300A,0002'
  # RT Plan Name.
  RT_PLAN_NAME = '300A,0003'
  # RT Plan Description.
  RT_PLAN_DESCR = '300A,0004'
  # Fraction Group Sequence.
  FRACTION_GROUP_SQ = '300A,0070'
  # Fraction Group Number.
  FRACTION_GROUP_NUMBER = '300A,0071'
  # Beam Meterset.
  BEAM_METERSET = '300A,0086'
  # Beam Sequence.
  BEAM_SQ = '300A,00B0'
  # Treatment Machine Name.
  MACHINE_NAME = '300A,00B2'
  # Primary Dosimeter Unit.
  DOSIMETER_UNIT = '300A,00B3'
  # Source-Axis Distance.
  SAD = '300A,00B4'
  # RT Beam Limiting Device Sequence.
  COLL_SQ = '300A,00B6'
  # RT Beam Limiting Device Type.
  COLL_TYPE = '300A,00B8'
  # Number of Leaf/Jaw Pairs.
  NR_COLLIMATORS = '300A,00BC'
  # Leaf Position Boundaries.
  COLL_BOUNDARIES = '300A,00BE'
  # Beam Number.
  BEAM_NUMBER = '300A,00C0'
  # Beam Name.
  BEAM_NAME = '300A,00C2'
  # Beam Description.
  BEAM_DESCR = '300A,00C3'
  # Beam Type.
  BEAM_TYPE = '300A,00C4'
  # Radiation Type.
  RAD_TYPE = '300A,00C6'
  # Treatment Delivery Type.
  DELIVERY_TYPE = '300A,00CE'
  # Final Cumulative Meterset Weight.
  FINAL_METERSET_WEIGHT = '300A,010E'
  # Control Point Sequence.
  CONTROL_POINT_SQ = '300A,0111'
  # Cumulative Meterset Weight.
  CONTROL_POINT_INDEX = '300A,0112'
  # Nominal Beam Energy.
  BEAM_ENERGY = '300A,0114'
  # RT Beam Limiting Device Type Sequence.
  COLL_POS_SQ = '300A,011A'
  # Leaf/Jaw Positions.
  COLL_POS = '300A,011C'
  # Gantry Angle.
  GANTRY_ANGLE = '300A,011E'
  # Gantry Rotation Direction.
  GANTRY_DIRECTION = '300A,011F'
  # Beam Limiting Device Angle.
  COLL_ANGLE = '300A,0120'
  # Beam Limiting Device Rotation Direction.
  COLL_DIRECTION = '300A,0121'
  # Patient Support Angle.
  PEDESTAL_ANGLE = '300A,0122'
  # Patient Support Rotation Direction.
  PEDESTAL_DIRECTION = '300A,0123'
  # Table Top Eccentric Angle.
  TABLE_TOP_ANGLE = '300A,0125'
  # Table Top Eccentric Rotation Direction.
  TABLE_TOP_DIRECTION = '300A,0126'
  # Table Top Vertical Position.
  TABLE_TOP_VERTICAL = '300A,0128'
  # Table Top Longitudinal Position.
  TABLE_TOP_LONGITUDINAL = '300A,0129'
  # Table Top Lateral Position.
  TABLE_TOP_LATERAL = '300A,012A'
  # Isocenter Position.
  ISO_POS = '300A,012C'
  # Source to Surface Distance.
  SSD = '300A,0130'
  # Cumulative Meterset Weight.
  CUM_METERSET_WEIGHT = '300A,0134'
  # Gantry Pitch Angle.
  GANTRY_PITCH_ANGLE = '300A,014A'
  # Patient Setup Sequence.
  PATIENT_SETUP_SQ = '300A,0180'
  # Patient Setup Number.
  PATIENT_SETUP_NUMBER = '300A,0182'
  # Setup technique.
  SETUP_TECHNIQUE = '300A,01B0'
  # Table Top Vertical Setup Displacement.
  OFFSET_VERTICAL = '300A,01D2'
  # Table Top Longitudinal Setup Displacement.
  OFFSET_LONG = '300A,01D4'
  # Table Top Lateral Setup Displacement.
  OFFSET_LATERAL = '300A,01D6'
  # Referenced RT Plan Sequence.
  REF_PLAN_SQ = '300C,0002'
  # Referenced Beam Sequence.
  REF_BEAM_SQ = '300C,0004'
  # Referenced Beam Number.
  REF_BEAM_NUMBER = '300C,0006'
  # Referenced Structure Set Sequence.
  REF_STRUCT_SQ = '300C,0060'

  # The modalities that contain multiple images per series.
  IMAGE_SERIES = ['CT', 'MR']
  # The modalities that contain pixel data.
  IMAGE_MODALITIES = ['CT', 'MR', 'RTDOSE', 'RTIMAGE']
  # The accepted projection image modalities.
  PROJECTION_MODALITIES = ['RTIMAGE', 'CR']
  # The accepted slice image modalities.
  SLICE_MODALITIES = ['CT', 'MR', 'RTDOSE']
  # The modalities supported by RTKIT.
  SUPPORTED_MODALITIES = ['CT', 'MR', 'RTDOSE', 'RTIMAGE', 'RTPLAN', 'RTSTRUCT']

end
# Loads files and libraries that are used by RTKIT.
# Configures some DICOM and UID settings.
#

# External dependencies:
require 'dicom'
require 'narray'

# Ruby Standard Library dependencies:
require 'find'
require 'matrix'
require 'set'
require 'delegate'

# Gem specific extensions:
require_relative 'rtkit/extensions/array'
require_relative 'rtkit/extensions/n_array'
require_relative 'rtkit/extensions/string'

# General module features/settings:
require_relative 'rtkit/general/logging'
require_relative 'rtkit/general/version'
require_relative 'rtkit/general/constants'
require_relative 'rtkit/general/variables'
require_relative 'rtkit/general/methods'

# Super classes/modules:
require_relative 'rtkit/series'
require_relative 'rtkit/image'
require_relative 'rtkit/mixins/image_parent'
# Subclasses and independent classes:
# Collection classes:
require_relative 'rtkit/data_set'
require_relative 'rtkit/frame'
require_relative 'rtkit/patient'
require_relative 'rtkit/study'
require_relative 'rtkit/image_series'
require_relative 'rtkit/structure_set'
require_relative 'rtkit/plan'
require_relative 'rtkit/rt_dose'
require_relative 'rtkit/rt_image'
require_relative 'rtkit/cr_series'
# Image related:
require_relative 'rtkit/dose_volume'
require_relative 'rtkit/slice_image'
require_relative 'rtkit/projection_image'
require_relative 'rtkit/plane'
# DRR:
require_relative 'rtkit/drr/voxel_space'
require_relative 'rtkit/drr/pixel_space'
require_relative 'rtkit/drr/beam_geometry'
require_relative 'rtkit/drr/attenuation'
require_relative 'rtkit/drr/ray'
# Dose related:
require_relative 'rtkit/dose_distribution'
require_relative 'rtkit/dose'
# Segmentation related:
require_relative 'rtkit/structure'
require_relative 'rtkit/poi'
require_relative 'rtkit/roi'
require_relative 'rtkit/slice'
require_relative 'rtkit/contour'
require_relative 'rtkit/coordinate'
require_relative 'rtkit/bin_matcher'
require_relative 'rtkit/bin_volume'
require_relative 'rtkit/bin_image'
require_relative 'rtkit/staple'
require_relative 'rtkit/selection'
# Plan related:
require_relative 'rtkit/setup'
require_relative 'rtkit/beam'
require_relative 'rtkit/control_point'
require_relative 'rtkit/collimator'
require_relative 'rtkit/collimator_setup'

# Modify the source application entity title of the DICOM module:
DICOM.source_app_title = "RTKIT"
# Set a high threshold for the log level of the DICOM module's logger:
DICOM.logger.level = Logger::FATAL

# Use ruby-dicom's UID as our DICOM Root UID:
RTKIT.dicom_root = DICOM::UID_ROOT
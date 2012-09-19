# Loads files and libraries that are used by RTKIT.
# Configures some DICOM and UID settings.
#

# Logging:
require_relative 'rtkit/logging'
# Super classes/modules:
require_relative 'rtkit/series'
require_relative 'rtkit/pixel_data'
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
# Image related:
require_relative 'rtkit/dose_volume'
require_relative 'rtkit/image'
require_relative 'rtkit/plane'
# Dose related:
require_relative 'rtkit/dose_distribution'
require_relative 'rtkit/dose'
# Segmentation related:
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
# Module settings:
require_relative 'rtkit/version'
require_relative 'rtkit/constants'
require_relative 'rtkit/variables'
require_relative 'rtkit/methods'
# Extensions to the Ruby library:
require_relative 'rtkit/ruby_extensions'

# Ruby Standard Library dependencies:
require 'find'
require 'matrix'
require 'set'

# External dependencies:
require 'dicom'
require 'narray'

# Modify the source application entity title of the DICOM module:
DICOM.source_app_title = "RTKIT"
# Set a high threshold for the log level of the DICOM module's logger:
DICOM.logger.level = Logger::FATAL

# Use ruby-dicom's UID as our DICOM Root UID:
RTKIT.dicom_root = DICOM::UID_ROOT
require File.dirname(__FILE__) + '/../lib/rtkit'

RSpec.configure do |config|
  config.mock_with :mocha
end

# Defining constants for the sample RTKIT files that are used in the specification,
# while suppressing the annoying warnings when these constants are initialized.
module Kernel
  def suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    return result
  end
end

suppress_warnings do
  # Sample RTKIT folders:
  RTKIT::DIR_IMAGE_ONLY = 'samples/single_image/'
  RTKIT::DIR_STRUCT_ONLY = 'samples/single_struct/'
  RTKIT::DIR_PLAN_ONLY = 'samples/single_plan/'
  RTKIT::DIR_DOSE_ONLY = 'samples/single_dose/'
  RTKIT::DIR_RTIMAGE_ONLY = 'samples/single_rt_image/'
  # A simple 5 slice phantom with 8 contours:
  RTKIT::DIR_SIMPLE_PHANTOM_CONTOURS = 'samples/simple_phantom_contours/'
  # A simple 5 slice phantom with 8 contours, a 3 beam plan, corresponding dose grids and RT Images:
  RTKIT::DIR_SIMPLE_PHANTOM_CASE = 'samples/simple_phantom_case/'
  # Directory for writing temporary files:
  RTKIT::TMPDIR = "tmp/"
  # Single files:
  RTKIT::FILE_IMAGE = RTKIT::DIR_IMAGE_ONLY + 'ct_rect_phantom.dcm'
  RTKIT::FILE_STRUCT = RTKIT::DIR_STRUCT_ONLY + 'two_roi_rtstruct.dcm'
  RTKIT::FILE_PLAN = RTKIT::DIR_PLAN_ONLY + 'simple_plan.dcm'
  RTKIT::FILE_DOSE = RTKIT::DIR_DOSE_ONLY + 'dose.dcm'
  RTKIT::FILE_RTIMAGE = RTKIT::DIR_RTIMAGE_ONLY + 'rt_image.dcm'
end

# Create a directory for temporary files (and delete the directory if it already exists):
require 'fileutils'
FileUtils.rmtree(RTKIT::TMPDIR) if File.directory?(RTKIT::TMPDIR)
FileUtils.mkdir(RTKIT::TMPDIR)
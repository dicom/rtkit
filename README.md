# RTKIT

##*The Radiotherapy DICOM toolkit*

RTKIT is a toolkit for processing information from the various DICOM modalities
encountered in radiotherapy. It contains a number of classes and convenience methods
designed to make it easy to extract and manipulate radiotherapy information of
interest, like e.g. segmentation, plan, image and dose data.

Note that the toolkit is in an early state of release, and as such, may
be a bit rough in the edges. If you are interested in using RTKIT, please feel free
to send me an email with a brief explanation of what you would like to do, and I'll
be happy to assist you in getting started with Ruby and RTKIT.

### Supported DICOM Modalities

* CT
* MR
* RTSTRUCT
* RTPLAN
* RTDOSE
* RTIMAGE


## INSTALLATION

  gem install rtkit


## REQUIREMENTS

* Ruby 1.9.3 (or higher)
* ruby-dicom
* NArray


## BASIC USAGE

### Load & Include

    require 'rtkit'
    include RTKIT

### Load a set of DICOM files from a folder

    # Load files:
    ds = RTKIT::DataSet.read("C:/phantom_study/")

### Example: Merge two structure sets

    # Locate the structure set objects:
    structs = ds.patient.study.iseries.structs
    # Extract the two structure sets:
    s1 = structs.first
    s2 = structs.last
    # Transfer all ROIs except the external contour:
    s2.rois.each do |roi|
      s1.add_roi(roi) unless roi.name.downcase.include?('external')
    end
    # Ensure unique ROI Numbers:
    s1.set_numbers
    # Write the composed structure set object to file:
    s1.write("fusion_struct.dcm")

### IRB Tip

When working with RTKIT in irb, you may be annoyed with all the
information that is printed to screen. This is because in irb every
variable loaded in the program is automatically printed to the screen.
A useful hack to avoid this effect is to append ";0" after a command.
Example:

    ds = RTKIT::DataSet.read(folder) ;0


## RESOURCES

* [Source code repository](https://github.com/dicom/rtkit)
* [RTKIT gem](http://rubygems.org/gems/rtkit)
* [DICOM in Ruby](http://dicom.rubyforge.org/)
* [ruby-dicom forum](http://groups.google.com/group/ruby-dicom)


## COPYRIGHT

Copyright 2012-2016 Christoffer Lervåg

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see http://www.gnu.org/licenses/ .


## ABOUT THE AUTHOR

* Name: Christoffer Lervåg
* Location: Norway
* Email: chris.lervag [@nospam.com] @gmail.com

Please don't hesitate to email me if you have any feedback related to this project!
#    Copyright 2012 Christoffer Lervag
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
module RTKIT

  # Handles the DICOM data found at a particular location, typically all files contained in a specific directory.
  # A DataSet contains all DICOM objects read from the specified source,
  # organized in a patient - study - series - image structure.
  #
  class DataSet

    # An array of Frame instances loaded for this DataSet.
    attr_reader :frames
    # An array of Patient instances loaded for this DataSet.
    attr_reader :patients

    # Creates (and returns) a new DataSet instance from an array of DICOM objects.
    #
    # === Parameters
    #
    # * <tt>objects</tt> -- An array of DICOM::DObject instances which will be loaded into the DataSet.
    #
    def self.load(objects)
      raise ArgumentError, "Invalid argument 'objects'. Expected Array, got #{objects.class}." unless objects.is_a?(Array)
      raise ArgumentError, "Invalid argument 'objects'. Expected Array to contain only DObjects, got #{objects.collect{|dcm| dcm.class}.uniq}." if objects.collect{|dcm| dcm.class}.uniq != [DICOM::DObject]
      # We will put the objects in arrays sorted by modality, to control
      # the sequence in which they are loaded in our data structure:
      images = Array.new
      structs = Array.new
      plans = Array.new
      doses = Array.new
      rtimages = Array.new
      # Read and sort:
      objects.each do |dcm|
        # Find out which modality our DICOM file is and handle it accordingly:
        modality = dcm.value("0008,0060")
        case modality
          when *IMAGE_SERIES
            images << dcm
          when 'RTSTRUCT'
            structs << dcm
          when 'RTPLAN'
            plans << dcm
          when 'RTDOSE'
            doses << dcm
          when 'RTIMAGE'
            rtimages << dcm
          else
            #puts "Notice: Unsupported modality (ignored): #{modality}"
        end
      end
      # Create the DataSet:
      ds = DataSet.new
      # Add the objects to our data structure in a specific sequence:
      [images, structs, plans, doses, rtimages].each do |modality|
        modality.each do |dcm|
          ds.add(dcm)
        end
      end
      return ds
    end

    # Creates (and returns) a new DataSet instance from a specified path,
    # by reading and loading the DICOM files found in this directory (including its sub-directories).
    #
    # === Parameters
    #
    # * <tt>path</tt> -- A path to the directory containing the DICOM files you want to load.
    #
    def self.read(path)
      raise ArgumentError, "Invalid argument 'path'. Expected String, got #{path.class}." unless path.is_a?(String)
      # Get the files:
      files = RTKIT.files(path)
      raise ArgumentError, "No files found in the specified folder: #{path}" unless files.length > 0
      # Load DICOM objects:
      objects = Array.new
      failed = Array.new
      files.each do |file|
        dcm = DICOM::DObject.read(file)
        if dcm.read?
          objects << dcm
        else
          failed << file
          #puts "Warning: A file was not successfully read as a DICOM object. (#{file})"
        end
      end
      raise ArgumentError, "No DICOM files were successfully read from the specified folder: #{path}" unless objects.length > 0
      # Create the DataSet:
      return DataSet.load(objects)
    end

    # Creates a new DataSet instance.
    #
    def initialize
      # Create instance variables:
      @frames = Array.new
      @patients = Array.new
      @associated_frames = Hash.new
      @associated_patients = Hash.new
    end

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_data_set)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Adds a DICOM object to the dataset, by adding it
    # to an existing Patient, or creating a new Patient.
    #
    # === Restrictions
    #
    # To ensure a correct relationship between objects of different modality, please add
    # DICOM objects in the specific order: images, structs, plans, doses, rtimages
    # Alternatively, use the class method DataSet.load(objects), which handles this automatically.
    #
    def add(dcm)
      id = dcm.value(PATIENTS_ID)
      p = patient(id)
      if p
        p.add(dcm)
      else
        add_patient(Patient.load(dcm, self))
      end
    end

    # Adds a Frame to this DataSet.
    #
    def add_frame(frame)
      raise ArgumentError, "Invalid argument 'frame'. Expected Frame, got #{frame.class}." unless frame.is_a?(Frame)
      # Do not add it again if the frame already belongs to this instance:
      @frames << frame unless @associated_frames[frame.uid]
      @associated_frames[frame.uid] = frame
    end

    # Adds a Patient to this DataSet.
    #
    def add_patient(patient)
      raise ArgumentError, "Invalid argument 'patient'. Expected Patient, got #{patient.class}." unless patient.is_a?(Patient)
      # Do not add it again if the patient already belongs to this instance:
      @patients << patient unless @associated_patients[patient.id]
      @associated_patients[patient.id] = patient
    end

    # Returns the Frame instance mathcing the specified Frame's UID (if an UID argument is used).
    # If a specified UID doesn't match, nil is returned.
    # If no argument is passed, the first Frame instance associated with the DataSet is returned.
    #
    # === Parameters
    #
    # * <tt>uid</tt> -- String. The Frame of Reference UID.
    #
    def frame(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        raise ArgumentError, "Expected String (or nil), got #{args.first.class}." unless [String, NilClass].include?(args.first.class)
        return @associated_frames[args.first]
      else
        # No argument used, therefore we return the first Frame instance:
        return @frames.first
      end
    end

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Returns the Patient instance mathcing the specified Patient's ID (if an ID argument is used).
    # If a specified ID doesn't match, nil is returned.
    # If no argument is passed, the first Patient instance associated with the DataSet is returned.
    #
    # === Parameters
    #
    # * <tt>id</tt> -- String. The value of the Patient's ID element.
    #
    def patient(*args)
      raise ArgumentError, "Expected one or none arguments, got #{args.length}." unless [0, 1].include?(args.length)
      if args.length == 1
        raise ArgumentError, "Expected String (or nil), got #{args.first.class}." unless [String, NilClass].include?(args.first.class)
        return @associated_patients[args.first]
      else
        # No argument used, therefore we return the first Patient instance:
        return @patients.first
      end
    end

    # Prints the nested structure of patient - study - series - images that have been loaded to the dataset instance.
    #
    def print
      @patients.each do |p|
        puts p.name
        p.studies.each do |st|
          puts "  #{st.uid}"
          st.series.each do |se|
            puts "    #{se.modality}"
            if se.respond_to?(:images) && se.images
              puts "      (#{se.images.length} images)"
            end
          end
        end
      end
    end

    # Prints the nested structure of patient - study - modalities from
    # a RT point of view, with image_series - ss - plan, etc.
    #
    def print_rt
      @patients.each do |p|
        puts p.name
        p.studies.each do |st|
          puts "  #{st.uid}"
          st.image_series.each do |is|
            puts "    #{is.modality} (#{is.images.length} images)"
            is.structs.each do |struct|
              puts "      StructureSet"
              struct.plans.each do |plan|
                puts "        RTPlan"
                plan.rt_doses.each do |rt_dose|
                  puts "          RTDose"
                end
                plan.rt_images.each do |rt_image|
                  puts "          RTImage"
                end
              end
            end
          end
        end
      end
    end

    # Returns self.
    #
    def to_data_set
      self
    end


    # Following methods are private:
    private


    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
       [@frames, @patients]
    end

  end

end
module RTKIT

  class << self

    #--
    # Module methods:
    #++

    # Gives a date string in the DICOM format.
    #
    # @param [Time] date a Time object which is to be converted
    # @return [String] the DICOM date string
    #
    def date_str(date=Time.now)
      date.strftime('%Y%m%d')
    end

    # Finds all files contained in the specified folder or folders (including
    # any sub-folders).
    # Returns an array containing the discovered file strings.
    #
    # @param [String, Array<String>] path_or_paths one or more directory paths
    # @return [Array<String>] path strings for the files contained by the given directories
    #
    def files(path_or_paths)
      raise ArgumentError, "Invalid argument 'path_or_paths'. Expected String or Array, got #{paths.class}." unless [String, Array].include?(path_or_paths.class)
      raise ArgumentError, "Invalid argument 'path_or_paths'. Expected Array to contain only strings, got #{path_or_paths.collect{|p| p.class}.uniq}." if path_or_paths.is_a?(Array) && path_or_paths.collect{|p| p.class}.uniq != [String]
      paths = path_or_paths.is_a?(Array) ? path_or_paths : [path_or_paths]
      files = Array.new
      # Iterate the folders (and their subfolders) to extract all files:
      for dir in paths
        Find.find(dir) do |path|
          if FileTest.directory?(path)
            next
          else
            # Store the file in our array:
            files << path
          end
        end
      end
      return files
    end

    # Generates a random Frame Instance UID string.
    #
    # @return [String] a (random) frame instance UID value
    #
    def frame_uid
      return self.generate_uids('9').first
    end

    # Generates one or several random UID values.
    # The UIDs are based on the RTKIT dicom_root attribute, a type prefix,
    # a datetime part, a random number part, and an index part (when multiple
    # UIDs are requested, e.g. for a SOP Instances in a Series).
    #
    # @param [Integer] prefix an integer value which is put between the dicom root and the random part of the UID
    # @param [Integer] instances the desired number of UID values
    # @return [Array<String>] a collection of (random) UID values
    #
    def generate_uids(prefix, instances=1)
      prefix = prefix.to_i
      instances = instances.to_i
      raise ArgumentError, "Invalid argument 'prefix'. Expected positive Integer, got #{prefix}." if prefix < 1
      raise ArgumentError, "Invalid argument 'instances'. Expected positive Integer, got #{instances}." if instances < 1
      # NB! For UIDs, leading zeroes after a dot is not allowed, and must be removed:
      date = Time.now.strftime("%Y%m%d").to_i.to_s
      time = Time.now.strftime("%H%M%S").to_i.to_s
      random = rand(99999) + 1 # (Minimum 1, max. 99999)
      base_uid = [RTKIT.dicom_root, prefix, date, time, random].join('.')
      uids = Array.new
      if instances == 1
        uids << base_uid
      else
        (1..instances).to_a.each do |i|
          uids << "#{base_uid}.#{i}"
        end
      end
      return uids
    end

    # Generates a random Series Instance UID string.
    #
    # @return [String] a (random) series instance UID value
    #
    def series_uid
      return self.generate_uids('2').first
    end

    # Generates a random SOP Instance UID string.
    #
    # @return [String] a (random) SOP instance UID value
    #
    def sop_uid
      return self.generate_uids('3').first
    end

    # Generates a collection of random SOP Instance UID strings.
    #
    # @param [Integer] instances the desired number of SOP instance UID values
    # @return [Array<String>] a collection of (random) SOP instance UID values
    #
    def sop_uids(instances)
      raise ArgumentError, "Invalid argument 'instances'. Expected Integer, got #{instances.class}." unless instances.is_a?(Integer)
      return self.generate_uids('3', instances)
    end

    # Generates a random Study Instance UID string.
    #
    # @return [String] a (random) study instance UID value
    #
    def study_uid
      return self.generate_uids('1').first
    end

    # Gives a time string in the DICOM format.
    #
    # @param [Time] time a Time object which is to be converted
    # @return [String] the DICOM time string
    #
    def time_str(time=Time.now)
      time.strftime('%H%M%S')
    end

  end

end
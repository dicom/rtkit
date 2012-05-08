module RTKIT

  class << self

    #--
    # Module methods:
    #++

    # Finds all files contained in the specified folder or folders (including any sub-folders).
    # Returns an array containing the discovered file strings.
    #
    # === Parameters
    #
    # * <tt>path_or_paths</tt> -- String or Array of strings. The path(s) in which to find all files.
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

    # Generates and returns a random Frame Instance UID string.
    #
    def frame_uid
      return self.generate_uids('9').first
    end

    # Generates one or several random UID strings.
    # The UIDs are based on the RTKIT dicom_root attribute, a type prefix, a datetime part,
    # a random number part, and an index part (when multiple UIDs are requested,
    # e.g. for a SOP Instances in a Series).
    # Returns the UIDs in a string array.
    #
    # === Parameters
    #
    # * <tt>prefix</tt> -- String. A (numerical) type string which sits between the dicom root and the random part of the UID.
    # * <tt>instances</tt> -- Integer. The number of UIDs to generate. Defaults to 1.
    #
    def generate_uids(prefix, instances=1)
      raise ArgumentError, "Invalid argument 'prefix'. Expected (integer) String, got #{prefix.class}." unless prefix.is_a?(String)
      raise ArgumentError, "Invalid argument 'instances'. Expected Integer (when defined), got #{instances.class}." if instances && !instances.is_a?(Integer)
      raise ArgumentError, "Invalid argument 'prefix'. Expected non-zero Integer (String), got #{prefix}." if prefix.to_i == 0
      raise ArgumentError, "Invalid argument 'instances'. Expected positive Integer (when defined), got #{instances}." if instances && instances < 0
      prefix = prefix.to_i
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

    # Generates and returns a random Series Instance UID string.
    #
    def series_uid
      return self.generate_uids('2').first
    end

    # Generates and returns a random SOP Instance UID string.
    #
    def sop_uid
      return self.generate_uids('3').first
    end

    # Generates and returns a collection of random SOP Instance UID strings.
    #
    # === Parameters
    #
    # * <tt>instances</tt> -- Integer. The number of UIDs to generate.
    #
    def sop_uids(instances)
      raise ArgumentError, "Invalid argument 'instances'. Expected Integer, got #{instances.class}." unless instances.is_a?(Integer)
      return self.generate_uids('3', instances)
    end

    # Generates and returns a random Study Instance UID string.
    #
    def study_uid
      return self.generate_uids('1').first
    end

  end

end
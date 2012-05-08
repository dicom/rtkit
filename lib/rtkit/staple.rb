module RTKIT

  # The Staple class is used for simultaneously evaluating the performance of multiple volume segmentations
  # (typically derived from a RT Structure Set) as well as establishing the hidden true segmentation based
  # on probabilistic analysis of the supplied rater decisions. The determined true segmentation can easily
  # be exported to a RT Structure Set for external use.
  #
  # === THEORY
  #
  # Complete data:
  # (D, T)
  # Probability mass function of the complete data:
  # f(D,T | p,q)
  # Task:
  # Which performance level parameters (p,q) will maximize the complete data log likelihood function:
  # (p',q') = arg max_pq ln f(D,T | p,q)
  #
  # Indices:  D[i,j]
  # Voxel nr: i
  # Segmentation nr: j
  # Iteration nr: k
  #
  # The Expectation-Maximization algorithm approaches the problem of maximizing the incomplete data log likelihood
  # equation by proceeding iteratively with estimation and maximization of the complete data log likelihood function.
  #
  class Staple

    # An NArray containing all rater decisions (dimensions n*r).
    attr_reader :decisions
    # The maximum number of iterations to use in the STAPLE algorithm.
    attr_accessor :max_iterations
    # Number of voxels in the volume to be evaluated.
    attr_reader :n
    # Sensitivity float vector (length r). Each index contains a score from 0 (worst) to 1 (all true voxels segmented by the rater).
    attr_reader :p
    # An NArray containing the results of the Staple analysis (dimensions 2*r).
    attr_reader :phi
    # Specificity float vector (length r). Each index contains a score from 0 (worst) to 1 (none of the true remaining voxels are segmented by the rater).
    attr_reader :q
    # Number of raters to be evaluated.
    attr_reader :r
    # An NArray containing the determined true segmentation (dimensions equal to that of the input volumes).
    attr_reader :true_segmentation
    # The decision vectors used (derived from the supplied volumes).
    attr_reader :vectors
    # A float vector containing the weights assigned to each voxel (when rounded becomes the true segmentation) (length n).
    attr_reader :weights

    # Creates a Staple instance for the provided segmented volumes.
    #
    # === Parameters
    #
    # * <tt>bin_matcher</tt> -- An BinMatcher instance containing at least two volumes.
    # * <tt>options</tt> -- A hash of parameters.
    #
    # === Options
    #
    # * <tt>:max_iterations</tt> -- Integer. The maximum number of iterations to use in the STAPLE algorithm. Defaults to 25.
    #
    def initialize(bin_matcher, options={})
      raise ArgumentError, "Invalid argument 'bin_matcher'. Expected BinMatcher, got #{bin_matcher.class}." unless bin_matcher.is_a?(BinMatcher)
      raise ArgumentError, "Invalid argument 'bin_matcher'. Expected BinMatcher with at least 2 volumes, got #{bin_matcher.volumes.length}." unless bin_matcher.volumes.length > 1
      # Verify that the volumes have equal dimensions (columns and rows):
      volumes = bin_matcher.narrays(sort=false)
      raise ArgumentError, "Invalid argument 'bin_matcher'. Expected BinMatcher with volumes having the same number of columns, got #{volumes.collect{|v| v.shape[1]}.uniq}." unless volumes.collect{|v| v.shape[1]}.uniq.length == 1
      raise ArgumentError, "Invalid argument 'bin_matcher'. Expected BinMatcher with volumes having the same number of rows, got #{volumes.collect{|v| v.shape[2]}.uniq}." unless volumes.collect{|v| v.shape[2]}.uniq.length == 1
      # Make sure the volumes of the BinMatcher instance are comparable:
      bin_matcher.fill_blanks
      bin_matcher.sort_volumes
      @volumes = bin_matcher.narrays(sort=false)
      @original_volumes = @volumes.dup
      # Verify that the volumes have the same number of frames:
      raise ArgumentError, "Invalid argument 'bin_matcher'. Expected BinMatcher with volumes having the same number of frames, got #{@volumes.collect{|v| v.shape[0]}.uniq}." unless @volumes.collect{|v| v.shape[0]}.uniq.length == 1
      @bm = bin_matcher
      # Options:
      @max_iterations = options[:max_iterations] || 25
    end

    # Returns true if the argument is an instance with attributes equal to self.
    #
    def ==(other)
      if other.respond_to?(:to_staple)
        other.send(:state) == state
      end
    end

    alias_method :eql?, :==

    # Generates a Fixnum hash value for this instance.
    #
    def hash
      state.hash
    end

    # Along each dimension of the input volume, removes any index (slice, column or row) which is empty in all volumes.
    # The result is a reduced volume used for the analysis, yielding scores with better contrast on specificity.
    # This implementation aims to be independent of the number of dimensions in the input segmentation.
    #
    def remove_empty_indices
      # It only makes sense to run this volume reduction if the number of dimensions are 2 or more:
      if @original_volumes.first.dim > 1
        # To be able to reconstruct the volume later on, we need to keep track of the original indices
        # of the indices that remain in the new, reduced volume:
        @original_indices = Array.new(@original_volumes.first.dim)
        # For a volume the typical meaning of the dimensions will be: slice, column, row
        @original_volumes.first.shape.each_with_index do |size, dim_index|
          extract = Array.new(@original_volumes.first.dim, true)
          segmented_indices = Array.new
          size.times do |i|
            extract[dim_index] = i
            segmented = false
            @volumes.each do |volume|
              segmented = true if volume[*extract].max > 0
            end
            segmented_indices << i if segmented
          end
          @original_indices[dim_index] = segmented_indices
          extract[dim_index] = segmented_indices
          # Iterate each volume and pull out segmented indices:
          if segmented_indices.length < size
            @volumes.collect!{|volume| volume = volume[*extract]}
          end
        end
      end
    end

    # Applies the STAPLE algorithm to the dataset to determine the true hidden segmentation
    # as well as scoring the various segmentations.
    #
    def solve
      set_parameters
      # Vectors holding the values used for calculating the weights:
      a = NArray.float(@n)
      b = NArray.float(@n)
      # Set an initial estimate for the probabilities of true segmentation:
      @n.times do |i|
        @weights_current[i] = @decisions[i, true].mean
      end
      # Proceed iteratively until we have converged to a local optimum:
      k = 0
      while k < max_iterations do
        # Copy weights:
        @weights_previous = @weights_current.dup
        # E-step: Estimation of the conditional expectation of the complete data log likelihood function.
        # Deriving the estimator for the unobserved true segmentation (T).
        @n.times do |i|
          voxel_decisions = @decisions[i, true]
          # Find the rater-indices for this voxel where the raters' decisions equals 1 and 0:
          positive_indices, negative_indices = (voxel_decisions.eq 1).where2
          # Determine ai:
          # Multiply by corresponding sensitivity (or 1 - sensitivity):
          a_decision1_factor = (positive_indices.length == 0 ? 1 : @p[positive_indices].prod)
          a_decision0_factor = (negative_indices.length == 0 ? 1 : (1 - @p[negative_indices]).prod)
          a[i] = @weights_previous[i] * a_decision1_factor * a_decision0_factor
          # Determine bi:
          # Multiply by corresponding specificity (or 1 - specificity):
          b_decision0_factor = (negative_indices.length == 0 ? 1 : @q[negative_indices].prod)
          b_decision1_factor = (positive_indices.length == 0 ? 1 : (1 - @q[positive_indices]).prod)
          b[i] = @weights_previous[i] * b_decision0_factor * b_decision1_factor
          # Determine Wi: (take care not to divide by zero)
          if a[i] > 0 or b[i] > 0
            @weights_current[i] = a[i] / (a[i] + b[i])
          else
            @weights_current[i] = 0
          end
        end
        # M-step: Estimation of the performance parameters by maximization.
        # Finding the values of the expert performance level parameters that maximize the conditional expectation
        # of the complete data log likelihood function (phi - p,q).
        @r.times do |j|
          voxel_decisions = @decisions[true, j]
          # Find the voxel-indices for this rater where the rater's decisions equals 1 and 0:
          positive_indices, negative_indices = (voxel_decisions.eq 1).where2
          # Determine sensitivity:
          # Sum the weights for the indices where the rater's decision equals 1:
          sum_positive = (positive_indices.length == 0 ? 0 : @weights_current[positive_indices].sum)
          @p[j] = sum_positive / @weights_current.sum
          # Determine specificity:
          # Sum the weights for the indices where the rater's decision equals 0:
          sum_negative = (negative_indices.length == 0 ? 0 : (1 - @weights_current[negative_indices]).sum)
          @q[j] = sum_negative / (1 - @weights_current).sum
        end
        # Bump our iteration index:
        k += 1
        # Abort if we have reached the local optimum: (there is no change in the sum of weights)
        if @weights_current.sum - @weights_previous.sum == 0
#puts "Iteration aborted as optimum solution was found!" if @verbose
#logger.info("Iteration aborted as optimum solution was found!")
          break
        end
      end
      # Set the true segmentation:
      @true_segmentation_vector = @weights_current.round
      # Set the weights attribute:
      @weights = @weights_current
      # As this vector doesn't make much sense to the user, it must be converted to a volume. If volume reduction has
      # previously been performed, this must be taken into account when transforming it to a volume:
      construct_segmentation_volume
      # Construct a BinVolume instance for the true segmentation and add it as a master volume to the BinMatcher instance.
      update_bin_matcher
      # Set the phi variable:
      @phi[0, true] = @p
      @phi[1, true] = @q
    end

    # Returns self.
    #
    def to_staple
      self
    end


    private


    # Reshapes the true segmentation vector to a volume which is comparable with the input volumes for the
    # Staple instance. If volume reduction has been peformed, this must be taken into account.
    #
    def construct_segmentation_volume
      if @volumes.first.shape == @original_volumes.first.shape
        # Just reshape the vector (and ensure that it remains byte type):
        @true_segmentation = @true_segmentation_vector.reshape(*@original_volumes.first.shape).to_type(1)
      else
        # Need to take into account exactly which indices (slices, columns, rows) have been removed.
        # To achieve a correct reconstruction, we will use the information on the original volume indices of our
        # current volume, and apply it for each dimension.
        @true_segmentation = NArray.byte(*@original_volumes.first.shape)
        true_segmentation_in_reduced_volume = @true_segmentation_vector.reshape(*@volumes.first.shape)
        @true_segmentation[*@original_indices] = true_segmentation_in_reduced_volume
      end
    end

    # Sets the instance variables used by the STAPLE algorithm.
    #
    def set_parameters
      # Convert the volumes to vectors:
      @vectors = Array.new
      @volumes.each {|volume| @vectors << volume.flatten}
      verify_equal_vector_lengths
      # Number of voxels:
      @n = @vectors.first.length
      # Number of raters:
      @r = @vectors.length
      # Decisions array:
      @decisions = NArray.int(@n, @r)
      # Sensitivity vector: (Def: true positive fraction, or relative frequency of Dij = 1 when Ti = 1)
      # (If a rater includes all the voxels that are included in the true segmentation, his score is 1.0 on this parameter)
      @p = NArray.float(@r)
      # Specificity vector: (Def: true negative fraction, or relative frequency of Dij = 0 when Ti = 0)
      # (If a rater has avoided to specify any voxels that are not specified in the true segmentation, his score is 1.0 on this parameter)
      @q = NArray.float(@r)
      # Set initial parameter values: (p0, q0) - when combined, called: phi0
      @p.fill!(0.99999)
      @q.fill!(0.99999)
      # Combined scoring parameter:
      @phi = NArray.float(2, @r)
      # Fill the decisions matrix:
      @vectors.each_with_index do |decision, j|
        @decisions[true, j] = decision
      end
      # Indicator vector of the true (hidden) segmentation:
      @true_segmentation = NArray.byte(@n)
      # The estimate of the probability that the true segmentation at each voxel is Ti = 1: f(Ti=1)
      @weights_previous = NArray.float(@n)
      # Using the notation commom for EM algorithms and refering to this as the weight variable:
      @weights_current = NArray.float(@n)
    end

    # Returns the attributes of this instance in an array (for comparison purposes).
    #
    def state
      [@volumes.collect{|narr| narr.to_a}, @max_iterations]
    end

    # Updates the BinMatcher instance with information following the completion of the Staple analysis.
    # * Creates a BinVolume instance for the true segmentation and inserts it as a master volume.
    # * Updates the various volumes of the BinMatcher instance with their determined sensitivity and specificity scores.
    #
    def update_bin_matcher
      # Create an empty BinVolume with no ROI reference:
      staple = BinVolume.new(@bm.volumes.first.series)
      # Add BinImages to the staple volume:
      @true_segmentation.shape[0].times do |i|
        image_ref = @bm.volumes.first.bin_images[i].image
        staple.add(BinImage.new(@true_segmentation[i, true, true], image_ref))
      end
      # Set the staple volume as master volume:
      @bm.master = staple
      # Apply sensitivity & specificity score to the various volumes of the BinMatcher instance:
      @bm.volumes.each_with_index do |bin_vol, i|
        bin_vol.sensitivity = @p[i]
        bin_vol.specificity = @q[i]
      end
    end

    # The number of voxels must be the same for all segmentation vectors going into the STAPLE analysis.
    # If it is not, an error is raised.
    #
    def verify_equal_vector_lengths
      vector_lengths = @vectors.collect{|vector| vector.length}
      raise IndexError, "Unexpected behaviour: The vectors going into the STAPLE analysis have different lengths." unless vector_lengths.uniq.length == 1
    end

  end
end
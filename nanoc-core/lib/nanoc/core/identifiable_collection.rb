# frozen_string_literal: true

module Nanoc
  module Core
    class IdentifiableCollection
      prepend MemoWise

      # include Nanoc::Core::ContractsSupport
      include Enumerable

      extend Forwardable

      def_delegator :@objects, :each
      def_delegator :@objects, :size

      def initialize
        raise 'IdentifiableCollection is abstract and cannot be instantiated'
      end

      # contract C::Or[Hash, C::Named['Nanoc::Core::Configuration']], C::IterOf[C::RespondTo[:identifier]], C::Maybe[String] => C::Any
      def initialize_basic(config, objects = [], name = nil)
        @config = config
        @objects = Hamster::Vector.new(objects)
        @name = name
      end

      # contract C::None => String
      def inspect
        "<#{self.class}>"
      end

      # contract C::None => self
      def freeze
        @objects.freeze
        each(&:freeze)
        build_mapping
        super
      end

      # contract C::Any => C::Maybe[C::RespondTo[:identifier]]
      def [](arg)
        if frozen?
          get_memoized(arg)
        else
          get_unmemoized(arg)
        end
      end

      # contract C::Any => C::IterOf[C::RespondTo[:identifier]]
      def find_all(arg)
        if frozen?
          find_all_memoized(arg)
        else
          find_all_unmemoized(arg)
        end
      end

      # contract C::None => C::ArrayOf[C::RespondTo[:identifier]]
      def to_a
        @objects.to_a
      end

      # contract C::None => C::Bool
      def empty?
        @objects.empty?
      end

      # contract C::RespondTo[:identifier] => self
      def add(obj)
        self.class.new(@config, @objects.add(obj))
      end

      # contract C::Func[C::RespondTo[:identifier] => C::Any] => self
      def reject(&block)
        self.class.new(@config, @objects.reject(&block))
      end

      # contract C::Any => C::Maybe[C::RespondTo[:identifier]]
      def object_with_identifier(identifier)
        if frozen?
          @mapping[identifier.to_s]
        else
          find { |i| i.identifier == identifier }
        end
      end

      protected

      # contract C::Any => C::Maybe[C::RespondTo[:identifier]]
      def get_unmemoized(arg)
        case arg
        when Nanoc::Core::Identifier
          object_with_identifier(arg)
        when String
          object_with_identifier(arg) || object_matching_glob(arg)
        when Regexp
          find { |i| i.identifier.to_s =~ arg }
        else
          raise ArgumentError, "don’t know how to fetch objects by #{arg.inspect}"
        end
      end

      # contract C::Any => C::Maybe[C::RespondTo[:identifier]]
      def get_memoized(_arg)
        # TODO: Figure out how to get memo_wise to work with subclasses
        raise 'implement in subclasses'
      end

      # contract C::Any => C::IterOf[C::RespondTo[:identifier]]
      def find_all_unmemoized(arg)
        pat = Pattern.from(arg)
        select { |i| pat.match?(i.identifier) }
      end

      # contract C::Any => C::IterOf[C::RespondTo[:identifier]]
      def find_all_memoized(arg)
        find_all_unmemoized(arg)
      end
      memo_wise :find_all_memoized

      def object_matching_glob(glob)
        if use_globs?
          pat = Pattern.from(glob)
          find { |i| pat.match?(i.identifier) }
        end
      end

      def build_mapping
        @mapping = {}
        each do |object|
          @mapping[object.identifier.to_s] = object
        end
      end

      # contract C::None => C::Bool
      def use_globs?
        @config[:string_pattern_type] == 'glob'
      end
    end
  end
end

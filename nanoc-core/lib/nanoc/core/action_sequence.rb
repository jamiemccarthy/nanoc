# frozen_string_literal: true

module Nanoc
  module Core
    class ActionSequence
      # include Nanoc::Core::ContractsSupport
      include Enumerable
      prepend MemoWise

      attr_reader :item_rep
      attr_reader :actions

      def initialize(item_rep, actions: [])
        @item_rep = item_rep
        @actions = actions
      end

      # contract C::None => Numeric
      def size
        @actions.size
      end

      # contract Numeric => C::Maybe[Nanoc::Core::ProcessingAction]
      def [](idx)
        @actions[idx]
      end

      # contract C::None => C::ArrayOf[Nanoc::Core::ProcessingAction]
      def snapshot_actions
        @actions.select { |a| a.is_a?(Nanoc::Core::ProcessingActions::Snapshot) }
      end

      # contract C::None => Array
      def paths
        snapshot_actions.map { |a| [a.snapshot_names, a.paths] }
      end

      def serialize
        serialize_uncached
      end
      memo_wise :serialize

      # contract C::None => Array
      def serialize_uncached
        to_a.map(&:serialize)
      end

      # contract C::Func[Nanoc::Core::ProcessingAction => C::Any] => self
      def each(&block)
        @actions.each(&block)
        self
      end

      # contract C::Func[Nanoc::Core::ProcessingAction => C::Any] => self
      def map(&block)
        self.class.new(
          @item_rep,
          actions: @actions.map(&block),
        )
      end
    end
  end
end

module EventsManagement
  module Crud
    class Creator < EventsManagement::BaseInterface

      def initialize
        super
      end

      def process(data)
        self.build_request(:create, data)
      end
    end
  end
end
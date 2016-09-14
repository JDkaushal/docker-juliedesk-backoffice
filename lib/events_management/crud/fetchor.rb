module EventsManagement
  module Crud
    class Fetchor < EventsManagement::BaseInterface

      def initialize
        super
      end

      def process(data)
        self.build_request(:fetch, data)
      end
    end
  end
end
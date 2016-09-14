module EventsManagement
  module Crud
    class Updator < EventsManagement::BaseInterface

      def initialize
        super
      end

      def process(data)
        self.build_request(:update, data)
      end
    end
  end
end

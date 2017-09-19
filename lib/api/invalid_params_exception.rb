module Api

  class InvalidParamsException < Exception
    attr_reader :errors

    def initialize(message, errors)
      @errors = errors
      super(message)
    end
  end

end
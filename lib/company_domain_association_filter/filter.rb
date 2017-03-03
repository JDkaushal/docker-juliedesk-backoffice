module CompanyDomainAssociationFilter
  class Filter

    # /(?:\.edu$|^fre)/ to add others just add | followed by pattern inside the brackets
    DOMAINS_TO_FILTER_REGEX = /(?:\.edu$)/

    def initialize
    end

    def filter(domain)
      apply_filters(domain).present?
    end

    private

    def apply_filters(domain)
      domain =~ DOMAINS_TO_FILTER_REGEX
    end

  end
end
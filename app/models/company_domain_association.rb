class CompanyDomainAssociation < ActiveRecord::Base

  validates_uniqueness_of :domain, scope: :company_name

  def self.populate
    ClientContact.all.each do |c|

      if c.email.present?
        split = c.email.split('@')[1]

        if split.present?
          domain = split.gsub('@', '')
          record = CompanyDomainAssociation.find_by(company_name: c.company, domain: domain)
          if record.blank?
            CompanyDomainAssociation.create(company_name: c.company, domain: domain)
          end

        end


      end

    end

    puts CompanyDomainAssociation.count

  end
end

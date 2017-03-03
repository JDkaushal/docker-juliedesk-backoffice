require "rails_helper"

describe CompanyDomainAssociationFilter::Filter do

  describe 'filter' do
    subject(:domain_is_filtered) { CompanyDomainAssociationFilter::Filter.new.filter(domain) }

    context '.edu domain' do
      let(:domain) { 'domain.edu' }

      it 'should return true' do
        expect(domain_is_filtered).to be(true)
      end
    end

    context 'not filtered domain' do
      let(:domain) { 'domain.not_filtered' }

      it 'should return false' do
        expect(domain_is_filtered).to be(false)
      end
    end
  end
end
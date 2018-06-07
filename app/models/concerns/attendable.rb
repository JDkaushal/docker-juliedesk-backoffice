module Attendable
  extend ActiveSupport::Concern

  class AttendeesFieldNotPresent < StandardError ; end

  included do
    #raise AttendeesFieldNotPresent.new unless (self.respond_to?(:column_names) && self.column_names.include?(:attendees))
  end

  def get_attendees
    return [] if self.attendees.blank?
    Attendee.from_json(self.attendees)
  end

  def get_present_attendees
    self.get_attendees.select(&:present?)
  end

  def get_thread_owner_attendee
    self.get_present_attendees.find(&:is_thread_owner)
  end

  def get_client_attendees
    self.get_attendees.select(&:is_client)
  end

  def get_non_client_attendees
    self.get_attendees.reject(&:is_client)
  end

  def get_attendees_from_same_company
    account_company = account.try(:company)
    return [] if account_company.blank?

    self.get_attendees.select { |attendee| attendee.company == account_company }
  end

  def get_attendees_from_other_companies
    account_company = account.try(:company)
    self.get_attendees.select { |attendee| attendee.company != account_company }
  end

  def get_present_attendee_by_email(email)
    get_present_attendees.find { |attendee| attendee.email == email }
  end
end
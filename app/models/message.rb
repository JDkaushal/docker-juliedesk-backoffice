class Message < ActiveRecord::Base

  include ActionView::Helpers::TextHelper
  include ERB::Util
  include ApplicationHelper

  belongs_to :messages_thread
  has_many :message_classifications
  has_one :auto_message_classification
  has_many :message_interpretations

  has_many :automated_message_classifications, class_name: "AutomaticProcessing::AutomatedMessageClassification"

  has_one :main_message_interpretation, -> { where(question: MessageInterpretation::QUESTION_MAIN) }, class_name: 'MessageInterpretation'
  has_one :entities_message_interpretation, -> { where(question:  MessageInterpretation::QUESTION_ENTITIES) }, class_name: 'MessageInterpretation'

  attr_accessor :server_message, :ics_attendees
  FETCHED_ATTACHMENT_TYPES = ["application/ics", "text/calendar"]

  # Fetch attendees from ics attached to the message if any, we memoize the result in an instance variable
  def get_ics_attendees_if_any
    @ics_attendees ||= []

     if self.server_message.present? && self.server_message['attachments_data'].present? && @ics_attendees.blank?

      attachment_data_type = self.server_message['attachments_data'][0]['type']

      if FETCHED_ATTACHMENT_TYPES.include?(attachment_data_type)
        ics_data = fetch_ics
        if ics_data.present?
          ics_data.gsub!(/\n\./, "\n") # TODO : manager better / dirty fix
          ics_data.gsub!(/BEGIN:X-ICLOUD-PERUSER(.)*END:X-ICLOUD-PERUSER/m,'')
          parsed_ics_data = Icalendar::Calendar.parse(ics_data)
          if parsed_ics_data.present?
            event = parsed_ics_data.first.events.first
            # .reject{|a| a == nil}git  because compact does not work, it is not really a nil that is returned when the .attendee method, it is an instance of Icalendar::Values::CalAddress evaluating to nil so compact does not work on it
            @ics_attendees = event.attendee.reject{|a| !a.respond_to?(:to)}.map(&:to)
            if event.organizer.present? && event.organizer.respond_to?(:to)
              @ics_attendees.push(event.organizer.to)
            end
          end
        end
      end
    end

    @ics_attendees
  end

  def self.clean_server_message!(server_message)
    server_message['from'].try(:gsub!, '?', '')
    server_message['cc'].try(:gsub!, '?', '')
    server_message['to'].try(:gsub!, '?', '')
  end

  def populate_single_server_message
    server_thread = self.messages_thread.server_thread(force_refresh: true, show_split: true)
    raise 'Impossible to fetch server thread' unless server_thread
    server_message = server_thread['messages'].find{|server_message| server_message['id'] == self.server_message_id}
    Message.clean_server_message!(server_message)

    self.server_message = server_message
  end

  def fetch_ics
    begin
      EmailServerInterface.new.build_request(:fetch_ics, {message_id: self.server_message['id'], attachment_id: self.server_message['attachments_data'][0]['attachment_id']})['data']
    rescue => e
      Raven.capture_exception(e) unless ENV['SENTRY_DSN'].nil?
      nil
    end
  end

  def compute_allowed_attendees(julie_alias_emails)
    self.allowed_attendees = AllowedAttendees::MessageManager.new(self, self.server_message, julie_alias_emails).extract_allowed_attendees
  end

  def self.delegate_to_julia(message, julie_aliases_cache)
    Ai::EmailProcessing::Processor.new(message.id, nil).delay.process
  end

  def self.delegate_to_julia_async(message_id)
    ConscienceFullWorker.enqueue message_id, {}
  end

  def get_reply_all_recipients_emails
    recipients = JSON.parse(self.reply_all_recipients)

    recipients["to"].map{|r| r["email"].try(:downcase)} + recipients["cc"].map{|r| r["email"].try(:downcase)}
  end

  def clean_delete
    self.message_classifications.each do |mc|
      mc.clean_delete
    end
    self.delete
  end

  def get_email_sender
    parsed_reply_all_recipients = JSON.parse(self.reply_all_recipients)

    if parsed_reply_all_recipients['from'].present? && parsed_reply_all_recipients['from'].is_a?(Array)
      email_sender_email = parsed_reply_all_recipients['from'][0]['email']
    else
      if parsed_reply_all_recipients['to'].present? && parsed_reply_all_recipients['to'].is_a?(Array)
        email_sender_email = parsed_reply_all_recipients['to'][0]['email']
      else
        email_sender_email = ''
      end
    end
  end

  def get_email_from
    parsed_reply_all_recipients = JSON.parse(self.reply_all_recipients)
    email_sender_email = nil

    if parsed_reply_all_recipients['from'].present? && parsed_reply_all_recipients['from'].is_a?(Array)
      email_sender_email = parsed_reply_all_recipients['from'][0]['email']
    end

    email_sender_email
  end


  def async_auto_reply_mailing_list
    AutoReplyMailingListWorker.enqueue(self.id)
  end

  def auto_reply_mailing_list
    account = self.messages_thread.account
    I18n.locale = account.locale || :en

    if ENV['DEFAULT_JULIE_ALIAS_EMAIL'] != ENV['COMMON_JULIE_ALIAS_EMAIL']
      text = I18n.t("automatic_reply_emails.mailing_list.text_specific_tenant", client_name: account.usage_name)
    else
      text = I18n.t("automatic_reply_emails.mailing_list.text", client_name: account.usage_name)
    end


    julie_alias = JulieAlias.find_by_email(ENV['DEFAULT_JULIE_ALIAS_EMAIL'])
    html_signature = julie_alias.signature_en.gsub(/%REMOVE_IF_PRO%/, "")
    text_signature = julie_alias.footer_en.gsub(/%REMOVE_IF_PRO%/, "")

    if "#{I18n.locale}" == "fr"
      html_signature = julie_alias.signature_fr.gsub(/%REMOVE_IF_PRO%/, "")
      text_signature = julie_alias.footer_fr.gsub(/%REMOVE_IF_PRO%/, "")
    end

    email_params = {
        subject: "Re: #{"#{self.messages_thread.subject}".gsub(/^Re: /, "").gsub(/^Fw: /, "")}",
        from: julie_alias.generate_from,
        to: account.email,
        cc: "",
        text: "#{text}#{text_signature}#{strip_tags(html_signature)}",
        html: "#{text_to_html("#{text}#{text_signature}")}#{html_signature}",
        quote_replied_message: true,
        reply_to_message_id:  self.server_message_id
    }

    EmailServer.deliver_message(email_params)['id']
  end

  def send_account_configuration_pending_email
    self.interprete! unless Rails.env.development?

    locale_to_use = self.message_interpretations.find{|mI| mI.question == 'main'}.try(:json_response).try(:[], 'language_detected') || :en
    current_messages_thread = self.messages_thread
    current_reply_all_recipients = JSON.parse(self.reply_all_recipients)

    to = if self.messages_thread.account
           self.messages_thread.account.email
         else
           current_reply_all_recipients['from'].first['email']
         end

    julie_alias = current_messages_thread.julie_alias

    html_signature = julie_alias.signature_en.gsub(/%REMOVE_IF_PRO%/, "")
    text_signature = julie_alias.footer_en.gsub(/%REMOVE_IF_PRO%/, "")

    text = I18n.t("automatic_reply_emails.configuration_pending", locale: locale_to_use, client_name: self.messages_thread.account.usage_name)

    if locale_to_use == "fr"
      html_signature = julie_alias.signature_fr.gsub(/%REMOVE_IF_PRO%/, "")
      text_signature = julie_alias.footer_fr.gsub(/%REMOVE_IF_PRO%/, "")
    end

    email_params = {
      subject: "Re: #{"#{current_messages_thread.subject}".gsub(/^Re: /, "").gsub(/^Fw: /, "")}",
      from: julie_alias.generate_from,
      to: [to].join(','),
      cc: [].join(','),
      bcc: ["hello@juliedesk.com"].join(','),
      text: "#{text}#{text_signature}#{strip_tags(html_signature)}",
      html: "#{text_to_html("#{text}#{text_signature}")}#{html_signature}",
      quote_replied_message: true,
      reply_to_message_id:  self.server_message_id
    }

    current_messages_thread.update(account_request_auto_email_sent: true)

    EmailServer.deliver_message(email_params)['id']
  end

  def auto_reply_target_account_precisions_email
   self.interprete! unless Rails.env.development?

   locale_to_use = self.message_interpretations.find{|mI| mI.question == 'main'}.try(:json_response).try(:[], 'language_detected') || :en
   current_messages_thread = self.messages_thread
   current_reply_all_recipients = JSON.parse(self.reply_all_recipients)
   to = current_reply_all_recipients['from'].first['email']

   julie_alias = current_messages_thread.julie_alias
   julie_alias_email = julie_alias.email

   same_domain = ApplicationHelper.extract_domain(to) == ApplicationHelper.extract_domain(julie_alias.email)

   using_julie_alias = julie_alias_email != ENV['COMMON_JULIE_ALIAS_EMAIL']

   html_signature = julie_alias.signature_en.gsub(/%REMOVE_IF_PRO%/, "")
   text_signature = julie_alias.footer_en.gsub(/%REMOVE_IF_PRO%/, "")

   using_julie_alias_template = using_julie_alias && !same_domain
   text = I18n.t("automatic_reply_emails.target_account_precisions.text.#{using_julie_alias_template ? 'with_julie_alias' : 'without_julie_alias'}", locale: locale_to_use)

   if locale_to_use == "fr"
     html_signature = julie_alias.signature_fr.gsub(/%REMOVE_IF_PRO%/, "")
     text_signature = julie_alias.footer_fr.gsub(/%REMOVE_IF_PRO%/, "")
   end

    email_params = {
      subject: "Re: #{"#{current_messages_thread.subject}".gsub(/^Re: /, "").gsub(/^Fw: /, "")}",
      from: julie_alias.generate_from,
      to: [to].join(','),
      cc: [].join(','),
      bcc: ["hello@juliedesk.com"].join(','),
      text: "#{text}#{text_signature}#{strip_tags(html_signature)}",
      html: "#{text_to_html("#{text}#{text_signature}")}#{html_signature}",
      quote_replied_message: true,
      reply_to_message_id:  self.server_message_id
    }

   current_messages_thread.update(account_request_auto_email_sent: true)

   EmailServer.deliver_message(email_params)['id']
  end

  # Should refactor it to a more generic automatics emails send function
  # email_type params should be :specific_email or anything else
  def send_account_notice_email(email_type, email_to_send_to = nil, client_usage_name = nil)
    self.interprete! if !Rails.env.development? && !Rails.env.test?

    locale_to_use = self.message_interpretations.find{|mI| mI.question == 'main'}.try(:json_response).try(:[], 'language_detected') || :en
    current_messages_thread = self.messages_thread

    to = if email_type == 'account_deactivated.client'
      email_to_send_to
     elsif email_type == 'account_gone_unsubscribe.client'
      email_to_send_to
    else
      current_reply_all_recipients = JSON.parse(self.reply_all_recipients)
      current_reply_all_recipients['from'].first['email']
    end

    julie_alias = current_messages_thread.julie_alias

    html_signature = julie_alias.signature_en.gsub(/%REMOVE_IF_PRO%/, "")
    text_signature = julie_alias.footer_en.gsub(/%REMOVE_IF_PRO%/, "")

    identifier = current_messages_thread.account ? current_messages_thread.account.company_hash['identifier'] : ""  

    text = I18n.t("automatic_reply_emails.#{email_type}", locale: locale_to_use, client_name: client_usage_name, identifier: identifier)

    if locale_to_use == "fr"
      html_signature = julie_alias.signature_fr.gsub(/%REMOVE_IF_PRO%/, "")
      text_signature = julie_alias.footer_fr.gsub(/%REMOVE_IF_PRO%/, "")
    end

    email_params = {
      subject: "Re: #{"#{current_messages_thread.subject}".gsub(/^Re: /, "").gsub(/^Fw: /, "")}",
      from: julie_alias.generate_from,
      to: [to].join(','),
      cc: [].join(','),
      bcc: ["hello@juliedesk.com"].join(','),
      text: "#{text}#{text_signature}#{strip_tags(html_signature)}",
      html: "#{text_to_html("#{text}#{text_signature}")}#{html_signature}",
      quote_replied_message: true,
      reply_to_message_id:  self.server_message_id
    }

    current_messages_thread.update(account_request_auto_email_sent: true)

    EmailServer.deliver_message(email_params)['id']
  end

  def send_auto_email(email_type, translation_params = {}, email_to_send_to = nil)
    self.interprete! unless Rails.env.development?

    locale_to_use = self.message_interpretations.find{|mI| mI.question == 'main'}.try(:json_response).try(:[], 'language_detected') || :en
    current_messages_thread = self.messages_thread

    current_reply_all_recipients = JSON.parse(self.reply_all_recipients)

    to = email_to_send_to || current_reply_all_recipients['from'].first['email']

    julie_alias = current_messages_thread.julie_alias
    # In case the julie alias associated with the thread is not working, we will fallback to the main Julie for sending the automated message
    if email_type == AutomaticsEmails::Rules::TYPE_ACCESS_LOST_IN_THREAD_SHARED_CONNEXION || !julie_alias.can_send?
      julie_alias = JulieAlias.where(email: ENV['DEFAULT_JULIE_ALIAS_EMAIL']).first
    end

    html_signature = julie_alias.signature_en.gsub(/%REMOVE_IF_PRO%/, "")
    text_signature = julie_alias.footer_en.gsub(/%REMOVE_IF_PRO%/, "")

    translation_params.symbolize_keys!

    text = I18n.t("automatic_reply_emails.#{translation_params[:key]}", {locale: locale_to_use}.merge(translation_params))

    if locale_to_use == "fr"
      html_signature = julie_alias.signature_fr.gsub(/%REMOVE_IF_PRO%/, "")
      text_signature = julie_alias.footer_fr.gsub(/%REMOVE_IF_PRO%/, "")
    end

    bcc = (email_type == AutomaticsEmails::Rules::TYPE_NO_AVAILABLE_SLOTS) ? []: ["product@juliedesk.com"]

    email_params = {
        subject: "Re: #{"#{current_messages_thread.subject}".gsub(/^Re: /, "").gsub(/^Fw: /, "")}",
        from: julie_alias.generate_from,
        to: [to].join(','),
        cc: [].join(','),
        bcc: bcc.join(','),
        text: "#{text}#{text_signature}#{strip_tags(html_signature)}",
        html: "#{text_to_html_with_tags("#{text}#{text_signature}")}#{html_signature}",
        quote_replied_message: true,
        reply_to_message_id:  self.server_message_id,
        tags: ["EMAIL_AUTO_#{email_type}"]
    }

    current_messages_thread.update(account_request_auto_email_sent: true)

    server_message = EmailServer.deliver_message(email_params)

    message_recipients = Message.generate_reply_all_recipients(server_message, JulieAlias.all.map(&:email))

    m = self.messages_thread.messages.create server_message_id: server_message['id'],
                                        received_at: DateTime.parse(server_message['date']),
                                        reply_all_recipients: message_recipients.to_json,
                                        from_me: server_message['from_me'],
                                             auto_email_kind: email_type
    m.server_message = server_message

    m.id
  end

  def initial_recipients params={}
    # Get basic reply all recipients (details in message#generate_reply_all_recipients)
    reply_all_recipients = JSON.parse(self.reply_all_recipients || "{}")

    initial_to_emails = reply_all_recipients['to'].map{|c| c['email'].try(:downcase)}
    initial_cc_emails = reply_all_recipients['cc'].map{|c| c['email'].try(:downcase)}

    # Get all emails present in an email of the thread
    contact_emails = params[:contact_emails] || self.messages_thread.contacts(with_client: true).map { |c| c[:email].try(:downcase) }

    # Get all present attendees emails
    present_attendees = params[:present_attendees] || self.messages_thread.computed_data[:attendees].select{|a| a['isPresent'] == 'true'}

    attendee_emails = present_attendees.map{|a| a['email'].try(:downcase)}

    # Get main client email in this thread
    all_client_emails = self.messages_thread.account.try(:all_emails) || []
    client_email = ((initial_to_emails + initial_cc_emails + attendee_emails) & all_client_emails).first || self.messages_thread.client_email

    # List all possible emails
    possible_emails = (initial_to_emails +
        initial_cc_emails +
        attendee_emails +
        contact_emails +
        [client_email]).uniq
    possible_emails += (self.messages_thread.julie_aliases || []).map(&:email)
    possible_emails.reject! { |c| c.blank? }

    if params[:only_reply_all]
      computed_initial_to_emails = initial_to_emails.uniq
      computed_initial_cc_emails = initial_cc_emails.uniq

      # If client email not present in computed TO or CC, we add it to CC, or even TO if TO is empty
      unless client_email.blank? || ((computed_initial_to_emails + computed_initial_cc_emails).include? client_email)
        if computed_initial_to_emails.empty?
          computed_initial_to_emails += [client_email]
        else
          computed_initial_cc_emails += [client_email]
        end
      end

      {
          to: computed_initial_to_emails.sort,
          cc: computed_initial_cc_emails.sort,
          client: client_email,
          possible: possible_emails.sort
      }
    else
      # This case is used for suggest_dates action
      unassisted_attendee_emails = present_attendees.select{|att| att['assisted'] != 'true'}.map{|att| att['email'].try(:downcase)}
      assistant_attendee_emails = present_attendees.select{|att| att['isAssistant'] == 'true'}.map{|att| att['email'].try(:downcase)}
      client_attendee_emails = present_attendees.select{|att| att['isClient'] == 'true'}.map{|att| att['email'].try(:downcase)}

      # Need to reject empty string because there can be some if the operator enter an email then don't suppress it appropriately
      computed_initial_to_emails = ((unassisted_attendee_emails + assistant_attendee_emails).uniq - all_client_emails).reject { |c| c.blank? }
      computed_initial_cc_emails = ((client_attendee_emails + initial_to_emails + initial_cc_emails).uniq - computed_initial_to_emails - all_client_emails).reject { |c| c.blank? }

      if computed_initial_to_emails.empty?
        result = {
            to: [client_email].compact.sort.map(&:downcase),
            cc: computed_initial_cc_emails.sort.map(&:downcase),
            client: client_email,
            possible: possible_emails.sort
        }
      else
        result = {
            to: computed_initial_to_emails.sort.map(&:downcase),
            cc: (computed_initial_cc_emails + [client_email]).sort.map(&:downcase),
            client: client_email,
            possible: possible_emails.sort
        }
      end

      result[:cc] -= result[:to]
      result[:possible] = result[:possible].map(&:downcase).uniq
      result
    end


  end

  def from_me?
      server_message['from_me']
  end

  def generator_operator_actions_group operator_actions_groups
    return nil if self.generator_message_classification.nil?
    @generator_operator_actions_group ||= if operator_actions_groups

      operator_actions_groups.find{|operator_actions_group|
        operator_actions_group.is_action? &&
            operator_actions_group.target_id == self.generator_message_classification.julie_action.id
      }
                                          else
                                            nil
                                          end
  end

  def generator_message_classification
    messages_thread.messages.map(&:message_classifications).flatten.map(&:julie_action).find{|ja|
      ja.present? && ja.server_message_id && ja.server_message_id == self.server_message_id
    }.try(:message_classification)
  end

  def julie_alias
    Message.julie_aliases_from_server_message(self.server_message).first
  end

  def self.julie_aliases_from_server_message server_message, params={}
    (params[:julie_aliases] || JulieAlias.all).select{|julie_alias|
      "#{server_message['from']} #{server_message['to']} #{server_message['cc']}".downcase.include? julie_alias.email.downcase
    }
  end

  def destined_to_julie? params={}
    (params[:julie_aliases] || JulieAlias.all).find{|julie_alias|
      "#{server_message['to']}".downcase.include? julie_alias.email
    }.present?
  end

  def from_a_julie? params={}

    julie_alias = if params[:from_email]
      (params[:julie_aliases] || JulieAlias.all).find{ |julie_alias|
        julie_alias.email == params[:from_email]
      }
    else
      (params[:julie_aliases] || JulieAlias.all).find{|julie_alias|
        "#{server_message['from']}".downcase.include? julie_alias.email
      }
    end

    julie_alias.present?
  end


  def is_discussion_client_julie_only
    result = false

    if server_message.present?
      # If the message is destined to Julie only
      message_tos = server_message['to'].split(',')
      client_aliases = [messages_thread.account_email]
      thread_account = messages_thread.account

      if thread_account.present?
        client_aliases = thread_account.all_emails
      end

      from_address = ApplicationHelper.find_addresses(server_message['from']).addresses.first.address

      result = message_tos.size == 1 && (server_message['cc'].blank? ||  server_message['cc'].split(',').size == 0) && ( client_aliases.include?(from_address) || from_a_julie?(from_email: from_address) )
    end
    result
  end

  def self.import_emails
    Rails.logger.info "Importing emails"

    # Get server threads in inbox, only versions (quick call)
    server_threads = EmailServer.list_messages_threads(filter: "INBOX", limit: 1000, only_version: true)
    inbox_server_thread_ids = server_threads.map{|st| st['id']}
    inbox_messages_threads = MessagesThread.where(server_thread_id: inbox_server_thread_ids)

    #First, remove from inbox all messages_thread that should not be in inbox anymore
    MessagesThread.where(in_inbox: true).where.not(server_thread_id: inbox_server_thread_ids).update_all(in_inbox: false)
    #Then, put in inbox the others, remove should follow up ones as they have received a new message
    messages_threads_previously_not_in_inbox = MessagesThread.where(in_inbox: false, server_thread_id: inbox_server_thread_ids)
    messages_threads_previously_not_in_inbox_ids = messages_threads_previously_not_in_inbox.map(&:id)

    # Reset follow up and follow_up_reminder_date
    messages_threads_previously_not_in_inbox.update_all(in_inbox: true, should_follow_up: false, follow_up_reminder_date: nil)

    server_thread_ids_to_update = []
    server_thread_ids_to_create = []

    server_threads.each do |server_thread|

      messages_thread = inbox_messages_threads.find{|mt| mt.server_thread_id == server_thread['id']}
      if messages_thread
        if "#{messages_thread.server_version}" == "#{server_thread['version']}"
          # Nothing to do
        else
          server_thread_ids_to_update << server_thread['id']
        end
      else
        server_thread_ids_to_create << server_thread['id']
      end
    end

    if (server_thread_ids_to_update + server_thread_ids_to_create).empty?
      return []
    end

    #puts server_thread_ids_to_update + server_thread_ids_to_create
    ids_to_fetch = server_thread_ids_to_update + server_thread_ids_to_create

    server_threads = []
    ids_to_fetch.each_slice(200) do |ids|
      server_threads += EmailServer.list_messages_threads(specific_ids: ids, limit: 1000, full: true)
    end

    #server_threads = EmailServer.list_messages_threads(specific_ids: server_thread_ids_to_update + server_thread_ids_to_create, limit: 1000, full: true)

    # Julie aliases in cache
    julie_aliases = JulieAlias.all
    julie_aliases_emails = julie_aliases.map(&:email)

    users_with_lost_access = Set.new(REDIS_FOR_ACCOUNTS_CACHE.smembers('users_calendar_access_lost'))

    # Accounts in cache (light mode)
    accounts_cache = Account.accounts_cache(mode: "light")

    account_association_data_holder = ThreadAccountAssociation::DataHolder.new(accounts_cache, julie_aliases, julie_aliases_emails)

    # Store the messages_thread_ids that will be updated by this method
    updated_messages_thread_ids = []
    # Store a bit-array associated to every updated messages thread, to allow to decide weither or not we will include them in next socket update
    # The bit-array is composed of the read status of every new message imported in the thread
    messages_thread_candidates_for_notice = {}

    server_threads.each do |server_thread|
      if server_thread['messages'].blank?
        error_message = "No messsages for Messages Thread #{server_thread['id']} (email-server id)"
        Rails.logger.error(error_message)
        Raven.capture_exception(Exceptions::MessagesThread::NoMessageError.new(server_thread['id']))
        next
      else
        # When in staging env, we will check wether a thread is archived by queying the staging table responsible for holding this data
        # because we will not actually archive it on the email server, which is used in production
        if ENV['STAGING_APP']
          if server_thread['messages'].any?{|m| !m['read']}
            StagingHelpers::MessagesThreadsHelper.unarchive_thread(server_thread['id'])
          end

          is_archived = StagingHelpers::MessagesThreadsHelper.is_thread_archived?(server_thread['id'])
          if is_archived
            next
          end
        end
      end

      should_update_thread = true
      new_thread = false
      send_auto_reply_mailing_list_message_id = nil

      if server_thread['subject'].include? "MB5jB- Julie alias test".freeze || server_message['from'].include?('julie.aliastest@gmail.com') || server_message['from'].include?('juliedesk.alias@gmail.com')
        should_update_thread = false
      else
        messages_thread = MessagesThread.find_by_server_thread_id server_thread['id']

        if messages_thread
          Rails.logger.info "For thread #{messages_thread.id} server versions BO: #{messages_thread.server_version}, Email Server: #{server_thread['version']}"
          should_update_thread = ("#{messages_thread.server_version}" != "#{server_thread['version']}" || messages_thread.account_email.nil?)

          messages_thread.track_thread_in_inbox(:main) if messages_threads_previously_not_in_inbox_ids.include?(messages_thread.id)
          messages_thread.update_attributes({in_inbox: true, server_version: server_thread['version']})
        end
      end

      if should_update_thread
        thread_recipients = Set.new

        unless messages_thread
          messages_thread = MessagesThread.create server_thread_id: server_thread['id'], in_inbox: true, server_version: server_thread['version']
          messages_thread.track_thread_in_inbox(:main)
          new_thread = true
        end

        messages_thread.set_server_thread(server_thread)
        messages_thread.set_julie_aliases_in_recipients

        messages_thread.update_attributes({subject: server_thread['subject'], snippet: server_thread['snippet'], messages_count: server_thread['messages'].length})

        server_thread['messages'].each do |server_message|
          # Allow to store memoized data on messages that will be accessible later from messages_thread.messages (like fetched ics data)
          current_messages = messages_thread.messages
          message = current_messages.find{|m| m.server_message_id == server_message['id']}

          message_recipients = Message.generate_reply_all_recipients(server_message, julie_aliases_emails)

          thread_recipients.merge((message_recipients[:from] + message_recipients[:to] + message_recipients[:cc]).map{|recipient| recipient[:email]})

          unless message

            parsed_received_at = DateTime.parse(server_message['date'])
            message_creation_params = {
                server_message_id: server_message['id'],
                received_at: parsed_received_at,
                reply_all_recipients: message_recipients.to_json,
                from_me: server_message['from_me']
            }

            # As we are now ordering messages threads on the homepage with the created_at date, we need to set it to the
            # real received_at date so it is positioned properly on the homepage
            if server_message['was_split']
              message_creation_params[:created_at] = parsed_received_at
            end

            m = messages_thread.messages.create message_creation_params
            m.server_message = server_message

            # Added by Nico to interprete
            # We don't consider that a email sent by Julie means that the thread was updated
            should_call_conscience = false

            unless m.from_me
              should_call_conscience = true

              if server_thread['labels'].include?("MAILING_LIST")
                messages_thread.update(handled_by_automation: true)
                if messages_thread.account
                  unless m.server_message['was_split']
                    send_auto_reply_mailing_list_message_id = m.id
                    #m.async_auto_reply_mailing_list
                  end
                else
                  account_email = MessagesThread.find_account_email(server_thread, {accounts_cache: accounts_cache})
                  if account_email
                    account = Account.create_from_email(account_email, {accounts_cache: accounts_cache})
                    messages_thread.update_attributes({
                                                          account_email: account_email,
                                                          account_name: account.try(:usage_name)
                                                      })

                    unless m.server_message['was_split']
                      send_auto_reply_mailing_list_message_id = m.id
                      #m.async_auto_reply_mailing_list
                    end
                  end
                end
                messages_thread.async_archive
                should_call_conscience = false
              else
                messages_thread.update(handled_by_automation: false)
              end

              messages_thread_candidates_for_notice[messages_thread.id] = messages_thread_candidates_for_notice.fetch(messages_thread.id, []).push(server_message["duplicate"])

              updated_messages_thread_ids << messages_thread.id
            end

            # if server_message['to'].include?('jul.ia@juliedesk.com') || (server_message['cc'].present? && server_message['cc'].include?('jul.ia@juliedesk.com'))
            #   #m.server_message = server_message
            #   unless messages_thread.account
            #     account_email = MessagesThread.find_account_email(server_thread, {accounts_cache: accounts_cache})
            #     if account_email
            #       account = Account.create_from_email(account_email, {accounts_cache: accounts_cache})
            #       messages_thread.update_attributes({
            #                                             account_email: account_email,
            #                                             account_name: account.try(:usage_name)
            #                                         })
            #     end
            #   end
            #   messages_thread.update(handled_by_ai: true)
            #   Message.delegate_to_julia_async(m.id)
            #   should_call_conscience = false
            # end

            if should_call_conscience
              ConscienceWorker.enqueue m.id
            end

            m.compute_allowed_attendees(julie_aliases_emails)
            m.save
          else
            # We already have the message in DB, we will make sure that we computed the allowed attendees for it (for retro compatibility purposes)
            #if message.allowed_attendees.blank?
              # For compute_allowed_attendees
              message.server_message = server_message

              message.compute_allowed_attendees(julie_aliases_emails)
              message.save
            #end
          end
        end

        messages_thread.assign_attributes(last_message_imported_at: messages_thread.compute_last_message_imported_at, request_date: messages_thread.compute_request_date, computed_recipients: thread_recipients.to_a)

        computed_recipients_changed = messages_thread.computed_recipients_changed?

        messages_thread.save

        # Check if there are several julie aliases only if there was a new message
        if updated_messages_thread_ids.include? messages_thread.id && MessagesThread.julie_aliases_from_server_thread(server_thread, {julie_aliases: julie_aliases}).length > 1
          messages_thread.tag_as_multi_clients
        end

        if messages_thread && !messages_thread.handled_by_automation
          thread_account_association_manager = ThreadAccountAssociation::Manager.new(
            data_holder: account_association_data_holder,
            messages_thread: messages_thread,
            server_thread: server_thread
          )
          if messages_thread.account_email == nil
            thread_account_association_manager.compute_association_v2
          else
            if messages_thread.check_if_owner_inactive
              thread_account_association_manager.compute_association_v2
            else
              thread_account_association_manager.compute_accounts_candidates_v2(messages_thread.computed_recipients)
            end
          end

          if messages_thread.several_accounts_detected({accounts_cache: accounts_cache})
            messages_thread.tag_as_multi_clients
          end
        end

        # We send the mailing list automatic email only if the messages thread has no account associated
        if send_auto_reply_mailing_list_message_id.present? && messages_thread.account.blank?
          messages_thread.messages.find{ |m| m.id == send_auto_reply_mailing_list_message_id }.async_auto_reply_mailing_list
        end

        if messages_thread.should_reprocess_linked_attendees(computed_recipients_changed)
          messages_thread.compute_linked_attendees(accounts_cache)
        end

        # -- Manage 'syncing' tag
        if messages_thread.clients_in_recipients.any? { |client_email| Account.not_synced?(client_email) }
          messages_thread.add_tag(MessagesThread::SYNCING_TAG) unless MessagesThread::TRAINING_EMAILS.include? messages_thread.account_email
        end

        ## --
        # Need the accounts candidates to have been computed before doing it
        messages_thread.compute_allowed_attendees
        messages_thread.save

        messages_thread.handle_recipients_lost_access(users_with_lost_access, accounts_cache)

      end
    end

    # Only trigger the new email event for threads that have
    messages_thread_candidates_for_notice.select{|_, bit_array| bit_array.any?{|bit| !bit}}.keys
    #updated_messages_thread_ids.uniq
  end




  def self.generate_reply_all_recipients(server_message, julie_aliases_emails = nil)
    julie_aliases = julie_aliases_emails || JulieAlias.all.map(&:email)
    from_addresses = ApplicationHelper.find_addresses((server_message['from'] || '').downcase).addresses.select{|address| address.address && address.address.include?("@")}
    to_addresses = ApplicationHelper.find_addresses((server_message['to'] || '').downcase).addresses.select{|address| address.address && address.address.include?("@")}

    {
        from: from_addresses.uniq.select{|dest| !julie_aliases.include?(dest.address.try(:downcase))}.map{|dest|
          {
              email: dest.address,
              name: dest.name
          }
        },
        to: (from_addresses + to_addresses).uniq.select{|dest| !julie_aliases.include?(dest.address.try(:downcase))}.map{|dest|
          {
              email: dest.address,
              name: dest.name
          }
        },
        cc: ApplicationHelper.find_addresses((server_message['cc'] || '').downcase).addresses.select{|dest| !julie_aliases.include?(dest.address.try(:downcase))}.map{|dest|
          {
              email: dest.address,
              name: dest.name
          }
        }
    }
  end

  def generate_threads julie_messages
    # Get from field
    message_thread = self.messages_thread

    message_thread.re_import

    #cache_server_message = message_thread.messages.find{|m| m.id == self.id}.server_message
    # Same as the following?
    cache_server_message = message_thread.messages.find{|m| m.id == self.id}.server_message

    julie_alias = message_thread.julie_alias
    julie_alias_from = julie_alias.generate_from

    # Process each one of the messages we want to create
    julie_messages.each do |julie_message_hash|
      event_id = julie_message_hash['event_id']
      event_url = julie_message_hash['event_url']
      calendar_id = julie_message_hash['calendar_id']
      calendar_login_username = julie_message_hash['calendar_login_username']
      attendees = julie_message_hash['attendees']
      summary = julie_message_hash['summary']
      location = julie_message_hash['location']
      duration = julie_message_hash['duration']
      notes = julie_message_hash['notes']
      selectingOccurrence = julie_message_hash['selectingOccurrence']

      # Try to find an existing thread which would have resulted in the given event
      existing_message = JulieAction.where(event_id: event_id, calendar_id: calendar_id).first.try(:message_classification).try(:message)

      # When we specifically select an occurrence, we will not try to find the master event
      if existing_message.blank? && !selectingOccurrence
        found_main_event = PostponeEvents::CalendarServerEventFinder.new(start_date: julie_message_hash['start_date'], summary: julie_message_hash['summary'], organizer_email: julie_message_hash['organizerEmail']).find
        if found_main_event['success']
          event_id = found_main_event['event_id']
          event_url = nil
          calendar_id = found_main_event['calendar_id']
          calendar_login_username = found_main_event['calendar_login_username']
          attendees = found_main_event['attendees']
          summary = found_main_event['summary']
          location = found_main_event['location']
          duration = found_main_event['duration']
          notes = found_main_event['notes']
        end

        existing_message = JulieAction.where(event_id: event_id.to_s, calendar_id: calendar_id.to_s).first.try(:message_classification).try(:message)
      end

      if existing_message.try(:messages_thread)
        copy_response = EmailServer.copy_message_to_existing_thread server_message_id: self.server_message_id, server_thread_id: existing_message.messages_thread.server_thread_id
        EmailServer.deliver_message({
                                        subject: julie_message_hash['subject'],
                                        from: julie_alias_from,
                                        to: julie_alias_from,
                                        text: "#{strip_tags(julie_message_hash['html'])}",
                                        html: "#{julie_message_hash['html']}",
                                        quote_replied_message: true,
                                        reply_to_message_id:  copy_response['id']
                                    })
      else

        # When selecting an occurrence to postpone and we have not already it in DB (it will have a '__' in its id)
        # We will add the occurrence to the calendar server, so we can interact with it independently of the master recurring event
        if selectingOccurrence && event_id.to_s.include?('__')
          created_occurrence_in_db = PostponeEvents::OccurrenceCreator.new(julie_message_hash).create

          if created_occurrence_in_db.present? && created_occurrence_in_db['event_id'].present?
            event_id = created_occurrence_in_db['event_id']
          end
        end

        copy_response = EmailServer.copy_message_to_new_thread server_message_id: self.server_message_id, force_subject: julie_message_hash['subject']

        email_params = {
          subject: julie_message_hash['subject'],
          from: julie_alias_from,
          to: julie_alias_from,
          text: "#{strip_tags(julie_message_hash['html'])}",
          html: "#{julie_message_hash['html']}",
          quote_replied_message: true,
          reply_to_message_id: copy_response['id']
        }

        if ENV['STAGING_APP']
          thread = MessagesThread.create(server_thread_id: copy_response['messages_thread_id'])
          email_params.merge!(message_thread_id: thread.id, server_thread_id: thread.server_thread_id)
        end

        server_message = EmailServer.deliver_message(email_params)

        Message.associate_event_data server_message,
                                                {
                                                    'id' => event_id,
                                                    'calendar_id' => calendar_id,
                                                    'url' => event_url,
                                                    'calendar_login_username' => calendar_login_username,
                                                    'attendees' => attendees,
                                                    'summary' => summary,
                                                    'location' => location,
                                                    'duration' => duration,
                                                    'notes' => notes,
                                                },
                                                message_thread
      end
    end
  end

  def self.associate_event_data server_message, event, original_messages_thread
    # Create the message_thread in DB
    messages_thread = MessagesThread.create server_thread_id: server_message['messages_thread_id'],
                                            in_inbox: true,
                                            account_email: original_messages_thread.account_email,
                                            account_name: original_messages_thread.account_name,
                                            subject: server_message['subject'],
                                            snippet: server_message['snippet']

    # Create the message in DB
    message = messages_thread.messages.create server_message_id: server_message['id'],
                                              received_at: DateTime.parse(server_message['date']),
                                              reply_all_recipients: Message.generate_reply_all_recipients(server_message).to_json,
                                              from_me: server_message['from_me']

    original_thread_account_all_emails = original_messages_thread.account.all_emails

    attendees = event['attendees'] || {}
    attendees = attendees.is_a?(Hash) ? attendees.values : attendees

    attendees = attendees.select{|attendee|
      !original_thread_account_all_emails.include? attendee['email']
    }.map{|attendee|
      {
        email: attendee['email'],
        name: "#{attendee['displayName'] || attendee['name']}"
      }
    }
    # Create the message_classification in DB
    message_classification = message.message_classifications.create_from_params locale: original_messages_thread.computed_data[:locale],
                                                                                classification: MessageClassification::ASK_AVAILABILITIES,
                                                                                operator: original_messages_thread.julie_alias.email,
                                                                                attendees: attendees,
                                                                                processed_in: 0,
                                                                                summary: event['summary'],
                                                                                duration: event['duration'],
                                                                                location: event['location'],
                                                                                notes: event['notes']

    # Create the julie_action in DB to finally store event data
    message_classification.julie_action.update_attributes done: true,
                                                          event_id: event['id'],
                                                          calendar_id: event['calendar_id'],
                                                          event_url: event['url'],
                                                          calendar_login_username: event['calendar_login_username']

    messages_thread.id
  end

  def classification_category_for_classification classification
    messages_thread.classification_category_for_classification(classification)
  end

  def interprete!(options = {})
    force_reinterpretation = options.fetch(:force_reinterpretation, false)

    MessageInterpretation.transaction do
      # Reset interpretations
      self.message_interpretations = [] if force_reinterpretation

      # Process interpretation
      if self.message_interpretations.empty?
        message_interpretations = interprete(options)
        message_interpretations.each(&:save)
      end
    end

    self.message_interpretations
  end

  def interprete(options = {})
    force_reinterpretation = options.fetch(:force_reinterpretation, false)
    full_ai_mode           = options.fetch(:full_ai_mode, false)
    return self.message_interpretations unless message_interpretations.empty? || force_reinterpretation

    message_interpretations_to_process = MessageInterpretation.questions.map do |question|
      self.message_interpretations.build(question: question)
    end

    message_interpretations_to_process.each { |interpretation| interpretation.process(full_ai_mode: full_ai_mode) }
    message_interpretations_to_process
  end


  # Deprecated
  def interpretations
    main_answer = self.message_interpretations.select{|mi| mi.question == MessageInterpretation::QUESTION_MAIN}.first.try(:json_response) || {}
    entities_answer = self.message_interpretations.select{|mi| mi.question == MessageInterpretation::QUESTION_ENTITIES}.first.try(:json_response) || {}

    #entities_details = (entities_answer['annotated'] || "").scan(/<ENTITY(.*?)>(.*?)<\/ENTITY>/)
    entities_details = (entities_answer['annotated'] || "").to_enum(:scan, /<ENTITY(.*?)>(.*?)<\/ENTITY>/).map { Regexp.last_match }
    entities_found = {}
    if entities_details.present?

      entities_details.each do |entity|
        position_in_text = entity.offset(0)
        # First we extract the attributes from the ENTITY tag into a hash
        # <ENTITY type='PHONE' owner='slegrand@kalidea.com'>+33 (0)6 85 31 11 11</ENTITY>
        # => {"type"=>"'PHONE'", "owner"=>"'slegrand@kalidea.com'"}
        attributes = Hash[*(entity[1].strip.split(' ').map{|att| att.split('=')}.flatten)]
        # Here we get the value of the ENTITY (what is contained by the tag)
        # <ENTITY type='PHONE' owner='slegrand@kalidea.com'>+33 (0)6 85 31 11 11</ENTITY>
        # => +33 (0)6 85 31 11 11
        entity_text = entity[2].strip
        # We remove the type of the entity from the attributes and store it for later use, we also remove the single quotes
        # around it for better usage
        type = attributes.delete('type')

        if type.present?

          type = type.downcase.gsub("'", "")
          # Here we get all the attributes hash without the type and we merge the entity_text and value (if possible) in it
          attributes_without_type = attributes.merge('entity_text' => entity_text, 'position-in-text' => "'#{position_in_text.to_json}'")
          attributes_without_type.merge!('value' => "'#{entity_text}'") unless attributes_without_type.keys.include?('value')
          # Now if the hash contain the entity key like 'PHONE'
          # We push the new entity hash details to the array
          # If not we create the array with the first value
          if entities_found.keys.include?(type)
            entities_found[type] << attributes_without_type
          else
            entities_found[type] = [attributes_without_type]
          end
        end
      end
    end

    confidence = begin
      main_answer['request_confidence'] * main_answer['appointment_confidence']
    rescue
      0
    end

    {
        classification: main_answer['request_classif'],
        appointment: main_answer['appointment_classif'],
        locale: main_answer['language_detected'],
        entities: entities_found,
        confidence: confidence
    }
  end


  def get_email_body
    ai_entities = self.message_interpretations.find{|m_i| m_i.question == 'entities' && !m_i.error}
    body = self.server_message['parsed_html']

    if ai_entities.present?
      ai_entities = ai_entities.json_response

      if ai_entities.present? && ai_entities['annotated'].present?
        body = ai_entities['annotated']
      end
    end

    body
  end

  def self.expand_parts parts
    parts.map{|part|
      if part['mimeType'].include? "multipart"
        self.expand_parts part['parts']
        self.expand_parts part['parts']
      else
        part
      end
    }.flatten
  end

  def self.format_email_body message
    # (message.interpretations[:entities] || {}).each do |entity_type, attributes|
    #   attributes.each do |atts|
    #     attributes_without_entity_text = atts.reject{|k, v| k == 'entity_text'}.merge('entity-id' => "'#{entity_type}-#{atts['value'].gsub("'", "")}'").map{|k,v| "#{k}=#{v}"}.join(' ')
    #
    #     body.gsub!(Regexp.new("#{Regexp.quote(atts['entity_text'])}"), "<span class='juliedesk-entity #{entity_type}' #{attributes_without_entity_text}>#{atts['entity_text']}<span class='sprite-wrapper'><span class='sprite'></span></span></span>")
    #   end
    # end

    # Calendar server seems to escape the html tags sometimes
    message.get_email_body
  end

  private

  # Does not escape the html tags, so we can use html formatting in translations (used in some automatics emails)
  def text_to_html_with_tags text
    text.split("\n").map{|line| "<div>#{(line.present?)?h(line.html_safe):"<br>"}</div>"}.join("\n")
  end

  def text_to_html text
    text.split("\n").map{|line| "<div>#{(line.present?)?h(line):"<br>"}</div>"}.join("\n").html_safe
  end


end
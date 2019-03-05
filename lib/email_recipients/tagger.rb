module EmailRecipients
  class Tagger
    attr_accessor :computed_present_attendee_emails, :sanitized_email, :recipient_html, :qualifying_classes

    def initialize(messages_thread, client_emails, julie_emails, email)
      @messages_thread = messages_thread
      @client_emails = client_emails
      @julie_emails = julie_emails
      @email = email
      @sanitized_email = sanitize_email_address(email)
      @qualifying_classes = []

      @computed_present_attendee_emails ||= @messages_thread.computed_data[:attendees].select{|att| att['isPresent'] == true}.map{|att| att['email']}
    end

    def tag
      compute_recipients_html
      tag_as_linked_attendee_if_necessary
      tag_as_trusted_attendee_if_necessary

      "<span class='#{@qualifying_classes.join(' ')}'>#{@recipient_html}</span>"
    end
    
    private

    def compute_recipients_html
      @recipient_html = if @client_emails.include?(@sanitized_email)
        #we gsub the < for its html unicode equivalent to prevent it from beeing interpreted as a balise
        "<span class='highlighted'>#{CGI::escapeHTML(@email)}</span>"
      elsif @computed_present_attendee_emails.include?(@sanitized_email)
        "<span class='attendee-highlighted'>#{CGI::escapeHTML(@email)}</span>"
      elsif @julie_emails.include?(@sanitized_email)
        "<span class='julie-highlighted'>#{CGI::escapeHTML(@email)}</span>"
      else
        CGI::escapeHTML(@email)
      end
    end

    def tag_as_trusted_attendee_if_necessary
      trusted_attendees = @messages_thread.computed_data[:trusted_attendees] || {}

      if trusted_attendees.present?
        in_circle_of_trust_of = []

        trusted_attendees.each do |full_name, circle_of_trust|
          if circle_of_trust && (circle_of_trust['trusted_emails'].include?(@sanitized_email) || email_in_domain?(circle_of_trust['trusted_domains']))
            in_circle_of_trust_of.push(full_name)
          end
        end

        if in_circle_of_trust_of.present?
          @qualifying_classes.push(:trusted_attendee)
          in_circle_of_trust_of_parameterized = in_circle_of_trust_of.map{|client| client.parameterize.underscore}
          @recipient_html += "<span class='trusted-attendee-sprite' data-in-circle-of='#{in_circle_of_trust_of_parameterized}' #{in_circle_of_trust_of_parameterized.map{|a| "#{a}=true"}.join(' ')} title='Cercle de confiance de #{in_circle_of_trust_of.join(', ')}'></span>"
        end
      end
    end

    def tag_as_linked_attendee_if_necessary
      linked_attendees = (@messages_thread.computed_data[:linked_attendees] || {}).values.flatten

      if linked_attendees.include?(@sanitized_email) && !@client_emails.include?(@sanitized_email)
        @qualifying_classes.push(:linked_attendee)
        @recipient_html += "<span class='linked-attendee-sprite' title='Récipiendaire lié'></span>"
      end
    end

    def sanitize_email_address(string)
      tmp = string.dup

      if tmp.include?('<')
        # Removing trailing > with the -2
        tmp = tmp[(tmp.index('<') + 1)..-2]
      end

      tmp.gsub!('>', '')
      tmp.downcase
    end

    def email_in_domain?(domains)
      # domains.include?(@sanitized_email.split('@')[-1])
      ApplicationHelper.email_in_domain?(domains, @sanitized_email)
    end
    

  end
end
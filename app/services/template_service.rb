class TemplateService
  include ApplicationHelper
  include TemplateGeneratorHelper

  def generate_say_hi(recipients_names, params = {})
    locale = params.fetch(:locale, 'fr')
    say_hi = params.fetch(:say_hi, true)
    text = get_say_hi_template({ recipient_names: recipients_names, should_say_hi: say_hi, locale: locale })
    text.present? ? "#{text}\n\n" : nil
  end

  def generate_suggest_dates_for_slash(recipients_names, params = {})
    say_hi_text = self.generate_say_hi(recipients_names, params.slice(:locale))
    generated_text = say_hi_text

    generated_text += get_suggest_date_template({
                                                        client_names:                 params.fetch(:client_names),
                                                        timezones:                    params.fetch(:timezones, []),
                                                        default_timezone:             params.fetch(:default_timezone),
                                                        duration:                     params.fetch(:duration),
                                                        locale:                       params.fetch(:locale, 'fr'),
                                                        is_virtual:                   params.fetch(:is_virtual, false),
                                                        appointment_in_email:         params.fetch(:appointment_in_email),
                                                        location_in_email:            params.fetch(:location_in_email),
                                                        missing_contact_info:         params.fetch(:missing_contact_info, false),
                                                        date:                         params.fetch(:date),
                                                        validate_suggestion_link:     params.fetch(:validate_suggestion_link),
                                                        show_other_suggestions_link:  params.fetch(:show_other_suggestions_link)
                                                    })
  end

  def generate_send_invitations(recipients_names, params = {})
    location = params.fetch(:location, "")
    say_hi_text = self.generate_say_hi(recipients_names, params.slice(:locale))
    generated_text = say_hi_text

    generated_text += get_invitations_sent_template({
      client_names:         params.fetch(:client_names),
      timezones:            params.fetch(:timezones, []),
      locale:               params.fetch(:locale, 'fr'),
      is_virtual:           params.fetch(:is_virtual, false),
      attendees:            params.fetch(:attendees, []),
      appointment_in_email: params.fetch(:appointment_in_email),
      location_in_email:    params.fetch(:location_in_email),
      location:             location,
      location_is_settled:  location.present?,
      should_ask_location:  params.fetch(:should_ask_location, false),
      missing_contact_info: params.fetch(:missing_contact_info, false),
      date:                 params.fetch(:date)
    })
    generated_text
  end

  def generate_reply_message_html(julie_alias, content, params = {})
    locale = params.fetch(:locale)
    footer_and_signature = julie_alias.generate_footer_and_signature(locale)

    text_in_email = content
    text_in_email += footer_and_signature[:text_footer]
    html = text_to_html(text_in_email)
    html + footer_and_signature[:html_signature].html_safe
  end


  # TODO: should be a call to template generator
  def generate_call_instructions(present_attendees, params = {})
    thread_owner  = present_attendees.find(&:is_thread_owner)
    locale        = params.fetch(:locale, 'fr')
    support       = params.fetch(:support, '')
    target        = params.fetch(:target, '')
    target_infos  = params.fetch(:target_infos, '')

    return nil if target == 'later'

    if target == 'interlocutor'
      return nil if target_infos.blank?
      attendee = present_attendees.find { |attendee| attendee.email == target_infos['email'] }

      case support
        when 'mobile'
          I18n.t('call_instructions.single_attendee', { caller_name: thread_owner.name || thread_owner.full_name, target_name: (attendee.name || attendee.name), details: attendee.mobile, locale: locale })
        when 'landline'
          I18n.t(locale 'call_instructions.single_attendee', { caller_name: thread_owner.name, target_name: attendee.name, details: attendee.landline })
        else
          nil
      end

    elsif target == 'client'

      case support
        when 'mobile'
          I18n.t('call_instructions.single_attendee', { caller_name: attendee.name, target_name: thread_owner.name, details: thread_owner.mobile, locale: locale })
        when 'landline'
          I18n.t('call_instructions.single_attendee', { caller_name: attendee.name, target_name: thread_owner.name, details: thread_owner.landline, locale: locale })
        when 'confcall'
          thread_owner.confcall_instructions
        when 'video_conference'
          thread_owner.confcall_instructions
      end

    end
  end

end
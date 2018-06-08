class TemplateService
  include ApplicationHelper
  include TemplateGeneratorHelper

  def generate_say_hi(recipients_names, params = {})
    locale = params.fetch(:locale, 'fr')
    say_hi = params.fetch(:say_hi, true)
    text = get_say_hi_template({ recipient_names: recipients_names, should_say_hi: say_hi, locale: locale })
    text.present? ? "#{text}\n\n" : nil
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

end
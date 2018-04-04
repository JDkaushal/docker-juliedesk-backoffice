module AutomaticProcessing::NotesGenerator

  def generate_notes
    [
        is_virtual_appointment? ? notes_category(get_translation(:call_instructions), generate_call_instructions) : notes_category(get_translation(:address_complement), generate_address_complement),
        notes_category(get_translation(:organizer_infos), generate_organizer_infos),
        notes_category(get_translation(:contacts_infos), generate_contacts_infos)
    ].select(&:present?).join("<br/><br/>")
  end

  def generate_call_instructions
    call_instructions = JSON.parse(self.call_instructions || {})

    if call_instructions['target'] == 'interlocutor'
      if call_instructions['targetInfos'].blank?
        nil
      else
        attendee = get_present_attendee_by_email(call_instructions['targetInfos']['email'])

        case call_instructions['support']
          when 'mobile'
            if attendee.mobile.present?
              [
                  get_translation(:call),
                  attendee.usage_name,
                  get_translation(:on_mobile),
                  attendee.mobile
              ].join(' ')
            else
              nil
            end
          when 'landline'
            if attendee.landline.present?
              [
                  get_translation(:call),
                  attendee.usage_name,
                  get_translation(:on_mobile),
                  attendee.landline
              ].join(' ')
            else
              nil
            end
          when 'confcall'
            nil
          when 'skype'
            nil
          when 'skype_for_business'
            nil
          when 'video_conference'
            nil
          else
            nil
        end
      end


    elsif call_instructions['target'] == 'client'
      case account_appointment['support_config_hash']['label']
        when 'Mobile'
          [
              get_translation(:call),
              account.usage_name,
              get_translation(:on_mobile),
              account.mobile_number
          ].join(' ')
        when 'Landline'
          [
              get_translation(:call),
              account.usage_name,
              get_translation(:on_landline),
              account.landline_number
          ].join(' ')
        when 'Confcall'
          account.confcall_instructions
        when 'Skype'
          nil
        when 'Skype for Business'
          nil
        when 'Vide'
          nil
        when 'Video Conference'
          account.confcall_instructions
        else
          nil
      end


    elsif call_instructions == 'later'
      nil
    else
      nil
    end

  end

  def generate_address_complement
    account_address.try(:[], 'address_complement')
  end

  def generate_organizer_infos
    contact_info(
        full_name: account.full_name,
        mobile_number: account.mobile_number,
        landline_number: account.landline_number,
        skype_id: account.skype,
        confcall_instructions: account.confcall_instructions,

        display_mobile_number: account_appointment['support_config_hash']['mobile_in_note'],
        display_landline_number: account_appointment['support_config_hash']['landline_in_note'],
        display_skype_id: account_appointment['support_config_hash']['skype_in_note'],
        display_confcall_instructions: account_appointment['support_config_hash']['mobile_in_note']
    )
  end

  def generate_contacts_infos
    self.get_present_attendees.reject(&:is_thread_owner).map do |attendee|
      if attendee.has_any_phone_number? || attendee.has_skype?
        contact_info(
            full_name:        attendee.full_name, # TODO check this
            mobile_number:    attendee.mobile,
            landline_number:  attendee.landline,
            skype_id:         attendee.skype_id,

            display_mobile_number: true,
            display_landline_number: true,
            display_skype_id: true
        )
      else
        nil
      end
    end.compact.join("\n\n")
  end

  def contact_info(params)
    [
        params[:full_name],
        (params[:mobile_number].present? && params[:display_mobile_number]) ? "#{get_translation(:mobile)}#{params[:mobile_number]}" : nil,
        (params[:landline_number].present? && params[:display_landline_number]) ? "#{get_translation(:landline)}#{params[:landline_number]}": nil,
        (params[:skype_id].present? && params[:display_skype_id]) ? "#{get_translation(:skype)}#{params[:skype_id]}": nil,
        (params[:confcall_instructions].present? && params[:display_confcall_instructions]) ? "#{get_translation(:confcall_instructions)}#{params[:confcall_instructions]}": nil,
    ].join("<br/>")
  end

  private

  def get_translation(key)
    {
        call: {
            en: 'Call',
            fr: 'Appeler'
        },
        on_mobile: {
            en: 'on mobile:',
            fr: 'sur son téléphone mobile au :'
        },
        on_landline: {
            en: 'on landline:',
            fr: 'sur sa ligne fixe au :'
        },
        address_complement: {
            en: "Address complement",
            fr: "Complément d'adresse"
        },
        call_instructions: {
            en: "Call instructions",
            fr: "Instructions d'appel"
        },
        organizer_infos: {
            en: "Organizer infos",
            fr: "Informations de contact de l'organisateur"
        },
        contacts_infos: {
            en: "Contacts infos",
            fr: "Informations de contact"
        },
        mobile: {
            en: "Mobile: ",
            fr: "Tél. mobile : ",
        },
        landline: {
            en: "Landline: ",
            fr: "Tél. fixe : ",
        },
        skype: {
            en: "Skype ID: ",
            fr: "Identifiant skype : ",
        },
        confcall_instructions: {
            en: "Confcall:\n",
            fr: "Conférence téléphonique :\n",
        }
    }[key][self.locale.to_sym]
  end

  def decorator(label, content)
    content.present? ? "#{label}, #{content}" : nil
  end

  def notes_category(label, content)
    return "" if content.blank?
    <<END
<b>#{label}</b><br/>#{content}
END
  end

end
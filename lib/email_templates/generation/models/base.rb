module EmailTemplates
  module Generation
    module Models

      class Base

        def initialize(params)
          @params = params
          @server_message = @params.delete(:server_message)
          @output_array = []

          if I18n.available_locales.include?(@params['language'].try(:to_sym))
            I18n.locale = @params['language']
          end

        end

        def generate
          check_params_integrity

          if data_consistent?
            set_greetings_sentence
            set_body
          end
          set_footer_and_signature
          format_template_response
        end

        private

        def data_consistent?
          data_ok = false

          if get_thread_owner.blank?
            set_error_response(:no_thread_owner)
          elsif get_language == 'unknown'
            set_language_error
          else
            data_ok = true
          end

          data_ok
        end

        def set_error_response(key)
          add_to_output_array(I18n.translate("email_templates.errors.#{key}"))
        end

        def set_language_error
          message = <<END
Je ne suis pas sûre de comprendre votre langue...
I’m not sure I understand your language…
Io non sono sicuro di aver capito la lingua...
No estoy seguro de entender su idioma...
Ich bin mir nicht sicher, ob ich Ihre Sprache verstehen...
আমি নিশ্চিত আমি তোমার ভাষা বুঝি না...
Saya tidak yakin saya mengerti bahasa Anda...
私はあなたの言語を理解してないんだけど....
END
          add_to_output_array(message)
        end

        def get_required_params
          raise('Not implemented on parent class')
        end

        def get_language
          @params['language']
        end

        def get_non_client_attendees
          @params['participants'] && @params['participants'].reject{|att| att['isClient']}
        end

        def get_attendees_without_thread_owner
          @params['participants'] && @params['participants'].reject{|att| att['isThreadOwner']}
        end

        def get_thread_owner
          @params['participants'] && @params['participants'].find{|att| att['isThreadOwner']}
        end

        def get_suggested_dates
          @params['suggested_dates'].map{|d| d.to_time.in_time_zone(get_timezone)}.sort.group_by{|d| d.to_date}
        end

        def get_suggested_dates_count
          @params['suggested_dates'].size
        end

        def get_attendees_names
          attendees_count = get_attendees_count - 1 # We substract the thread owner
          attendees_count_last_index = attendees_count - 1
          attendees_count_before_last_index = attendees_count - 2

          attendees_str = ''

          get_attendees_without_thread_owner.each_with_index do |attendee, index|
            attendees_str += attendee['first_name']

            if attendees_count > 1 && index < attendees_count_last_index
              if index < attendees_count_before_last_index
                attendees_str += ', '
              else
                attendees_str += " #{I18n.translate('email_templates.common.or')} "
              end
            end
          end

          attendees_str
        end

        def get_clients
          @params['participants'].select{|att| att['isClient']}
        end

        def get_clients_count
          1
        end

        def get_attendees_count
          @params['participants'].size
        end

        def get_appointment_type
          @params['appointment']
        end

        def get_location
          @params['location']
        end

        def get_julie_alias_footer
          @params['julie_alias'].send("footer_#{I18n.locale}")
        end

        def check_params_integrity
          missing_args = []
          get_required_params.each do |param|
            unless @params.keys.include?(param)
              missing_args.push(param)
            end
          end

          unless missing_args.blank?
            raise ArgumentError.new("Missing required argument(s): #{missing_args.join(', ')}")
          end
        end

        def add_to_output_array(str)
          @output_array.push(str)
        end

        def set_greetings_sentence
          #write_to_output(I18n.translate("email_templates.greetings.#{@params.}", client_name: @params.))
          #add_to_output_array(I18n.translate("email_templates.greetings.M", client_name: 'Fred'))
          sender_attendee = get_attendee_who_sent_email

          if sender_attendee.present?
            add_to_output_array(I18n.translate("email_templates.greetings.#{sender_attendee['gender']}", client_name: sender_attendee['firstName']))
          else
            add_to_output_array(I18n.translate("email_templates.common.hello").capitalize)
          end
        end

        def get_attendee_who_sent_email
          @params['participants'] && @params['participants'].find{|att| att['email'] == get_from_email}
        end

        def get_from_email
          from = @server_message['from']

          if from.include?('<')
            from.split('<')[-1].gsub('>', '')
          else
            from
          end
        end

        def set_body
          raise('Not implemented on parent class')
        end

        def set_footer_and_signature
          # TODO Integrate Julie Alias signature

          if @params['julie_alias'].present?
            add_to_output_array(get_julie_alias_footer)
          end
        end

        def format_template_response
          @output_array.join("\n")
        end

      end
    end
  end
end
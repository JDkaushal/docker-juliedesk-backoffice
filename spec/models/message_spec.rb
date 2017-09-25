require "rails_helper"

describe Message do

  before do

  end

  describe "generator_message_classification" do
    before do

    end

    context "a julie_action has its server_message_id registered" do
      before do
        @messages_thread = FactoryGirl.create(:messages_thread_with_messages, messages_count: 3)

        julie_action = @messages_thread.messages[1].message_classifications.first.julie_action
        julie_action.server_message_id = "G12457"
        julie_action.save

        message = @messages_thread.messages[0]
        message.server_message_id = "G12457"
        message.save
      end
      it "should return this julie action's message_classification" do
        expect(@messages_thread.messages[0].generator_message_classification).to eq(@messages_thread.messages[1].message_classifications.first)
      end
    end

    context "a julie_action has its google_message_id registered" do
      before do
        @messages_thread = FactoryGirl.create(:messages_thread_with_messages, messages_count: 3)
      end

      it "should return nil" do
        expect(@messages_thread.messages[0].generator_message_classification).to be nil
      end
    end
  end

  describe "initial_recipients" do
    context "Context 1" do
      before do
        messages_thread = FactoryGirl.create(:messages_thread)
        @message = FactoryGirl.create(
            :message,
            reply_all_recipients: {to: [{email: "elrandil1@gmail.com"}, {email: "nmarlier@gmail.com"}], cc: [{email: "elrandil2@gmail.com"}, {email: "nicolas.marlier@wanadoo.fr"}]}.to_json,
            messages_thread: messages_thread
        )
        expect(messages_thread).to receive(:contacts).with(with_client: true).and_return([])
        expect(messages_thread).to receive(:computed_data).and_return({
                                                                          attendees: [
                                                                              {'email' => "elrandil1@gmail.com", 'isPresent' => 'true'},
                                                                              {'email' => "notThere@gmail.com", 'isPresent' => 'false'},
                                                                              {'email' => "boss@company.com", "assisted" => "true", 'assistant' => 'false', 'isPresent' => 'true'},
                                                                              {'email' => "sec@company.com", "assisted" => "false", 'assistant' => 'true', 'isPresent' => 'true'}
                                                                          ]
                                                                      })
        expect(messages_thread).to receive_message_chain(:account, :all_emails).and_return(["nmarlier@gmail.com", "nicolas.marlier@wanadoo.fr"])
        allow(messages_thread).to receive(:client_email).and_return("nmarlier@gmail.com")

        expect(messages_thread).to receive(:julie_aliases).and_return([FactoryGirl.create(:julie_alias, email: "julie@juliedesk.com")])
      end
      it "should return a hash with initial recipients" do
        expect(@message.initial_recipients).to eq({
                                                      to: ["elrandil1@gmail.com", "sec@company.com"].sort,
                                                      cc: ["nmarlier@gmail.com", "elrandil2@gmail.com"].sort,
                                                      client: "nmarlier@gmail.com",
                                                      possible: ["elrandil1@gmail.com", "elrandil2@gmail.com", "julie@juliedesk.com", "nmarlier@gmail.com", "nicolas.marlier@wanadoo.fr", "boss@company.com", "sec@company.com"].sort

                                                  })
      end

      it "should return a hash with initial recipients" do
        expect(@message.initial_recipients(only_reply_all: true)).to eq({
                                                                            to: ["elrandil1@gmail.com", "nmarlier@gmail.com"].sort,
                                                                            cc: ["elrandil2@gmail.com", "nicolas.marlier@wanadoo.fr"].sort,
                                                                            client: "nmarlier@gmail.com",
                                                                            possible: ["elrandil1@gmail.com", "elrandil2@gmail.com", "julie@juliedesk.com", "nmarlier@gmail.com", "nicolas.marlier@wanadoo.fr", "boss@company.com", "sec@company.com"].sort

                                                                        })
      end
    end

    context "Context 2" do
      before do
        messages_thread = FactoryGirl.create(:messages_thread)
        @message = FactoryGirl.create(
            :message,
            reply_all_recipients: {to: [{email: "elrandil1@gmail.com"}, {email: "nmarlier@gmail.com"}], cc: [{email: "elrandil2@gmail.com"}, {email: "nicolas.marlier@wanadoo.fr"}]}.to_json,
            messages_thread: messages_thread
        )
        expect(messages_thread).to receive(:contacts).with(with_client: true).and_return([])
        expect(messages_thread).to receive(:computed_data).and_return({
                                                                          attendees: []
                                                                      })
        expect(messages_thread).to receive_message_chain(:account, :all_emails).and_return(["nmarlier@gmail.com", "nicolas.marlier@wanadoo.fr"])
        allow(messages_thread).to receive(:client_email).and_return("nmarlier@gmail.com")

        expect(messages_thread).to receive(:julie_aliases).and_return([FactoryGirl.create(:julie_alias, email: "julie@juliedesk.com")])
      end
      it "should return a hash with initial recipients" do
        expect(@message.initial_recipients).to eq({
                                                      to: ["nmarlier@gmail.com"].sort,
                                                      cc: ["elrandil1@gmail.com", "elrandil2@gmail.com"].sort,
                                                      client: "nmarlier@gmail.com",
                                                      possible: ["elrandil1@gmail.com", "elrandil2@gmail.com", "julie@juliedesk.com", "nmarlier@gmail.com", "nicolas.marlier@wanadoo.fr"].sort

                                                  })
      end

      it "should return a hash with initial recipients" do
        expect(@message.initial_recipients(only_reply_all: true)).to eq({
                                                                            to: ["elrandil1@gmail.com", "nmarlier@gmail.com"].sort,
                                                                            cc: ["elrandil2@gmail.com", "nicolas.marlier@wanadoo.fr"].sort,
                                                                            client: "nmarlier@gmail.com",
                                                                            possible: ["elrandil1@gmail.com", "elrandil2@gmail.com", "julie@juliedesk.com", "nmarlier@gmail.com", "nicolas.marlier@wanadoo.fr"].sort

                                                                        })
      end
    end

    context "Context 3" do
      before do
        messages_thread = FactoryGirl.create(:messages_thread)
        @message = FactoryGirl.create(
            :message,
            reply_all_recipients: {to: [{email: "nmarlier@gmail.com"}], cc: []}.to_json,
            messages_thread: messages_thread
        )
        expect(messages_thread).to receive(:contacts).with(with_client: true).and_return([])
        expect(messages_thread).to receive(:computed_data).and_return({
                                                                          attendees: [{'email' => "elrandil1@gmail.com", 'isPresent' => 'true'}, {'email' => "elrandil2@gmail.com", 'isPresent' => 'true'}, {'email' => "notThere@gmail.com", 'isPresent' => 'false'}]
                                                                      })
        expect(messages_thread).to receive_message_chain(:account, :all_emails).and_return(["nmarlier@gmail.com", "nicolas.marlier@wanadoo.fr"])
        allow(messages_thread).to receive(:client_email).and_return("nmarlier@gmail.com")

        expect(messages_thread).to receive(:julie_aliases).and_return([FactoryGirl.create(:julie_alias, email: "julie@juliedesk.com")])
      end
      it "should return a hash with initial recipients" do
        expect(@message.initial_recipients).to eq({
                                                      to: ["elrandil1@gmail.com", "elrandil2@gmail.com"].sort,
                                                      cc: ["nmarlier@gmail.com"].sort,
                                                      client: "nmarlier@gmail.com",
                                                      possible: ["elrandil1@gmail.com", "elrandil2@gmail.com", "julie@juliedesk.com", "nmarlier@gmail.com"].sort

                                                  })
      end

      it "should return a hash with initial recipients" do
        expect(@message.initial_recipients(only_reply_all: true)).to eq({
                                                      to: ["nmarlier@gmail.com"].sort,
                                                      cc: [].sort,
                                                      client: "nmarlier@gmail.com",
                                                      possible: ["elrandil1@gmail.com", "elrandil2@gmail.com", "julie@juliedesk.com", "nmarlier@gmail.com"].sort

                                                  })
      end

    end

    context "Context 4" do
      before do
        messages_thread = FactoryGirl.create(:messages_thread)
        @message = FactoryGirl.create(
            :message,
            reply_all_recipients: {to: [{email: "nmarlier@gmail.com"}, {email: "elrandil1@gmail.com"}], cc: []}.to_json,
            messages_thread: messages_thread
        )
        expect(messages_thread).to receive(:contacts).with(with_client: true).and_return([])
        expect(messages_thread).to receive(:computed_data).and_return({
                                                                          attendees: [{'email' => "Elrandil1@gmail.com", 'isPresent' => 'true'}, {'email' => "elrandil2@gmail.com", 'isPresent' => 'true'}, {'email' => "notThere@gmail.com", 'isPresent' => 'false'}]
                                                                      })
        expect(messages_thread).to receive_message_chain(:account, :all_emails).and_return(["nmarlier@gmail.com", "nicolas.marlier@wanadoo.fr"])
        allow(messages_thread).to receive(:client_email).and_return("nmarlier@gmail.com")

        expect(messages_thread).to receive(:julie_aliases).and_return([FactoryGirl.create(:julie_alias, email: "julie@juliedesk.com")])
      end
      it "should return a hash with initial recipients" do
        expect(@message.initial_recipients).to eq({
                                                      to: ["elrandil1@gmail.com", "elrandil2@gmail.com"].sort,
                                                      cc: ["nmarlier@gmail.com"].sort,
                                                      client: "nmarlier@gmail.com",
                                                      possible: ["elrandil1@gmail.com", "elrandil2@gmail.com", "julie@juliedesk.com", "nmarlier@gmail.com"].sort

                                                  })
      end

    end

    context "No client email in dest" do
      before do
        messages_thread = FactoryGirl.create(:messages_thread)
        @message = FactoryGirl.create(
            :message,
            reply_all_recipients: {to: [{email: "elrandil1@gmail.com"}], cc: [{email: "elrandil2@gmail.com"}]}.to_json,
            messages_thread: messages_thread
        )
        expect(messages_thread).to receive(:contacts).with(with_client: true).and_return([])
        expect(messages_thread).to receive(:computed_data).and_return({
                                                                          attendees: [{'email' => "elrandil1@gmail.com", 'isPresent' => 'true'}, {'email' => "elrandil2@gmail.com", 'isPresent' => 'true'}, {'email' => "notThere@gmail.com", 'isPresent' => 'false'}]
                                                                      })
        expect(messages_thread).to receive_message_chain(:account, :all_emails).and_return(["nmarlier@gmail.com", "nicolas.marlier@wanadoo.fr"])
        allow(messages_thread).to receive(:client_email).and_return("nmarlier@gmail.com")

        expect(messages_thread).to receive(:julie_aliases).and_return([FactoryGirl.create(:julie_alias, email: "julie@juliedesk.com")])
      end
      it "should return a hash with initial recipients" do
        expect(@message.initial_recipients).to eq({
                                                      to: ["elrandil1@gmail.com", "elrandil2@gmail.com"].sort,
                                                      cc: ["nmarlier@gmail.com"].sort,
                                                      client: "nmarlier@gmail.com",
                                                      possible: ["elrandil1@gmail.com", "elrandil2@gmail.com", "julie@juliedesk.com", "nmarlier@gmail.com"].sort

                                                  })
      end

      it "should return a hash with initial recipients" do
        expect(@message.initial_recipients(only_reply_all: true)).to eq({
                                                                            to: ["elrandil1@gmail.com"].sort,
                                                                            cc: ["elrandil2@gmail.com", "nmarlier@gmail.com"].sort,
                                                                            client: "nmarlier@gmail.com",
                                                                            possible: ["elrandil1@gmail.com", "elrandil2@gmail.com", "julie@juliedesk.com", "nmarlier@gmail.com"].sort

                                                                        })
      end
    end

    context "Only client" do
      before do
        messages_thread = FactoryGirl.create(:messages_thread)
        @message = FactoryGirl.create(
            :message,
            reply_all_recipients: {to: [{email: "nmarlier@gmail.com"}], cc: []}.to_json,
            messages_thread: messages_thread
        )
        expect(messages_thread).to receive(:contacts).with(with_client: true).and_return([])
        expect(messages_thread).to receive(:computed_data).and_return({
                                                                          attendees: []
                                                                      })
        expect(messages_thread).to receive_message_chain(:account, :all_emails).and_return(["nmarlier@gmail.com", "nicolas.marlier@wanadoo.fr"])
        allow(messages_thread).to receive(:client_email).and_return("nmarlier@gmail.com")

        expect(messages_thread).to receive(:julie_aliases).and_return([FactoryGirl.create(:julie_alias, email: "julie@juliedesk.com")])
      end
      it "should return a hash with initial recipients" do
        expect(@message.initial_recipients).to eq({
                                                      to: ["nmarlier@gmail.com"].sort,
                                                      cc: [].sort,
                                                      client: "nmarlier@gmail.com",
                                                      possible: ["julie@juliedesk.com", "nmarlier@gmail.com"].sort

                                                  })
      end

      it "should return a hash with initial recipients" do
        expect(@message.initial_recipients(only_reply_all: true)).to eq({
                                                                            to: ["nmarlier@gmail.com"].sort,
                                                                            cc: [].sort,
                                                                            client: "nmarlier@gmail.com",
                                                                            possible: ["julie@juliedesk.com", "nmarlier@gmail.com"].sort

                                                                        })
      end
    end

  end

  # Deprecated

  # describe 'interpretations' do
  #   before do
  #     messages_thread = FactoryGirl.create(:messages_thread)
  #
  #     @message = FactoryGirl.create(
  #         :message,
  #         messages_thread: messages_thread
  #     )
  #
  #     @message.message_interpretations.create(question: MessageInterpretation::QUESTION_MAIN, raw_response: "{\"body\": \"Merci !\\n\", \"email_id\": 278000, \"request_classif\": \"classif\", \"request_threshold\": 0.46, \"appointment_classif\": \"appointment\", \"dates_to_check\": {}, \"language_detected\": \"fr\", \"request_proba\": null, \"appointment_threshold\": 0.78, \"algo_duration\": [6, 3, 0, 3], \"appointment_proba\": 0.94}")
  #     @message.message_interpretations.create(question: MessageInterpretation::QUESTION_ENTITIES, raw_response: "{\"annotated\": \"gegergergerg gregergreg gregreg <ENTITY type='TIME' value='2016-04-06T09:00'>Mercredi 6 avril 2016 à 9h00 </ENTITY>(Fuseau horaire : Europe/<ENTITY type='LOCATION'>Paris</ENTITY> frefer freferferfe frefer <ENTITY type='PHONE' owner='slegrand@kalidea.com'>+33 (0)6 85 31 11 11</ENTITY>\\r\\n rfferfe  <ENTITY type='PHONE' owner='None'>06 26 94 24 08</ENTITY>\"}")
  #   end
  #
  #   it 'should return the correct hash' do
  #     expect(@message.interpretations).to eq({:classification=>"classif", :appointment=>"appointment", :locale=>"fr", :entities=>{"time"=>[{"value"=>"'2016-04-06T09:00'", "entity_text"=>"Mercredi 6 avril 2016 à 9h00", "position-in-text"=>"'[32,115]'"}], "location"=>[{"entity_text"=>"Paris", "position-in-text"=>"'[140,178]'", "value"=>"'Paris'"}], "phone"=>[{"owner"=>"'slegrand@kalidea.com'", "entity_text"=>"+33 (0)6 85 31 11 11", "position-in-text"=>"'[205,284]'", "value"=>"'+33 (0)6 85 31 11 11'"}, {"owner"=>"'None'", "entity_text"=>"06 26 94 24 08", "position-in-text"=>"'[296,353]'", "value"=>"'06 26 94 24 08'"}]}})
  #   end
  # end

  describe 'format_email_body' do
    before do
      messages_thread = FactoryGirl.create(:messages_thread)

      @message = FactoryGirl.create(
          :message,
          messages_thread: messages_thread
      )

      @message.message_interpretations.create(question: MessageInterpretation::QUESTION_MAIN, raw_response: "{\"body\": \"Merci !\\n\", \"email_id\": 278000, \"request_classif\": \"classif\", \"request_threshold\": 0.46, \"appointment_classif\": \"appointment\", \"dates_to_check\": {}, \"language_detected\": \"fr\", \"request_proba\": null, \"appointment_threshold\": 0.78, \"algo_duration\": [6, 3, 0, 3], \"appointment_proba\": 0.94}")
      @message.message_interpretations.create(question: MessageInterpretation::QUESTION_ENTITIES, raw_response: "{\"annotated\": \"annotated body\"}")
    end

    it 'should replace the message body with the annotated body returned by the AI' do
      body = "gegergergerg gregergreg gregreg Mercredi 6 avril 2016 à 9h00 (Fuseau horaire : Europe/Paris frefer freferferfe frefer +33 (0)6 85 31 11 11 \r\n rfferfe  06 26 94 24 08"

      expect(@message).to receive(:server_message).and_return({'parsed_html' => body})
      expect(Message.format_email_body(@message)).to eq("annotated body")
    end

  end

  describe 'send_auto_email' do
    let(:julie_alias) { FactoryGirl.create(:julie_alias_random, name: "Julie Alias", email: 'juliealias@gmail.com', signature_en: 'signature EN', footer_en: 'footer EN', signature_fr: 'signature FR', footer_fr: 'footer FR') }
    let!(:default_julie_alias) { FactoryGirl.create(:julie_alias_random, name: "Default Julie", email: 'julie@juliedesk.com', signature_en: 'signature EN', footer_en: 'footer EN', signature_fr: 'signature FR', footer_fr: 'footer FR') }
    let(:messages_thread) { FactoryGirl.create(:messages_thread) }
    let(:message) {
      FactoryGirl.create(
        :message,
        reply_all_recipients: {from: [{email: "nmarlier@gmail.com"}], cc: []}.to_json,
        messages_thread: messages_thread
      )
    }

    before(:example) do
      expect(message).to receive(:interprete)
      message.message_interpretations.create(question: MessageInterpretation::QUESTION_MAIN, raw_response: "{\"body\": \"Merci !\\n\", \"email_id\": 278000, \"request_classif\": \"classif\", \"request_threshold\": 0.46, \"appointment_classif\": \"appointment\", \"dates_to_check\": {}, \"language_detected\": \"fr\", \"request_proba\": null, \"appointment_threshold\": 0.78, \"algo_duration\": [6, 3, 0, 3], \"appointment_proba\": 0.94}")
      expect(messages_thread).to receive(:julie_alias).and_return(julie_alias)
    end

    context 'The used julie alias is able to send emails' do

      before(:example) do
        expect(REDIS_FOR_ACCOUNTS_CACHE).to receive(:get).with('working_julie_aliases_cache').and_return([julie_alias.email].to_json)
      end

      it 'should trigger the correct actions' do

        expect(EmailServer).to receive(:deliver_message).with(
            {
                :subject=>"Re: ",
                :from=>"Julie Alias <juliealias@gmail.com>",
                :to=>"nmarlier@gmail.com",
                :cc=>"",
                :bcc=>"hello@juliedesk.com",
                :text=>"translation missing: fr.automatic_reply_emails.auto_email_typefooter FRsignature FR",
                :html=>"<div>translation missing: fr.automatic_reply_emails.auto_email_typefooter FR</div>signature FR",
                :quote_replied_message=>true,
                :reply_to_message_id=>nil,
                :is_auto_email=>true
            }
        ).and_return({'id' => 1})
        message.send_auto_email(:auto_email_type, {translation_param: "translation param value"})

        message.reload
        expect(message.auto_email_kind).to eq('auto_email_type')

      end
    end


    context 'The used julie alias is not able to send emails' do

      before(:example) do
        expect(REDIS_FOR_ACCOUNTS_CACHE).to receive(:get).with('working_julie_aliases_cache').and_return([].to_json)
      end

      it 'should trigger the correct actions' do
        expect(EmailServer).to receive(:deliver_message).with(
            {
                :subject=>"Re: ",
                :from=>"Default Julie <julie@juliedesk.com>",
                :to=>"nmarlier@gmail.com",
                :cc=>"",
                :bcc=>"hello@juliedesk.com",
                :text=>"translation missing: fr.automatic_reply_emails.auto_email_typefooter FRsignature FR",
                :html=>"<div>translation missing: fr.automatic_reply_emails.auto_email_typefooter FR</div>signature FR",
                :quote_replied_message=>true,
                :reply_to_message_id=>nil,
                :is_auto_email=>true
            }
        ).and_return({'id' => 1})
        message.send_auto_email(:auto_email_type, {translation_param: "translation param value"})

        message.reload
        expect(message.auto_email_kind).to eq('auto_email_type')
      end
    end

  end
end
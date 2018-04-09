class Attendee
  include ActiveModel::Model
  include ActiveModel::AttributeMethods

  GENDER_MALE   = 'M'
  GENDER_FEMALE = 'F'
  GENDERS = [GENDER_MALE, GENDER_FEMALE]

  STATUS_PRESENT      = 'present'
  STATUS_OPTIONAL     = 'optional'
  STATUS_NOT_PRESENT  = 'not_present'

  STATUSES = [STATUS_PRESENT, STATUS_OPTIONAL, STATUS_NOT_PRESENT]

  attr_accessor :account_email, :email, :first_name, :last_name, :usage_name, :gender, :landline, :mobile, :skype_id,
                :company, :is_present, :status, :is_client, :assisted, :is_assistant, :is_thread_owner, :timezone


  validates :gender, inclusion: { in: GENDERS }, presence: false
  validates :status, inclusion: { in: STATUSES }, presence: false

  def attributes
    {
        account_email:    @account_email,
        #accountEmail:     @accountEmail,
        email:            @email,
        first_name:       @first_name,
        last_name:        @last_name,
        usage_name:       @usage_name,
        gender:           @gender,
        landline:         @landline,
        timezone:         @timezone,
        mobile:           @mobile,
        skype_id:         @skype_id,
        company:          @company,
        is_present:       @is_present,
        status:           @status,
        is_client:        @is_client,
        assisted:         @assisted,
        is_assistant:     @is_assistant,
        is_thread_owner:  @is_thread_owner
    }
  end

  def assign_attributes(attrs)
    attrs.each do |k, v|
      send("#{k}=", v)
    end
  end

  # Ovverride
  def email=(email)
    @email = email.downcase
    @email
  end

  def full_name
    [self.first_name, self.last_name].select(&:present?).join(' ')
  end


  def has_any_phone_number?
    self.landline.present? || self.mobile.present?
  end

  def has_skype?
    self.skype_id.present?
  end

  def any_phone_number
    self.landline || self.mobile
  end

  def present?
    self.status == STATUS_PRESENT || self.is_present
  end


  def to_h
    {
        'account_email' => self.account_email,
        'accountEmail'  => self.account_email,
        'email'         => self.email,
        'fullName'      => self.full_name,
        'firstName'     => self.first_name,
        'lastName'      => self.last_name,
        'usageName'     => self.usage_name,
        'gender'        => self.gender,
        'timezone'      => self.timezone,
        'company'       => self.company,
        'landline'      => self.landline,
        'mobile'        => self.mobile,
        'skypeId'       => self.skype_id,
        'isPresent'     => self.is_present,
        'status'        => self.status,
        'isClient'      => self.is_client,
        'assisted'      => self.assisted,
        'isAssistant'   => self.is_assistant,
        'isThreadOwner' => self.is_thread_owner
    }
  end


  def merge_with!(attendee, options = {})
    overwrite = options.fetch(:overwrite, false)
    if overwrite
      self.assign_attributes(attendee.attributes.compact)
    else
      assignable_attrs = self.attributes.select { |_, value| value.nil?  }.keys
      self.assign_attributes(attendee.attributes.slice(*assignable_attrs))
    end

    self
  end


  def self.merge!(l_attendees, r_attendees, options = {})
    r_attendees.each do |r_attendee|
      l_attendee = l_attendees.find { |attendee| attendee.email == r_attendee.email }
      if l_attendee
        l_attendee.merge_with!(r_attendee, options)
      else
        l_attendees << r_attendee
      end
    end

    l_attendees
  end



  def self.from_json(json_data)
    data = JSON.parse(json_data)
    data_array = data.is_a?(Array) ? data : [data]

    boolean_fields = ['isPresent', 'isClient', 'assisted', 'isAssistant', 'isThreadOwner']
    attendee_list = data_array.map do |attendee_data|
      attendee_data = attendee_data.with_indifferent_access

      puts attendee_data.inspect
      # Normalize boolean fields ("true" => true)
      boolean_fields.each do |boolean_field_name|
        if attendee_data[boolean_field_name].is_a?(String)
          attendee_data[boolean_field_name] = attendee_data[boolean_field_name] == 'true' ? true : false
        end
      end

      Attendee.new(
          account_email:    attendee_data['account_email'],
          #accountEmail:     attendee_data['accountEmail'] || attendee_data['account_email'],
          email:            attendee_data['email'],
          first_name:       attendee_data['firstName'],
          last_name:        attendee_data['lastName'],
          usage_name:       attendee_data['usageName'],
          gender:           attendee_data['gender'],
          timezone:         attendee_data['timezone'],
          company:          attendee_data['company'],
          landline:         attendee_data['landline'],
          mobile:           attendee_data['mobile'],
          skype_id:         attendee_data['skypeId'],
          is_present:       attendee_data['isPresent'],
          status:           attendee_data['status'],
          is_client:        attendee_data['isClient'],
          assisted:         attendee_data['assisted'],
          is_assistant:     attendee_data['isAssistant'],
          is_thread_owner:  attendee_data['isThreadOwner']
      )
    end

    data.is_a?(Array) ? attendee_list : attendee_list.first
  end

end
class Api::V1::JulieAliasesController < Api::ApiV1Controller

  def synchronize
    julie_aliases = params[:julie_aliases]
    julie_aliases = JSON.parse(julie_aliases) if julie_aliases.class == String

    all_emails = julie_aliases.map{|julie_alias_hash| julie_alias_hash['email']}
    db_julie_aliases = JulieAlias.where(email: all_emails)
    julie_aliases.each do |julie_alias_hash|
      julie_alias = db_julie_aliases.select{|julie_alias| julie_alias.email == julie_alias_hash['email']}.first
      if julie_alias
        julie_alias.assign_attributes({
            name:         [julie_alias_hash['first_name'], julie_alias_hash['last_name']].select(&:present?).join(" "),
            footer_en:    julie_alias_hash['footer_en'],
            footer_fr:    julie_alias_hash['footer_fr'],
            signature_en: julie_alias_hash['signature_en'],
            signature_fr: julie_alias_hash['signature_fr'],
                                      })
        if julie_alias.changed?
          julie_alias.save
        end
      else
        JulieAlias.create({
                                          email: julie_alias_hash['email'],
                                          name:         [julie_alias_hash['first_name'], julie_alias_hash['last_name']].select(&:present?).join(" "),
                                          footer_en:    julie_alias_hash['footer_en'],
                                          footer_fr:    julie_alias_hash['footer_fr'],
                                          signature_en: julie_alias_hash['signature_en'],
                                          signature_fr: julie_alias_hash['signature_fr'],
                                      })
      end
    end

    JulieAlias.where.not(email: all_emails).delete_all

    render json: {
        status: "success",
        data: {}
    }
  end
end
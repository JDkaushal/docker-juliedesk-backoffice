class JulieAlias < ActiveRecord::Base

  class JulieAliasNotFoundError < StandardError
  end

  def generate_from
    "#{self.name} <#{self.email}>"
  end

  def can_send?
    can_send_julie_alias = JSON.parse(REDIS_FOR_ACCOUNTS_CACHE.get('working_julie_aliases_cache'))
    can_send_julie_alias.include?(self.email)
  end

  def generate_footer_and_signature locale
    puts self.id
    html_signature = self.signature_en.gsub(/%REMOVE_IF_PRO%/, "")
    text_signature = self.footer_en.gsub(/%REMOVE_IF_PRO%/, "")

    if "#{locale}" == "fr"
      html_signature = self.signature_fr.gsub(/%REMOVE_IF_PRO%/, "")
      text_signature = self.footer_fr.gsub(/%REMOVE_IF_PRO%/, "")
    end

    {
         text_footer: text_signature,
         html_signature: html_signature
    }
  end

  def is_malfunctionning?
    cache = REDIS_FOR_ACCOUNTS_CACHE.smembers('malfunctionning_julie_aliases')
    cache.include?(self.email)
  end
end
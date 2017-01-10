class JulieAlias < ActiveRecord::Base

  def generate_from
    "#{self.name} <#{self.email}>"
  end

  def generate_footer_and_signature locale
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
end
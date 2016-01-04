class JulieAliasesController < ApplicationController

  def index
    @julie_aliases = JulieAlias.all
  end

  def edit
    @julie_alias = JulieAlias.find(params[:id])
  end

  def new
    @julie_alias = JulieAlias.new({
        name: "Julie Desk",
        footer_en: "\n\nBest regards,\n\nJulie\nArtificial Intelligence @",
        footer_fr: "\n\nCordialement,\n\nJulie\nIntelligence Artificielle @",
    })
  end

  def update
    @julie_alias = JulieAlias.find params[:id]
    @julie_alias.update_attributes(julie_alias_params)
    redirect_to action: :edit
  end

  def create
    JulieAlias.create(julie_alias_params)
    redirect_to action: :index
  end

  private
  def julie_alias_params
    params.require(:julie_alias).permit(:name, :email, :footer_en, :footer_fr, :signature_en, :signature_fr)
  end

end
class MakeAnOfferController < ApplicationController

  before_action :set_property

  def index
    #@offer = @property.offers
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end


end

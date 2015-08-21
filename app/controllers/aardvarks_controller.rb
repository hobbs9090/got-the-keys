class AardvarksController < ApplicationController
  before_action :set_aardvark, only: [:show, :edit, :update, :destroy]

  # GET /aardvarks
  # GET /aardvarks.json
  def index
    @aardvarks = Aardvark.all
  end

  # GET /aardvarks/1
  # GET /aardvarks/1.json
  def show
  end

  # GET /aardvarks/new
  def new
    @aardvark = Aardvark.new
  end

  # GET /aardvarks/1/edit
  def edit
  end

  # POST /aardvarks
  # POST /aardvarks.json
  def create
    @aardvark = Aardvark.new(aardvark_params)

    respond_to do |format|
      if @aardvark.save
        format.html { redirect_to @aardvark, notice: 'Aardvark was successfully created.' }
        format.json { render action: 'show', status: :created, location: @aardvark }
      else
        format.html { render action: 'new' }
        format.json { render json: @aardvark.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /aardvarks/1
  # PATCH/PUT /aardvarks/1.json
  def update
    respond_to do |format|
      if @aardvark.update(aardvark_params)
        format.html { redirect_to @aardvark, notice: 'Aardvark was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @aardvark.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /aardvarks/1
  # DELETE /aardvarks/1.json
  def destroy
    @aardvark.destroy
    respond_to do |format|
      format.html { redirect_to aardvarks_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_aardvark
      @aardvark = Aardvark.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def aardvark_params
      params[:aardvark]
    end
end

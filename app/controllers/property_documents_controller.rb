class PropertyDocumentsController < ApplicationController
  include PropertyScoped

  before_action :set_property
  before_action :authenticate_user!, except: :download
  before_action :authorize_property_owner!, except: :download
  before_action :set_property_document, only: %i[update destroy download]

  def index
    @property_documents = @property.ordered_documents
    @new_property_document = @property.property_documents.new(position: next_position)
  end

  def new
    redirect_to property_property_documents_path(@property)
  end

  def create
    @property_documents = @property.ordered_documents
    @new_property_document = @property.property_documents.new(property_document_params)

    if @new_property_document.save
      AuditLogger.log!(
        auditable: @new_property_document,
        property: @property,
        actor_label: current_user.email,
        action: "property_document_created",
        message: t("ui.property_documents.audit.added", category: @new_property_document.category_label, title: @new_property_document.title)
      )
      redirect_to property_property_documents_path(@property), notice: t("ui.property_documents.flash.added")
    else
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @property_documents = @property.ordered_documents
    @new_property_document = @property.property_documents.new(position: next_position)
    @edited_property_document = @property_document

    if @property_document.update(property_document_params)
      AuditLogger.log!(
        auditable: @property_document,
        property: @property,
        actor_label: current_user.email,
        action: "property_document_updated",
        message: t("ui.property_documents.audit.updated", title: @property_document.title)
      )
      redirect_to property_property_documents_path(@property), notice: t("ui.property_documents.flash.updated")
    else
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    title = @property_document.title
    @property_document.destroy
    AuditLogger.log!(
      auditable: @property,
      property: @property,
      actor_label: current_user.email,
      action: "property_document_removed",
      message: t("ui.property_documents.audit.removed", title:)
    )
    redirect_to property_property_documents_path(@property), notice: t("ui.property_documents.flash.removed")
  end

  def download
    unless @property_document.publicly_visible? || current_user == @property.user || current_admin.present?
      redirect_to property_path(@property), alert: t("ui.property_documents.alerts.not_public")
      return
    end

    AuditLogger.log!(
      auditable: @property_document,
      property: @property,
      admin: current_admin,
      actor_label: current_user&.email.presence || t("ui.property_documents.public_visitor"),
      action: "property_document_downloaded",
      message: t("ui.property_documents.audit.downloaded", title: @property_document.title)
    )

    send_data(
      PropertyDocumentPayloadBuilder.new(document: @property_document, property: @property).payload,
      filename: @property_document.file_name,
      disposition: "attachment",
      type: mime_type_for(@property_document.file_name)
    )
  end

  private

  def set_property_document
    @property_document = @property.property_documents.find(params[:id])
  end

  def property_document_params
    params.require(:property_document).permit(:title, :file_name, :category, :visibility, :position)
  end

  def next_position
    @property.property_documents.maximum(:position).to_i + 1
  end

  def mime_type_for(file_name)
    case File.extname(file_name).downcase
    when ".pdf"
      "application/pdf"
    when ".doc"
      "application/msword"
    when ".docx"
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    when ".jpg", ".jpeg"
      "image/jpeg"
    when ".png"
      "image/png"
    else
      "application/octet-stream"
    end
  end
end

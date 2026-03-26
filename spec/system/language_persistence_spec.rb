require "rails_helper"

RSpec.describe "Language persistence", type: :system do
  it "keeps a guest language choice across public pages" do
    visit root_path

    find('[data-testid="language-option-de"]', visible: :all).click

    expect(page).to have_current_path(root_path)
    expect(page).to have_css('html[lang="de"]', visible: false)
    expect(page).to have_text("Immobilien ansehen")
    expect(page).to have_css('[data-testid="language-dropdown"] .language-dropdown__summary-code', text: "DE")

    click_link "Immobilien ansehen"

    expect(page).to have_current_path(properties_path)
    expect(page).to have_css('html[lang="de"]', visible: false)
    expect(page).to have_text("Moderne Inserate mit live verfügbaren Besichtigungsterminen durchsuchen")
    expect(page).to have_css('[data-testid="language-dropdown"] .language-dropdown__summary-code', text: "DE")

    find('[data-testid="home-link"]').click

    expect(page).to have_current_path(root_path)
    expect(page).to have_css('html[lang="de"]', visible: false)
    expect(page).to have_text("Immobilien ansehen")
  end
end

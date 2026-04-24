# User Manual

## Contents

- [Documentation index](INDEX.md)
- [Browse the public site](#1-browse-the-public-site)
- [Browse and filter listings](#2-browse-and-filter-listings)
- [Open a property detail page](#3-open-a-property-detail-page)
- [Book a viewing](#4-book-a-viewing)
- [Send an enquiry](#5-send-an-enquiry)
- [Make an offer](#6-make-an-offer)
- [Submit a rental application](#7-submit-a-rental-application)
- [Use appointment self-service links](#8-use-appointment-self-service-links)
- [Use seller tools](#9-use-seller-tools)
- [Use the admin workspace](#10-use-the-admin-workspace)

This guide explains how to use GotTheKeys as if it were a real boutique sales and lettings website.

That framing matters. The app is intentionally believable enough for real product walkthroughs, even though it is also used for QA training and seeded demos.

## 1. Browse The Public Site

Start at `/`.

The homepage introduces:

- the product tone and marketing copy
- featured listings
- calls to browse the full catalogue
- trust cues that make the site feel like a local property business

For training use, the homepage is also a good orientation page because it contains stable navigation, predictable hero content, and a consistent route into the catalogue.

## 2. Browse And Filter Listings

Use:

- `/properties` for the full catalogue
- `/for_sale` for sale-only stock
- `/for_rent` for rental-only stock

The catalogue supports:

- listing-type filters
- area or keyword search
- town filters
- minimum bedroom filters
- price filters
- sort options
- saved-search capture

On combined sale/rental search surfaces, such as `/properties` and `/searches`, choose a listing type before entering a minimum or maximum price. The price fields are disabled until the listing type is known because sale prices and monthly rents use different scales. The sale-only and rent-only catalogues already know their listing type, so their price filters are available immediately.

The shared search form is deliberately conventional: server-rendered filters, paginated results, and stable listing cards.

## 3. Open A Property Detail Page

From a listing card, open the property detail page to view:

- pricing and key facts
- property description
- image and media cues
- public document downloads where available
- viewing-request entry point
- enquiry, offer, or rental-application calls to action

Not every property is configured identically. Some seeded scenarios intentionally present empty states, no-slot cases, or sparse trust cues for testing purposes.

## 4. Request A Viewing

On a property with available public slots:

1. Open the detail page.
2. Choose `Request a viewing`.
3. Fill in your contact details.
4. Select an available slot.
5. Submit the booking request.

After submission, the app creates a `pending` appointment and shows a secure appointment page with:

- the booking reference
- current status
- timeline history
- the secure self-service tokenized link context

Appointment status emails include the secure appointment link so the customer can return to the same tokenized page later.

## 5. Send An Enquiry

If a visitor needs details before booking:

1. Open the property page.
2. Choose the enquiry action.
3. Add a name, a message, and at least one contact method.
4. Submit the form.

For signed-in users, the enquiry form pre-fills name, email, and phone from the account profile. Those fields remain editable so a user can correct details before submitting.

That lead appears in the admin workspace and, when email is present, also supports acknowledgement flows.

## 6. Submit An Offer

On sale listings, visitors can submit:

- buyer name
- email
- phone number
- offer amount
- chain position
- optional notes

The app treats this seriously as a property workflow, but it also leaves a visible audit trail that is useful for training and admin review.

## 7. Submit A Rental Application

On rental listings, visitors can submit:

- applicant contact details
- preferred move-in date
- guarantor information
- affordability notes
- general notes

This flow is intentionally distinct from the offer flow so trainees can work across both sales and lettings patterns.

## 8. Use Appointment Self-Service Links

Booked appointments expose a secure page tied to:

- a public reference
- an access token

Depending on timing and status, the customer may be able to:

- review the appointment
- reschedule to a new slot
- cancel the viewing

The self-service window is intentionally limited, which gives both realistic behavior and useful test coverage.

## 9. Seller Workspace

Signed-in sellers can manage their own listings.

Typical seller tasks:

- create a listing
- edit property details
- manage listing state
- review completeness cues
- manage photos
- manage floor plans
- manage property documents
- review recent lead and progression activity

This area behaves like a lightweight listing workspace rather than a full back-office CRM.

## 10. Admin Workspace

Admins use `/admin` to manage the training environment and the operational side of the app.

High-level admin tasks:

- manage bookings and appointment transitions
- review properties and sellers
- use property booking history links to open the exact booking reference or the customer profile
- inspect notification logs
- adjust booking rules
- preview or reset demo scenarios
- inspect QA guidance and selector diagnostics

The admin area is relevant to the "real product" story, but it is also clearly where the training harness becomes most visible.

## Product Honesty

GotTheKeys should be used respectfully as a property website, but it is still a training application.

That means:

- some datasets are intentionally seeded for repeatability
- some empty states and conflict states exist because they are good training material
- demo-data controls are intentionally powerful for workshop operation
- the app balances product believability with deterministic reset behavior

## Read Next

- [QA and testing guide](QA_TESTING_GUIDE.md)
- [Training session guide](TRAINING_SESSION_GUIDE.md)
- [Demo data operations](DEMO_DATA_OPERATIONS.md)

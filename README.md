# Salesforce–Stripe Payment Link Integration

This project integrates **Salesforce** (using Apex classes) with the **Stripe** payment API to create payment links for Salesforce Contacts. The integration checks for existing payment links for a given Stripe customer and, if none exist, generates a new link via a POST request to Stripe.

## Features

- **Apex Classes:** Handles building, sending, and parsing HTTP requests and responses to the Stripe API.
- **Payment Link Generation:** Automatically creates secure, unique payment links tied to specific Contacts, with itemized payment details included.
- **Error Handling:** Manages errors from Stripe, including failed requests or missing URLs.

## Use Case

This integration allows you to seamlessly generate Stripe payment links from Salesforce, making it easy to charge customers directly from your CRM.

---

This project is an excellent starting point for connecting Salesforce data with Stripe payments.

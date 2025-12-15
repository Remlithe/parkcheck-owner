
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");

// Definicja sekretnego klucza (używana w funkcji)
const stripeKey = defineSecret("STRIPE_API_KEY");

admin.initializeApp();


// --- FUNKCJA 1: DLA WŁAŚCICIELA (PARTNERA)
// Oryginalna funkcja createCustomer została usunięta zgodnie z Twoim życzeniem.
exports.createConnectedAccount = onCall(
    {secrets: [stripeKey]},
    async (request) => {
      const data = request.data;

      if (!request.auth) {
        throw new HttpsError("unauthenticated",
            "Musisz być uwierzytelniony, aby wykonać tę operację.");
      }

      // Walidacja danych
      if (!data.email) {
        throw new HttpsError("invalid-argument", "Brakuje emaila właściciela.");
      }

      try {
        const stripe = require("stripe")(stripeKey.value());

        // 1. Tworzenie konta Connect (Typ Custom)
        // Używamy 'US' i 'btok_us' dla symulacji w trybie sandbox.
        const account = await stripe.accounts.create({
          type: "express",
          country: "US",
          email: data.email,
          business_type: "individual",
          capabilities: {
            card_payments: {requested: true},
            transfers: {requested: true},
          },
        });


        // 2. Podpinamy testowe konto bankowe do tego konta
        // Używamy symbolicznego tokena 'btok_us'
        await stripe.accounts.createExternalAccount(
            account.id,
            {external_account: "btok_us"},
        );

        console.log(`Connected account created: ${account.id}`);

        return {
          stripeAccountId: account.id,
        };
      } catch (error) {
        console.error("Error creating connected account:", error);
        throw new HttpsError("internal", error.message);
      }
    });

// --- FUNKCJA 2: Tworzenie linku do onboardingu Stripe
exports.createAccountLink = onCall(
    {secrets: [stripeKey]},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated",
            "Musisz być uwierzytelniony, aby wykonać tę operację.");
      }

      const {accountId} = request.data;
      if (!accountId) {
        throw new HttpsError("invalid-argument",
            "Brakuje identyfikatora konta (accountId).");
      }

      try {
        const stripe = require("stripe")(stripeKey.value());
        const accountLink = await stripe.accountLinks.create({
          account: accountId,
          // Używamy deep linków, aby wrócić do aplikacji mobilnej.
          // Aplikacja musi być skonfigurowana, aby obsługiwać ten schemat URL.
          refresh_url: "parkcheckowner://stripe/refresh",
          return_url: "parkcheckowner://stripe/return",
          type: "account_onboarding",
        });
        return {url: accountLink.url};
      } catch (error) {
        console.error("Błąd podczas tworzenia linku do konta:", error);
        throw new HttpsError("internal", error.message);
      }
    },
);

// --- FUNKCJA 3: Tworzenie linku do logowania do panelu Stripe
exports.createLoginLink = onCall(
    {secrets: [stripeKey]},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated",
            "Musisz być uwierzytelniony, aby wykonać tę operację.");
      }

      const {accountId} = request.data;
      if (!accountId) {
        throw new HttpsError("invalid-argument",
            "Brakuje identyfikatora konta (accountId).");
      }

      try {
        const stripe = require("stripe")(stripeKey.value());
        // Dla kont 'express' używamy createLoginLink
        const loginLink = await stripe.accounts.createLoginLink(accountId);
        return {url: loginLink.url};
      } catch (error) {
        console.error("Błąd podczas tworzenia linku do logowania:", error);
        throw new HttpsError("internal", error.message);
      }
    },
);

// shredMembers web checkout

// ─── i18n ────────────────────────────────────────────────
var TRANSLATIONS = {
  de: {
    title: 'shredMembers Pro',
    subtitle: 'Voller Zugriff auf alle Trainingspläne, Progress-Tracking und Premium-Features.',
    emailLabel: 'E-Mail-Adresse',
    emailPlaceholder: 'deine@email.com',
    sendLink: 'Magic Link senden',
    linkSent: 'Link gesendet',
    linkSentMsg: 'Wir haben dir einen Login-Link geschickt. Öffne die E-Mail und klicke den Link, um fortzufahren.',
    invalidEmail: 'Bitte gib eine gültige E-Mail-Adresse ein.',
    loadError: 'Fehler beim Laden: ',
    signupError: 'Registrierung momentan nicht möglich. Bitte versuche es in wenigen Minuten erneut oder nutze eine bereits registrierte E-Mail-Adresse.',
    loggedInAs: 'Angemeldet als',
    monthly: 'Monatlich',
    monthlyPeriod: 'pro Monat',
    yearly: 'Jährlich',
    yearlyPeriod: 'pro Jahr · 30% günstiger',
    upgrade: 'Jetzt upgraden',
    trialDays: (d) => `Dein kostenloser Test läuft noch ${d} Tag${d !== 1 ? 'e' : ''}.`,
    trialLink: (d) => `Noch ${d} Tag${d !== 1 ? 'e' : ''} kostenlos testen`,
    trialLinkSuffix: ' – kein Abo nötig',
    otherEmail: 'Andere E-Mail verwenden',
    alreadyActive: 'Du hast bereits ein aktives Abonnement. Öffne die App, um Premium zu nutzen.',
    alreadyActiveBtn: 'Bereits aktiv',
    appStore: 'Im App Store herunterladen',
    playStore: 'Bei Google Play herunterladen',
    linkPlayStore: 'Weiter zu Google Play',
    linkAppStore: 'Weiter zu App Store',
    linkWebApp: 'Weiter zur Web App',
    checkoutError: 'Checkout konnte nicht gestartet werden',
    notLoggedIn: 'Nicht angemeldet',
    noUrl: 'Keine Checkout-URL erhalten',
    loading: 'Bitte warten',
  },
  en: {
    title: 'shredMembers Pro',
    subtitle: 'Full access to all training plans, progress tracking and premium features.',
    emailLabel: 'Email address',
    emailPlaceholder: 'your@email.com',
    sendLink: 'Send Magic Link',
    linkSent: 'Link sent',
    linkSentMsg: 'We sent you a login link. Open your email and click the link to continue.',
    invalidEmail: 'Please enter a valid email address.',
    loadError: 'Loading error: ',
    signupError: 'Registration currently unavailable. Please try again in a few minutes or use an already registered email address.',
    loggedInAs: 'Logged in as',
    monthly: 'Monthly',
    monthlyPeriod: 'per month',
    yearly: 'Yearly',
    yearlyPeriod: 'per year · 30% cheaper',
    upgrade: 'Upgrade now',
    trialDays: (d) => `Your free trial has ${d} day${d !== 1 ? 's' : ''} remaining.`,
    trialLink: (d) => `Try free for ${d} more day${d !== 1 ? 's' : ''}`,
    trialLinkSuffix: ' – no subscription needed',
    otherEmail: 'Use a different email',
    alreadyActive: 'You already have an active subscription. Open the app to use Premium.',
    alreadyActiveBtn: 'Already active',
    appStore: 'Download on the App Store',
    playStore: 'Get it on Google Play',
    linkPlayStore: 'Continue to Google Play',
    linkAppStore: 'Continue to App Store',
    linkWebApp: 'Continue to Web App',
    checkoutError: 'Could not start checkout',
    notLoggedIn: 'Not logged in',
    noUrl: 'No checkout URL received',
    loading: 'Please wait',
  },
  fr: {
    title: 'shredMembers Pro',
    subtitle: 'Accès complet à tous les plans d\'entraînement, suivi des progrès et fonctionnalités premium.',
    emailLabel: 'Adresse e-mail',
    emailPlaceholder: 'ton@email.com',
    sendLink: 'Envoyer le Magic Link',
    linkSent: 'Lien envoyé',
    linkSentMsg: 'Nous t\'avons envoyé un lien de connexion. Ouvre ton e-mail et clique sur le lien pour continuer.',
    invalidEmail: 'Veuillez entrer une adresse e-mail valide.',
    loadError: 'Erreur de chargement: ',
    signupError: 'Inscription momentanément indisponible. Veuillez réessayer dans quelques minutes ou utiliser une adresse déjà enregistrée.',
    loggedInAs: 'Connecté en tant que',
    monthly: 'Mensuel',
    monthlyPeriod: 'par mois',
    yearly: 'Annuel',
    yearlyPeriod: 'par an · 30% moins cher',
    upgrade: 'Passer à Pro',
    trialDays: (d) => `Il reste ${d} jour${d !== 1 ? 's' : ''} à ton essai gratuit.`,
    trialLink: (d) => `Encore ${d} jour${d !== 1 ? 's' : ''} d'essai gratuit`,
    trialLinkSuffix: ' – sans abonnement',
    otherEmail: 'Utiliser un autre e-mail',
    alreadyActive: 'Tu as déjà un abonnement actif. Ouvre l\'app pour utiliser Premium.',
    alreadyActiveBtn: 'Déjà actif',
    appStore: 'Télécharger sur l\'App Store',
    playStore: 'Disponible sur Google Play',
    linkPlayStore: 'Continuer vers Google Play',
    linkAppStore: "Continuer vers l'App Store",
    linkWebApp: "Continuer vers l'app web",
    checkoutError: 'Impossible de démarrer le paiement',
    notLoggedIn: 'Non connecté',
    noUrl: 'Aucune URL de paiement reçue',
    loading: 'Veuillez patienter',
  },
  it: {
    title: 'shredMembers Pro',
    subtitle: 'Accesso completo a tutti i piani di allenamento, monitoraggio dei progressi e funzionalità premium.',
    emailLabel: 'Indirizzo e-mail',
    emailPlaceholder: 'tua@email.com',
    sendLink: 'Invia Magic Link',
    linkSent: 'Link inviato',
    linkSentMsg: 'Ti abbiamo inviato un link di accesso. Apri la tua e-mail e clicca sul link per continuare.',
    invalidEmail: 'Inserisci un indirizzo e-mail valido.',
    loadError: 'Errore di caricamento: ',
    signupError: 'Registrazione momentaneamente non disponibile. Riprova tra qualche minuto o usa un indirizzo già registrato.',
    loggedInAs: 'Connesso come',
    monthly: 'Mensile',
    monthlyPeriod: 'al mese',
    yearly: 'Annuale',
    yearlyPeriod: 'all\'anno · 30% di sconto',
    upgrade: 'Passa a Pro',
    trialDays: (d) => `Il tuo periodo di prova scade tra ${d} giorn${d !== 1 ? 'i' : 'o'}.`,
    trialLink: (d) => `Ancora ${d} giorn${d !== 1 ? 'i' : 'o'} di prova gratuita`,
    trialLinkSuffix: ' – nessun abbonamento',
    otherEmail: 'Usa un\'altra e-mail',
    alreadyActive: 'Hai già un abbonamento attivo. Apri l\'app per utilizzare Premium.',
    alreadyActiveBtn: 'Già attivo',
    appStore: 'Scarica su App Store',
    playStore: 'Disponibile su Google Play',
    linkPlayStore: 'Continua su Google Play',
    linkAppStore: "Continua sull'App Store",
    linkWebApp: "Continua sulla Web App",
    checkoutError: 'Impossibile avviare il checkout',
    notLoggedIn: 'Non connesso',
    noUrl: 'Nessun URL di checkout ricevuto',
    loading: 'Attendere prego',
  },
};

function getLang() {
  const lang = (navigator.language || 'de').toLowerCase().substring(0, 2);
  return TRANSLATIONS[lang] ? lang : 'de';
}

var t = TRANSLATIONS[getLang()];

var SUPABASE_URL = 'https://xcgfzunpvremqdlamvbw.supabase.co';
var SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjZ2Z6dW5wdnJlbXFkbGFtdmJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA2OTI4MTYsImV4cCI6MjA5NjI2ODgxNn0.AOI3_v-HJp2DpAd2uLv-4cvqUYKJ8wVMPQBqJFQ3mj4';
var REDIRECT_URL = `${window.location.origin}${window.location.pathname}`;

var supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

let selectedPrice = 'yearly';
let currentSession = null;

const stepEmail = document.getElementById('step-email');
const checkoutSection = document.getElementById('step-plan');
const emailInput = document.getElementById('email');
const btnEmail = document.getElementById('btn-email');
const msgEmail = document.getElementById('msg-email');
const btnCheckout = document.getElementById('btn-checkout');
const btnLogout = document.getElementById('btn-logout');
const msgPlan = document.getElementById('msg-plan');
const storeLinks = document.getElementById('store-links');
const userEmailEl = document.getElementById('user-email');
const planEls = document.querySelectorAll('.plan');

function applyTranslations() {
  document.querySelector('h1').textContent = t.title;
  document.querySelector('.subtitle').textContent = t.subtitle;
  document.querySelector('label[for="email"]') && (document.querySelector('label[for="email"]').textContent = t.emailLabel);
  emailInput.placeholder = t.emailPlaceholder;
  btnEmail.textContent = t.sendLink;
  btnCheckout.textContent = t.upgrade;
  btnLogout.textContent = t.otherEmail;
  const iosLink = document.getElementById('ios-link');
  const androidLink = document.getElementById('android-link');
  if (iosLink) iosLink.textContent = t.appStore;
  if (androidLink) androidLink.textContent = t.playStore;
  document.querySelectorAll('.plan')[0].querySelector('.plan-title').textContent = t.monthly;
  document.querySelectorAll('.plan')[0].querySelector('.plan-period').textContent = t.monthlyPeriod;
  document.querySelectorAll('.plan')[1].querySelector('.plan-title').textContent = t.yearly;
  document.querySelectorAll('.plan')[1].querySelector('.plan-period').textContent = t.yearlyPeriod;
  const trialSuffix = document.getElementById('trial-link-suffix');
  if (trialSuffix) trialSuffix.textContent = t.trialLinkSuffix;
  const btnTrial = document.getElementById('btn-trial');
  if (btnTrial) btnTrial.textContent = t.trialLink(30);
  const linkPlayStore = document.getElementById('link-playstore');
  const linkAppStore = document.getElementById('link-appstore');
  const linkWebApp = document.getElementById('link-webapp');
  if (linkPlayStore) linkPlayStore.textContent = '▶ ' + t.linkPlayStore;
  if (linkAppStore) linkAppStore.textContent = ' ' + t.linkAppStore;
  if (linkWebApp) linkWebApp.textContent = '🌐 ' + t.linkWebApp;
}

var STORE_URLS = {
  playStore: 'https://play.google.com/store/apps/details?id=com.shredmembers.app',
  appStore: 'https://apps.apple.com/app/shredmembers/id0000000000',
  webApp: 'https://shredmember.app',
};

async function init() {
  console.log('[WEB] init started');
  applyTranslations();
  const lps = document.getElementById('link-playstore');
  const las = document.getElementById('link-appstore');
  const lwa = document.getElementById('link-webapp');
  if (lps) lps.href = STORE_URLS.playStore;
  if (las) las.href = STORE_URLS.appStore;
  if (lwa) { lwa.href = STORE_URLS.webApp; lwa.removeAttribute('target'); }
  try {
    const { data, error } = await supabaseClient.auth.getSession();
    console.log('[WEB] session data:', data, 'error:', error);

    if (data?.session?.user) {
      currentSession = data.session;
      showPlanStep(data.session.user.email);
      return;
    }

    const hash = window.location.hash;
    if (hash && (hash.includes('access_token') || hash.includes('refresh_token'))) {
      console.log('[WEB] detected auth tokens in URL');
      const { data: exchangeData, error: exchangeError } = await supabaseClient.auth.getSession();
      if (exchangeError) throw exchangeError;
      if (exchangeData?.session?.user) {
        currentSession = exchangeData.session;
        showPlanStep(exchangeData.session.user.email);
        window.history.replaceState({}, document.title, window.location.pathname);
        return;
      }
    }

    stepEmail.classList.remove('hidden');
    checkoutSection.classList.add('hidden');
    btnEmail.addEventListener('click', sendMagicLink);
    emailInput.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') sendMagicLink();
    });
    console.log('[WEB] email listeners attached');
  } catch (e) {
    console.error('[WEB] init error:', e);
    showMessage(msgEmail, t.loadError + e.message);
  }
}

function isValidEmail(email) {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return regex.test(email);
}

async function sendMagicLink() {
  const email = emailInput.value.trim();
  console.log('[WEB] sendMagicLink clicked for', email);

  if (!email || !isValidEmail(email)) {
    showMessage(msgEmail, t.invalidEmail);
    return;
  }

  setLoading(btnEmail, true);
  showMessage(msgEmail, '');

  const { error } = await supabaseClient.auth.signInWithOtp({
    email,
    options: {
      shouldCreateUser: true,
      emailRedirectTo: REDIRECT_URL,
    },
  });

  setLoading(btnEmail, false);

  if (error) {
    console.error('[WEB] signInWithOtp error:', error);
    const errorText = typeof error === 'object'
      ? (error.message || error.msg || JSON.stringify(error))
      : String(error);
    const isEmptyError = !errorText || errorText === '{}' || errorText === '{}';
    const displayError = isEmptyError ? t.signupError : 'Fehler: ' + errorText;
    showMessage(msgEmail, displayError);
    return;
  }

  console.log('[WEB] magic link sent');
  showMessage(msgEmail, t.linkSentMsg, true);
  btnEmail.textContent = t.linkSent;
}

async function checkTrialStatus() {
  const { data, error } = await supabaseClient
    .rpc('check_trial_status', { p_user_id: currentSession.user.id });

  if (error) {
    console.error('[WEB] trial status check error:', error);
    return null;
  }

  return data?.[0] ?? null;
}

async function showPlanStep(email) {
  console.log('[WEB] showing plan step for', email);
  stepEmail.classList.add('hidden');
  checkoutSection.classList.remove('hidden');
  planEls.forEach(p => p.style.display = 'block');
  userEmailEl.textContent = email;

  btnLogout.addEventListener('click', async () => {
    await supabaseClient.auth.signOut();
    window.location.reload();
  });

  const trialStatus = await checkTrialStatus();

  if (trialStatus?.subscription_status === 'active') {
    showMessage(msgPlan, t.alreadyActive, true);
    btnCheckout.disabled = true;
    btnCheckout.textContent = t.alreadyActiveBtn;
    planEls.forEach(p => p.style.pointerEvents = 'none');
    storeLinks.classList.remove('hidden');
    return;
  }

  if (trialStatus?.subscription_status === 'trial') {
    const days = trialStatus.days_remaining;
    const trialInfo = document.getElementById('trial-info');
    if (trialInfo) {
      trialInfo.textContent = t.trialDays(days);
      trialInfo.style.display = 'block';
    }
    const btnTrial = document.getElementById('btn-trial');
    if (btnTrial) {
      btnTrial.textContent = t.trialLink(days);
    }
  }

  planEls.forEach(plan => {
    const isSelected = plan.dataset.price === selectedPrice;
    if (isSelected) plan.classList.add('active');
    else plan.classList.remove('active');

    plan.addEventListener('click', () => {
      planEls.forEach(p => p.classList.remove('active'));
      plan.classList.add('active');
      selectedPrice = plan.dataset.price;
      console.log('[WEB] selected plan:', selectedPrice);
    });
  });

  btnCheckout.addEventListener('click', startCheckout);

  const btnTrial = document.getElementById('btn-trial');
  if (btnTrial) {
    btnTrial.addEventListener('click', (e) => {
      e.preventDefault();
      window.location.href = 'shredmembers://';
    });
  }
}

async function startCheckout() {
  console.log('[WEB] startCheckout', selectedPrice);
  setLoading(btnCheckout, true);
  showMessage(msgPlan, '');

  try {
    const token = currentSession?.access_token;
    if (!token) {
      throw new Error(t.notLoggedIn);
    }

    const response = await fetch(`${SUPABASE_URL}/functions/v1/stripe-checkout`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify({
        priceType: selectedPrice,
        successUrl: `${window.location.origin}/success.html?session_id={CHECKOUT_SESSION_ID}`,
        cancelUrl: `${window.location.origin}/cancel.html`,
      }),
    });

    const data = await response.json();
    console.log('[WEB] stripe-checkout response:', data);

    if (!response.ok || data.error) {
      throw new Error(data.error || t.checkoutError);
    }

    if (data.url) {
      window.location.href = data.url;
    } else {
      throw new Error(t.noUrl);
    }
  } catch (e) {
    console.error('[WEB] checkout error:', e);
    showMessage(msgPlan, 'Fehler: ' + e.message);
    setLoading(btnCheckout, false);
  }
}

function setLoading(btn, loading) {
  btn.disabled = loading;
  if (loading) {
    btn.innerHTML = `<span class="spinner"></span>${t.loading}`;
  } else if (btn === btnEmail) {
    btn.textContent = t.sendLink;
  } else {
    btn.textContent = t.upgrade;
  }
}

function showMessage(el, text, isSuccess = false) {
  el.textContent = text;
  el.className = 'message' + (isSuccess ? ' success' : '');
}

init();

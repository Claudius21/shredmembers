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
    otherEmail: 'Andere E-Mail verwenden',
    openApp: 'App öffnen',
    startFreeMsg: 'Starte jetzt deine 30-tägige kostenlose Testphase. Lade die App herunter oder öffne sie direkt.',
    manageSubscription: 'Abo verwalten',
    alreadyActive: 'Du hast bereits ein aktives Abonnement. Öffne die App, um Premium zu nutzen.',
    alreadyActiveBtn: 'Bereits aktiv',
    appStore: 'Im App Store herunterladen',
    playStore: 'Bei Google Play herunterladen',
    linkPlayStore: 'Weiter zu Google Play',
    linkAppStore: 'Weiter zu App Store',
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
    otherEmail: 'Use a different email',
    openApp: 'Open app',
    startFreeMsg: 'Start your 30-day free trial now. Download the app or open it directly.',
    manageSubscription: 'Manage subscription',
    alreadyActive: 'You already have an active subscription. Open the app to use Premium.',
    alreadyActiveBtn: 'Already active',
    appStore: 'Download on the App Store',
    playStore: 'Get it on Google Play',
    linkPlayStore: 'Continue to Google Play',
    linkAppStore: 'Continue to App Store',
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
    otherEmail: 'Utiliser un autre e-mail',
    openApp: "Ouvrir l'app",
    startFreeMsg: "Commence maintenant ton essai gratuit de 30 jours. Télécharge l'app ou ouvre-la directement.",
    manageSubscription: 'Gérer mon abonnement',
    alreadyActive: 'Tu as déjà un abonnement actif. Ouvre l\'app pour utiliser Premium.',
    alreadyActiveBtn: 'Déjà actif',
    appStore: 'Télécharger sur l\'App Store',
    playStore: 'Disponible sur Google Play',
    linkPlayStore: 'Continuer vers Google Play',
    linkAppStore: "Continuer vers l'App Store",
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
    otherEmail: 'Usa un\'altra e-mail',
    openApp: "Apri l'app",
    startFreeMsg: "Inizia subito la tua prova gratuita di 30 giorni. Scarica l'app o aprila direttamente.",
    manageSubscription: 'Gestisci abbonamento',
    alreadyActive: 'Hai già un abbonamento attivo. Apri l\'app per utilizzare Premium.',
    alreadyActiveBtn: 'Già attivo',
    appStore: 'Scarica su App Store',
    playStore: 'Disponibile su Google Play',
    linkPlayStore: 'Continua su Google Play',
    linkAppStore: "Continua sull'App Store",
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
const btnLogout = document.getElementById('btn-logout');
const msgPlan = document.getElementById('msg-plan');
const storeLinks = document.getElementById('store-links');
const userEmailEl = document.getElementById('user-email');

function applyTranslations() {
  document.querySelector('h1').textContent = t.title;
  document.querySelector('.subtitle').textContent = t.subtitle;
  document.querySelector('label[for="email"]') && (document.querySelector('label[for="email"]').textContent = t.emailLabel);
  emailInput.placeholder = t.emailPlaceholder;
  btnEmail.textContent = t.sendLink;
  btnLogout.textContent = t.otherEmail;
  const iosLink = document.getElementById('ios-link');
  const androidLink = document.getElementById('android-link');
  if (iosLink) iosLink.textContent = t.appStore;
  if (androidLink) androidLink.textContent = t.playStore;
  const openApp = document.getElementById('btn-open-app');
  if (openApp) openApp.textContent = t.openApp;
  const linkPlayStore = document.getElementById('link-playstore');
  const linkAppStore = document.getElementById('link-appstore');
  if (linkPlayStore) linkPlayStore.textContent = '▶ ' + t.linkPlayStore;
  if (linkAppStore) linkAppStore.textContent = ' ' + t.linkAppStore;
}

var STORE_URLS = {
  playStore: 'https://play.google.com/store/apps/details?id=com.shredmembers.app',
  appStore: 'https://apps.apple.com/app/shredmembers/id0000000000',
};

async function init() {
  console.log('[WEB] init started');
  applyTranslations();
  const lps = document.getElementById('link-playstore');
  const las = document.getElementById('link-appstore');
  if (lps) lps.href = STORE_URLS.playStore;
  if (las) las.href = STORE_URLS.appStore;
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
  userEmailEl.textContent = email;

  btnLogout.addEventListener('click', async () => {
    await supabaseClient.auth.signOut();
    window.location.reload();
  });

  const startFreeMsg = document.getElementById('start-free-msg');
  if (startFreeMsg) {
    startFreeMsg.textContent = t.startFreeMsg;
  }

  const openAppBtn = document.getElementById('btn-open-app');
  if (openAppBtn) {
    openAppBtn.addEventListener('click', (e) => {
      e.preventDefault();
      // Web App als primärer Einstieg (web-first Strategie)
      window.location.href = 'https://web-shredmembers.web.app';
    });
  }

  const trialStatus = await checkTrialStatus();

  if (trialStatus?.subscription_status === 'active') {
    showMessage(msgPlan, t.alreadyActive, true);
    if (openAppBtn) openAppBtn.textContent = t.alreadyActiveBtn;
    return;
  }

  if (trialStatus?.subscription_status === 'trial') {
    const days = trialStatus.days_remaining;
    const trialInfo = document.getElementById('trial-info');
    if (trialInfo) {
      trialInfo.textContent = t.trialDays(days);
      trialInfo.style.display = 'block';
    }
  }
}

function setLoading(btn, loading) {
  btn.disabled = loading;
  if (loading) {
    btn.innerHTML = `<span class="spinner"></span>${t.loading}`;
  } else if (btn === btnEmail) {
    btn.textContent = t.sendLink;
  }
}

function showMessage(el, text, isSuccess = false) {
  el.textContent = text;
  el.className = 'message' + (isSuccess ? ' success' : '');
}

init();

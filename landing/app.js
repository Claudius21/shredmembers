// shredMembers web checkout
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

async function init() {
  console.log('[WEB] init started');
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
    showMessage(msgEmail, 'Fehler beim Laden: ' + e.message);
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
    showMessage(msgEmail, 'Bitte gib eine gültige E-Mail-Adresse ein.');
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
    const isEmptyError = !errorText || errorText === '{}' || errorText === 'Fehler: ';
    const displayError = isEmptyError
      ? 'Registrierung momentan nicht möglich. Bitte versuche es in wenigen Minuten erneut oder nutze eine bereits registrierte E-Mail-Adresse.'
      : 'Fehler: ' + errorText;
    showMessage(msgEmail, displayError);
    return;
  }

  console.log('[WEB] magic link sent');
  showMessage(msgEmail, 'Wir haben dir einen Login-Link geschickt. Öffne die E-Mail und klicke den Link, um fortzufahren.', true);
  btnEmail.textContent = 'Link gesendet';
}

async function checkExistingSubscription() {
  const { data, error } = await supabaseClient
    .from('subscriptions')
    .select('status')
    .eq('user_id', currentSession.user.id)
    .maybeSingle();

  if (error) {
    console.error('[WEB] subscription check error:', error);
    return false;
  }

  return data?.status === 'active';
}

async function showPlanStep(email) {
  console.log('[WEB] showing plan step for', email);
  stepEmail.classList.add('hidden');
  checkoutSection.classList.remove('hidden');
  planEls.forEach(p => p.style.display = 'block');
  userEmailEl.textContent = email;

  const hasActiveSubscription = await checkExistingSubscription();
  if (hasActiveSubscription) {
    showMessage(msgPlan, 'Du hast bereits ein aktives Abonnement. Öffne die App, um Premium zu nutzen.', true);
    btnCheckout.disabled = true;
    btnCheckout.textContent = 'Bereits aktiv';
    planEls.forEach(p => p.style.pointerEvents = 'none');
    storeLinks.classList.remove('hidden');
    return;
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
  btnLogout.addEventListener('click', async () => {
    await supabaseClient.auth.signOut();
    window.location.reload();
  });
}

async function startCheckout() {
  console.log('[WEB] startCheckout', selectedPrice);
  setLoading(btnCheckout, true);
  showMessage(msgPlan, '');

  try {
    const token = currentSession?.access_token;
    if (!token) {
      throw new Error('Nicht angemeldet');
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
      throw new Error(data.error || 'Checkout konnte nicht gestartet werden');
    }

    if (data.url) {
      window.location.href = data.url;
    } else {
      throw new Error('Keine Checkout-URL erhalten');
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
    btn.innerHTML = '<span class="spinner"></span>Bitte warten';
  } else if (btn === btnEmail) {
    btn.textContent = 'Magic Link senden';
  } else {
    btn.textContent = 'Jetzt upgraden';
  }
}

function showMessage(el, text, isSuccess = false) {
  el.textContent = text;
  el.className = 'message' + (isSuccess ? ' success' : '');
}

init();

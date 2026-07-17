// shredMembers billing page (Stripe checkout)
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
const userEmailEl = document.getElementById('user-email');
const planEls = document.querySelectorAll('.plan');

async function init() {
  try {
    const { data } = await supabaseClient.auth.getSession();
    if (data?.session?.user) {
      currentSession = data.session;
      showPlanStep(data.session.user.email);
      return;
    }

    const hash = window.location.hash;
    if (hash && (hash.includes('access_token') || hash.includes('refresh_token'))) {
      const { data: exchangeData } = await supabaseClient.auth.getSession();
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
  } catch (e) {
    showMessage(msgEmail, 'Fehler beim Laden: ' + e.message);
  }
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

async function sendMagicLink() {
  const email = emailInput.value.trim();
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
    showMessage(msgEmail, 'Registrierung momentan nicht möglich. Bitte versuche es in wenigen Minuten erneut.');
    return;
  }

  showMessage(msgEmail, 'Wir haben dir einen Login-Link geschickt. Öffne die E-Mail und klicke den Link.', true);
  btnEmail.textContent = 'Link gesendet';
}

async function showPlanStep(email) {
  stepEmail.classList.add('hidden');
  checkoutSection.classList.remove('hidden');
  userEmailEl.textContent = email;

  btnLogout.addEventListener('click', async () => {
    await supabaseClient.auth.signOut();
    window.location.reload();
  });

  planEls.forEach(plan => {
    const isSelected = plan.dataset.price === selectedPrice;
    if (isSelected) plan.classList.add('active');
    else plan.classList.remove('active');

    plan.addEventListener('click', () => {
      planEls.forEach(p => p.classList.remove('active'));
      plan.classList.add('active');
      selectedPrice = plan.dataset.price;
    });
  });

  btnCheckout.addEventListener('click', startCheckout);
}

async function startCheckout() {
  setLoading(btnCheckout, true);
  showMessage(msgPlan, '');

  try {
    const token = currentSession?.access_token;
    if (!token) throw new Error('Nicht angemeldet');

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
    if (!response.ok || data.error) {
      throw new Error(data.error || 'Checkout konnte nicht gestartet werden');
    }

    if (data.url) window.location.href = data.url;
    else throw new Error('Keine Checkout-URL erhalten');
  } catch (e) {
    showMessage(msgPlan, 'Fehler: ' + e.message);
    setLoading(btnCheckout, false);
  }
}

function setLoading(btn, loading) {
  btn.disabled = loading;
  if (loading) {
    btn.innerHTML = '<span class="spinner"></span>Bitte warten';
  } else if (btn === btnEmail) {
    btn.textContent = 'Anmelden';
  } else {
    btn.textContent = 'Jetzt upgraden';
  }
}

function showMessage(el, text, isSuccess = false) {
  el.textContent = text;
  el.className = 'message' + (isSuccess ? ' success' : '');
}

init();

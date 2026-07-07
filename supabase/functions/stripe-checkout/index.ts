// @ts-nocheck
// Supabase Edge Function: Stripe Checkout Session
// Erstellt eine Checkout-Session für Web-Zahlungen (Store-Gebühren umgehen)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import Stripe from 'https://esm.sh/stripe@12.0.0?target=deno'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { priceType, discountCode, successUrl, cancelUrl } = await req.json()
    
    // Auth-Header prüfen
    const authHeader = req.headers.get('authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Authorization required' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Supabase Admin-Client erstellen
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // Stripe initialisieren
    const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
      apiVersion: '2023-10-16',
      httpClient: Stripe.createFetchHttpClient(),
    })

    // User aus Auth-Header holen
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token)
    
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const userId = user.id
    const userEmail = user.email

    // Subscription-Plan und aktuelle Subscription holen
    const { data: subscription, error: subError } = await supabaseAdmin
      .from('subscriptions')
      .select('*, plan:plan_id(*)')
      .eq('user_id', userId)
      .single()

    if (subError || !subscription) {
      return new Response(
        JSON.stringify({ error: 'Subscription not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Discount Code validieren (optional)
    let stripeCouponId: string | undefined
    let discountCodeId: string | undefined
    
    if (discountCode) {
      const { data: codeData, error: codeError } = await supabaseAdmin
        .from('discount_codes')
        .select('*')
        .eq('code', discountCode.toUpperCase())
        .eq('is_active', true)
        .single()
      
      if (!codeError && codeData) {
        // Prüfe ob Code noch gültig ist
        const now = new Date()
        const isValid = 
          new Date(codeData.valid_from) <= now &&
          (!codeData.valid_until || new Date(codeData.valid_until) >= now) &&
          (!codeData.max_uses || codeData.current_uses < codeData.max_uses)
        
        if (isValid) {
          stripeCouponId = codeData.stripe_coupon_id
          discountCodeId = codeData.id
        }
      }
    }

    // Stripe Customer erstellen oder aktualisieren
    let customerId = subscription.stripe_customer_id
    
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: userEmail,
        metadata: { supabase_user_id: userId }
      })
      customerId = customer.id
      
      // Customer ID speichern
      await supabaseAdmin
        .from('subscriptions')
        .update({ stripe_customer_id: customerId })
        .eq('user_id', userId)
    }

    // Price ID auswählen (monthly oder yearly)
    const priceId = priceType === 'yearly' 
      ? subscription.plan.stripe_yearly_price_id 
      : subscription.plan.stripe_monthly_price_id

    if (!priceId) {
      return new Response(
        JSON.stringify({ error: `Stripe price ID not configured for ${priceType} plan. Add it to subscription_plans in Supabase.` }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Checkout Session erstellen
    const sessionConfig: any = {
      customer: customerId,
      line_items: [{
        price: priceId,
        quantity: 1,
      }],
      mode: 'subscription',
      success_url: successUrl || 'shredmembers://payment/success?session_id={CHECKOUT_SESSION_ID}',
      cancel_url: cancelUrl || 'shredmembers://payment/cancel',
      metadata: {
        supabase_user_id: userId,
        discount_code_id: discountCodeId || '',
      },
      subscription_data: {
        metadata: {
          supabase_user_id: userId,
        }
      }
    }

    // Discount anwenden falls vorhanden
    if (stripeCouponId) {
      sessionConfig.discounts = [{ coupon: stripeCouponId }]
    }

    const session = await stripe.checkout.sessions.create(sessionConfig)

    return new Response(
      JSON.stringify({ 
        sessionId: session.id, 
        url: session.url,
        discountApplied: !!stripeCouponId 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

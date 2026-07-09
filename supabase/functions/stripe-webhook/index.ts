// Supabase Edge Function: Stripe Webhook Handler
// Verarbeitet Stripe-Events und aktualisiert die Datenbank

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import Stripe from 'https://esm.sh/stripe@12.0.0?target=deno'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Stripe-Signatur verifizieren
const verifyStripeSignature = async (
  payload: string,
  signature: string,
  secret: string
): Promise<Stripe.Event | null> => {
  try {
    const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
      apiVersion: '2023-10-16',
      httpClient: Stripe.createFetchHttpClient(),
    })
    
    return stripe.webhooks.constructEvent(payload, signature, secret)
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message)
    return null
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const signature = req.headers.get('stripe-signature')
  if (!signature) {
    return new Response(
      JSON.stringify({ error: 'No signature' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  const payload = await req.text()
  const endpointSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET') ?? ''
  
  const event = await verifyStripeSignature(payload, signature, endpointSecret)
  if (!event) {
    return new Response(
      JSON.stringify({ error: 'Invalid signature' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  // Supabase Admin-Client
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    { auth: { persistSession: false } }
  )

  try {
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object as Stripe.Checkout.Session
        const userId = session.metadata?.supabase_user_id
        const discountCodeId = session.metadata?.discount_code_id
        
        if (!userId) break

        // Subscription-Details holen
        const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
          apiVersion: '2023-10-16',
          httpClient: Stripe.createFetchHttpClient(),
        })
        const subscription = await stripe.subscriptions.retrieve(session.subscription as string)

        // Price-ID holen (aus dem ersten Item der Subscription)
        const priceId = subscription.items.data[0]?.price.id
        let planId: string | null = null
        let priceType: 'monthly' | 'yearly' = 'monthly'

        // Plan anhand der Price-ID finden
        if (priceId) {
          const { data: plans } = await supabaseAdmin
            .from('subscription_plans')
            .select('id, stripe_monthly_price_id, stripe_yearly_price_id')
            .eq('is_active', true)
          
          const matchingPlan = plans?.find(plan => 
            plan.stripe_monthly_price_id === priceId || 
            plan.stripe_yearly_price_id === priceId
          )
          
          if (matchingPlan) {
            planId = matchingPlan.id
            priceType = matchingPlan.stripe_yearly_price_id === priceId ? 'yearly' : 'monthly'
          }
        }

        // Subscription in Datenbank aktualisieren
        const { error: updateError } = await supabaseAdmin
          .from('subscriptions')
          .update({
            status: 'active',
            stripe_subscription_id: subscription.id,
            subscribed_at: new Date().toISOString(),
            current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
            current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
            discount_code_id: discountCodeId || null,
            discount_applied: !!discountCodeId,
            plan_id: planId,
            price_type: priceType,
          })
          .eq('user_id', userId)

        if (updateError) {
          console.error('Error updating subscription:', updateError)
        }

        // Discount Code Usage erhöhen
        if (discountCodeId) {
          await supabaseAdmin.rpc('increment_discount_usage', { code_id: discountCodeId })
        }

        break
      }

      case 'invoice.payment_succeeded': {
        const invoice = event.data.object as Stripe.Invoice
        const subscriptionId = invoice.subscription
        
        if (!subscriptionId) break

        // Subscription-Details holen
        const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
          apiVersion: '2023-10-16',
          httpClient: Stripe.createFetchHttpClient(),
        })
        
        const subscription = await stripe.subscriptions.retrieve(subscriptionId as string)
        const userId = subscription.metadata?.supabase_user_id
        
        if (!userId) break

        // Periode aktualisieren
        await supabaseAdmin
          .from('subscriptions')
          .update({
            current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
            current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
          })
          .eq('stripe_subscription_id', subscriptionId)

        break
      }

      case 'customer.subscription.deleted':
      case 'customer.subscription.updated': {
        const subscription = event.data.object as Stripe.Subscription
        const userId = subscription.metadata?.supabase_user_id
        
        if (!userId) break

        const status = subscription.status
        const cancelAtPeriodEnd = subscription.cancel_at_period_end

        let dbStatus: string
        if (status === 'active' && !cancelAtPeriodEnd) {
          dbStatus = 'active'
        } else if (status === 'active' && cancelAtPeriodEnd) {
          dbStatus = 'active' // Bleibt aktiv bis Period-Ende
        } else if (status === 'canceled' || status === 'unpaid') {
          dbStatus = 'canceled'
        } else {
          dbStatus = status
        }

        await supabaseAdmin
          .from('subscriptions')
          .update({
            status: dbStatus,
            cancel_at_period_end: cancelAtPeriodEnd,
            current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
          })
          .eq('stripe_subscription_id', subscription.id)

        break
      }
    }

    return new Response(
      JSON.stringify({ received: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Webhook error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

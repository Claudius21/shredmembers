-- Stripe Live Price IDs für ShredMembers Pro eintragen
-- Diese IDs kommen aus dem Stripe-Dashboard (Livemodus).

update public.subscription_plans
set stripe_monthly_price_id = 'price_1Tk1QKKTz45bhpVhPoKe5s5c',
    stripe_yearly_price_id  = 'price_1Tk2mgKTz45bhpVhVSGFKRti'
where name = 'ShredMembers Pro';

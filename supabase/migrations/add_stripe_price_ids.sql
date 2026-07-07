-- Stripe Price IDs für ShredMembers Pro eintragen
-- Diese IDs kommen aus dem Stripe-Dashboard (Testmodus).
-- Wenn sich die IDs ändern, muss dieses Update erneut ausgeführt werden.

update public.subscription_plans
set stripe_monthly_price_id = 'price_1TqbmXKTz45bhpVhun83VVCw',
    stripe_yearly_price_id  = 'price_1TqbjAKTz45bhpVhyXfeiutj'
where name = 'ShredMembers Pro';

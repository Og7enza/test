import { config } from '../config';

export interface ChargeResult {
  transactionId: string;
}

/**
 * Encaisse un paiement.
 * - Réel via Stripe quand STRIPE_SECRET_KEY est fourni (TODO PaymentIntent).
 * - Sinon : simulé.
 */
export async function charge(args: {
  amount: number;
  currency: string;
  token?: string;
}): Promise<ChargeResult> {
  if (config.stripeEnabled) {
    // TODO: Stripe PaymentIntent côté serveur.
  }
  void args;
  return { transactionId: 'demo_' + Date.now() };
}

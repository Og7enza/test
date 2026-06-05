import dotenv from 'dotenv';

dotenv.config();

const env = process.env;

export const config = {
  port: Number(env.PORT || 4000),
  apiPrefix: env.API_PREFIX || '/api/v1',

  jwtSecret: env.JWT_SECRET || '',
  get authEnabled() {
    return this.jwtSecret.length > 0;
  },

  mongoUri: env.MONGODB_URI || '',
  get dbEnabled() {
    return this.mongoUri.length > 0;
  },

  storage: (env.STORAGE || 'local') as 'local' | 's3' | 'ipfs',
  publicBaseUrl: env.PUBLIC_BASE_URL || `http://localhost:${env.PORT || 4000}`,

  polygonRpcUrl: env.POLYGON_RPC_URL || '',
  minterPrivateKey: env.MINTER_PRIVATE_KEY || '',
  nftContract: env.NFT_CONTRACT_ADDRESS || '',
  chain: env.CHAIN || 'polygon-amoy',
  get nftEnabled() {
    return !!(this.polygonRpcUrl && this.minterPrivateKey && this.nftContract);
  },

  stripeSecretKey: env.STRIPE_SECRET_KEY || '',
  get stripeEnabled() {
    return this.stripeSecretKey.length > 0;
  },
  mintPrice: Number(env.MINT_PRICE || 2.99),
  currency: env.CURRENCY || 'EUR',
};

/** Petit récap du mode au démarrage. */
export function modeSummary(): string {
  return [
    `auth=${config.authEnabled ? 'JWT' : 'DÉMO'}`,
    `db=${config.dbEnabled ? 'MongoDB' : 'mémoire'}`,
    `storage=${config.storage}`,
    `nft=${config.nftEnabled ? 'réel' : 'simulé'}`,
    `paiement=${config.stripeEnabled ? 'Stripe' : 'simulé'}`,
  ].join(' · ');
}

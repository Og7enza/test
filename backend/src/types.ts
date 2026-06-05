export interface User {
  id: string;
  uid: string;
  name: string;
  email: string;
}

/** Preuve certifiée (compatible avec l'ancien `MintedImage`). */
export interface Certificate {
  _id: string;
  userId: string;
  matricule: string;
  name: string;
  image: string; // URL publique
  sha256: string;
  lat?: number;
  lng?: number;
  location: string;
  city?: string;
  country?: string;
  time: string; // horodatage de capture (ISO)
  status: string;
  tokenId?: string;
  contractAddress?: string;
  nftTransferHash?: string;
  chain?: string;
  isArchived: boolean;
  isPublic: boolean;
  transactionId?: string;
  createdAt: string;
  transferedAt?: string;
  __v: number;
}

export interface Coupon {
  id: string;
  coupon: string;
  percentOff: number;
}

export interface AppNotification {
  _id: string;
  userId: string;
  title: string;
  body: string;
  read: boolean;
  createdAt: string;
}

export interface Transaction {
  _id: string;
  userId: string;
  type: 'mint' | 'transfer';
  amount: number;
  currency: string;
  matricule?: string;
  status: string;
  createdAt: string;
}

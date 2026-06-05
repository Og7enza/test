import { AppNotification, Certificate, Coupon, Transaction, User } from './types';

// Store en mémoire (mode démo). Remplaçable par MongoDB si MONGODB_URI est défini
// (même surface de méthodes -> migration sans toucher aux routes).
const users = new Map<string, User>(); // clé: uid
const certificates = new Map<string, Certificate>(); // clé: _id (= matricule)
const coupons = new Map<string, Coupon>(); // clé: code
const notifications = new Map<string, AppNotification>();
const transactions = new Map<string, Transaction>();

function seed() {
  const demo: User = {
    id: 'demo',
    uid: 'demo',
    name: 'Démo',
    email: 'demo@truthcatcher.app',
  };
  users.set(demo.uid, demo);

  coupons.set('DEMO10', { id: 'c1', coupon: 'DEMO10', percentOff: 10 });
  coupons.set('TRUTH50', { id: 'c2', coupon: 'TRUTH50', percentOff: 50 });

  const now = Date.now();
  const addCert = (i: number, name: string, city: string) => {
    const matricule = `TC-DEMO-000${i}-AAAA`;
    const iso = new Date(now - i * 86400000).toISOString();
    certificates.set(matricule, {
      _id: matricule,
      userId: 'demo',
      matricule,
      name,
      image: `https://picsum.photos/seed/tc${i}/800/1000`,
      sha256: 'a'.repeat(64),
      location: `${city}, France`,
      city,
      country: 'France',
      time: iso,
      status: 'minted',
      tokenId: String(10240 + i),
      contractAddress: '0xMOCK0000000000000000000000000000000000',
      nftTransferHash: '0x' + '0'.repeat(64),
      chain: 'polygon',
      isArchived: false,
      isPublic: true,
      createdAt: iso,
      __v: 0,
    });
  };
  addCert(1, 'Compteur kilométrique', 'Paris');
  addCert(2, 'État des lieux — salon', 'Lyon');

  notifications.set('n1', {
    _id: 'n1',
    userId: 'demo',
    title: 'Bienvenue sur TruthCatcher',
    body: 'Certifiez votre première photo infalsifiable.',
    read: false,
    createdAt: new Date(now).toISOString(),
  });
}
seed();

export const store = {
  upsertUser(u: User) {
    users.set(u.uid, u);
    return u;
  },
  getUserByUid(uid: string) {
    return users.get(uid);
  },
  deleteUser(uid: string) {
    users.delete(uid);
  },

  listCertificates(userId: string, archived: boolean) {
    return [...certificates.values()]
      .filter((c) => c.userId === userId && c.isArchived === archived)
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  },
  getByMatricule(m: string) {
    const norm = m.trim().toUpperCase();
    return [...certificates.values()].find(
      (c) => c.matricule.toUpperCase() === norm,
    );
  },
  addCertificate(c: Certificate) {
    certificates.set(c._id, c);
    return c;
  },
  updateByMatricule(m: string, patch: Partial<Certificate>) {
    const c = this.getByMatricule(m);
    if (!c) return undefined;
    Object.assign(c, patch);
    certificates.set(c._id, c);
    return c;
  },

  listCoupons() {
    return [...coupons.values()];
  },
  getCoupon(code: string) {
    return coupons.get(code.trim().toUpperCase());
  },

  listNotifications(userId: string) {
    return [...notifications.values()]
      .filter((n) => n.userId === userId)
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  },
  markNotificationsRead(userId: string) {
    for (const n of notifications.values()) {
      if (n.userId === userId) n.read = true;
    }
  },

  listTransactions(userId: string) {
    return [...transactions.values()]
      .filter((t) => t.userId === userId)
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  },
  addTransaction(t: Transaction) {
    transactions.set(t._id, t);
    return t;
  },
};

// seed_node/seed_filters.js
// [Wave 11 v3] — Modular firebase-admin API (v13+ compatible)

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const serviceAccount = require('./serviceAccountKey.json');

initializeApp({ credential: cert(serviceAccount) });

const db = getFirestore();

const FILTERS = [
  {
    id: 'sort', nameAr: 'الترتيب', nameEn: 'Sort by', type: 'sort', fieldKey: 'sort',
    icon: 'sort', order: 10, isActive: true, isRequired: false,
    rolesAllowed: ['user','merchant','moderator','admin'], matchMode: 'exact',
    options: [
      { value: 'recommended', labelAr: 'موصى به', labelEn: 'Recommended', icon: 'star' },
      { value: 'rating_desc', labelAr: 'الأعلى تقييماً', labelEn: 'Highest rated', icon: 'star_half' },
      { value: 'newest', labelAr: 'الأحدث', labelEn: 'Newest', icon: 'schedule' },
      { value: 'distance', labelAr: 'الأقرب', labelEn: 'Nearest', icon: 'near_me' },
    ],
  },
  {
    id: 'wifi', nameAr: 'واي فاي', nameEn: 'Wi-Fi', type: 'boolean', fieldKey: 'hasWifi',
    icon: 'wifi', order: 20, isActive: true, isRequired: false,
    rolesAllowed: ['user','merchant','moderator','admin'], matchMode: 'exact',
    options: [{ value: 'true', labelAr: 'متاح واي فاي', labelEn: 'Has Wi-Fi', icon: 'wifi' }],
  },
  {
    id: 'parking', nameAr: 'موقف سيارات', nameEn: 'Parking', type: 'boolean', fieldKey: 'hasParking',
    icon: 'local_parking', order: 21, isActive: true, isRequired: false,
    rolesAllowed: ['user','merchant','moderator','admin'], matchMode: 'exact',
    options: [{ value: 'true', labelAr: 'متاح موقف', labelEn: 'Has parking', icon: 'local_parking' }],
  },
  {
    id: 'restroom', nameAr: 'دورات مياه', nameEn: 'Restrooms', type: 'boolean', fieldKey: 'hasRestroom',
    icon: 'wc', order: 22, isActive: true, isRequired: false,
    rolesAllowed: ['user','merchant','moderator','admin'], matchMode: 'exact',
    options: [{ value: 'true', labelAr: 'متاح دورة مياه', labelEn: 'Has restroom', icon: 'wc' }],
  },
  {
    id: 'accessibility', nameAr: 'إتاحة للمعاقين', nameEn: 'Accessibility', type: 'boolean', fieldKey: 'hasAccessibility',
    icon: 'accessible', order: 23, isActive: true, isRequired: false,
    rolesAllowed: ['user','merchant','moderator','admin'], matchMode: 'exact',
    options: [{ value: 'true', labelAr: 'متاح دخول للمعاقين', labelEn: 'Wheelchair accessible', icon: 'accessible' }],
  },
  {
    id: 'family_friendly', nameAr: 'مناسب للعائلات', nameEn: 'Family friendly', type: 'boolean', fieldKey: 'isFamilyFriendly',
    icon: 'family_restroom', order: 30, isActive: true, isRequired: false,
    rolesAllowed: ['user','merchant','moderator','admin'], matchMode: 'exact',
    options: [{ value: 'true', labelAr: 'مناسب للعائلات', labelEn: 'Family friendly', icon: 'family_restroom' }],
  },
  {
    id: 'halal', nameAr: 'حلال', nameEn: 'Halal', type: 'boolean', fieldKey: 'isHalal',
    icon: 'verified', order: 31, isActive: true, isRequired: false,
    rolesAllowed: ['user','merchant','moderator','admin'], matchMode: 'exact',
    options: [{ value: 'true', labelAr: 'حلال', labelEn: 'Halal', icon: 'verified' }],
  },
  {
    id: 'delivery', nameAr: 'توصيل', nameEn: 'Delivery', type: 'boolean', fieldKey: 'hasDelivery',
    icon: 'delivery_dining', order: 32, isActive: true, isRequired: false,
    rolesAllowed: ['user','merchant','moderator','admin'], matchMode: 'exact',
    options: [{ value: 'true', labelAr: 'خدمة توصيل', labelEn: 'Delivery', icon: 'delivery_dining' }],
  },
  {
    id: 'reservation', nameAr: 'حجز مسبق', nameEn: 'Reservation', type: 'boolean', fieldKey: 'hasReservation',
    icon: 'event_available', order: 33, isActive: true, isRequired: false,
    rolesAllowed: ['user','merchant','moderator','admin'], matchMode: 'exact',
    options: [{ value: 'true', labelAr: 'متاح حجز مسبق', labelEn: 'Reservation available', icon: 'event_available' }],
  },
  {
    id: 'price', nameAr: 'السعر', nameEn: 'Price', type: 'single_choice', fieldKey: 'priceLevel',
    icon: 'attach_money', order: 40, isActive: true, isRequired: false,
    rolesAllowed: ['user','merchant','moderator','admin'], matchMode: 'exact',
    options: [
      { value: '1', labelAr: 'اقتصادي', labelEn: 'Budget', icon: 'money_off' },
      { value: '2', labelAr: 'متوسط', labelEn: 'Moderate', icon: 'attach_money' },
      { value: '3', labelAr: 'فاخر', labelEn: 'Premium', icon: 'paid' },
    ],
  },
  {
    id: 'rating', nameAr: 'التقييم', nameEn: 'Rating', type: 'range', fieldKey: 'averageRating',
    icon: 'star', order: 50, isActive: true, isRequired: false,
    rolesAllowed: ['user','merchant','moderator','admin'], matchMode: 'gte',
    options: [
      { value: '3', labelAr: '3 نجوم فأكثر', labelEn: '3+ stars', icon: 'star_half' },
      { value: '4', labelAr: '4 نجوم فأكثر', labelEn: '4+ stars', icon: 'star' },
      { value: '4.5', labelAr: '4.5 نجمة فأكثر', labelEn: '4.5+ stars', icon: 'stars' },
    ],
  },
];

async function seedFilters() {
  const batch = db.batch();
  const now = FieldValue.serverTimestamp();

  const existing = await db.collection('filters').get();
  existing.forEach((doc) => batch.delete(doc.ref));

  for (const filter of FILTERS) {
    const { id, ...data } = filter;
    batch.set(db.collection('filters').doc(id), {
      ...data, id, createdAt: now, updatedAt: now,
    });
  }

  await batch.commit();
  console.log(`✅ Seeded ${FILTERS.length} filters (replaced ${existing.size} old ones).`);
  console.log('📋 Filter IDs:', FILTERS.map((f) => f.id).join(', '));
}

seedFilters()
  .then(() => process.exit(0))
  .catch((err) => { console.error('❌ Seed failed:', err); process.exit(1); });
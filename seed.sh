#!/bin/bash
PROJECT_ID="ya-baladi"
API_KEY="AIzaSyDhIi4IxjfTSw_aleoJbtKZsJYR35C_j7Q"
BASE="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents"

SUCCESS=0
FAILED=0

seed_doc() {
  local collection="$1"
  local doc_id="$2"
  local json="$3"
  local response code

  # امسح القديم لو موجود (نتجاهل النتيجة)
  curl -s -X DELETE "${BASE}/${collection}/${doc_id}?key=${API_KEY}" >/dev/null

  # أنشئ من جديد بـ POST + documentId
  response=$(curl -s -w "\n%{http_code}" -X POST \
    "${BASE}/${collection}?documentId=${doc_id}&key=${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "${json}")
  code=$(echo "$response" | tail -1)

  if [ "$code" = "200" ] || [ "$code" = "201" ]; then
    echo "✅ ${collection}/${doc_id}"
    SUCCESS=$((SUCCESS+1))
  else
    echo "❌ ${collection}/${doc_id} — HTTP ${code}"
    echo "$response" | head -n -1 | head -c 300
    echo
    FAILED=$((FAILED+1))
  fi
}

echo "🌱 Seeding categories (9)..."
seed_doc "categories" "restaurants" '{"fields":{"nameAr":{"stringValue":"مطاعم"},"nameEn":{"stringValue":"Restaurants"},"iconKey":{"stringValue":"مطعم"},"order":{"integerValue":"1"},"isActive":{"booleanValue":true},"placeCount":{"integerValue":"0"}}}'
seed_doc "categories" "cafes" '{"fields":{"nameAr":{"stringValue":"كافيهات"},"nameEn":{"stringValue":"Cafes"},"iconKey":{"stringValue":"كافيه"},"order":{"integerValue":"2"},"isActive":{"booleanValue":true},"placeCount":{"integerValue":"0"}}}'
seed_doc "categories" "beaches" '{"fields":{"nameAr":{"stringValue":"شواطئ وبلاجات"},"nameEn":{"stringValue":"Beaches"},"iconKey":{"stringValue":"بلاج"},"order":{"integerValue":"3"},"isActive":{"booleanValue":true},"placeCount":{"integerValue":"0"}}}'
seed_doc "categories" "hotels" '{"fields":{"nameAr":{"stringValue":"فنادق ومنتجعات"},"nameEn":{"stringValue":"Hotels & Resorts"},"iconKey":{"stringValue":"فندق ومنتجع"},"order":{"integerValue":"4"},"isActive":{"booleanValue":true},"placeCount":{"integerValue":"0"}}}'
seed_doc "categories" "family" '{"fields":{"nameAr":{"stringValue":"ترفيه أسري"},"nameEn":{"stringValue":"Family & Entertainment"},"iconKey":{"stringValue":"ترفيه أسري"},"order":{"integerValue":"5"},"isActive":{"booleanValue":true},"placeCount":{"integerValue":"0"}}}'
seed_doc "categories" "landmarks" '{"fields":{"nameAr":{"stringValue":"معالم تاريخية"},"nameEn":{"stringValue":"Historical Landmarks"},"iconKey":{"stringValue":"معلم تاريخي"},"order":{"integerValue":"6"},"isActive":{"booleanValue":true},"placeCount":{"integerValue":"0"}}}'
seed_doc "categories" "shopping" '{"fields":{"nameAr":{"stringValue":"تسوق"},"nameEn":{"stringValue":"Shopping"},"iconKey":{"stringValue":"تسوق"},"order":{"integerValue":"7"},"isActive":{"booleanValue":true},"placeCount":{"integerValue":"0"}}}'
seed_doc "categories" "parks" '{"fields":{"nameAr":{"stringValue":"حدائق ومتنزهات"},"nameEn":{"stringValue":"Parks"},"iconKey":{"stringValue":"حديقة"},"order":{"integerValue":"8"},"isActive":{"booleanValue":true},"placeCount":{"integerValue":"0"}}}'
seed_doc "categories" "events" '{"fields":{"nameAr":{"stringValue":"فعاليات"},"nameEn":{"stringValue":"Events"},"iconKey":{"stringValue":"فعالية"},"order":{"integerValue":"9"},"isActive":{"booleanValue":true},"placeCount":{"integerValue":"0"}}}'

echo ""
echo "🌱 Seeding places (12)..."
seed_doc "places" "abu_tarek" '{"fields":{"nameAr":{"stringValue":"مطعم أبو طارق"},"nameEn":{"stringValue":"Abu Tarek Restaurant"},"description":{"stringValue":"أشهر مطعم كشري في القاهرة"},"categoryId":{"stringValue":"restaurants"},"ownerId":{"stringValue":"seed"},"location":{"geoPointValue":{"latitude":30.0589,"longitude":31.2436}},"address":{"stringValue":"27 شارع شريف، وسط البلد"},"city":{"stringValue":"القاهرة"},"governorate":{"stringValue":"القاهرة"},"phone":{"stringValue":"+20 100 000 0001"},"whatsapp":{"stringValue":""},"imageUrls":{"arrayValue":{"values":[]}},"tags":{"arrayValue":{"values":[]}},"averageRating":{"doubleValue":4.7},"reviewCount":{"integerValue":"312"},"priceLevel":{"integerValue":"1"},"isApproved":{"booleanValue":true},"isActive":{"booleanValue":true}}}'
seed_doc "places" "fish_market" '{"fields":{"nameAr":{"stringValue":"مطعم فيش ماركت"},"nameEn":{"stringValue":"Fish Market"},"description":{"stringValue":"أسماك طازة على البحر المتوسط"},"categoryId":{"stringValue":"restaurants"},"ownerId":{"stringValue":"seed"},"location":{"geoPointValue":{"latitude":31.2001,"longitude":29.9187}},"address":{"stringValue":"كورنيش الإسكندرية"},"city":{"stringValue":"الإسكندرية"},"governorate":{"stringValue":"الإسكندرية"},"phone":{"stringValue":"+20 100 000 0002"},"whatsapp":{"stringValue":""},"imageUrls":{"arrayValue":{"values":[]}},"tags":{"arrayValue":{"values":[]}},"averageRating":{"doubleValue":4.5},"reviewCount":{"integerValue":"180"},"priceLevel":{"integerValue":"3"},"isApproved":{"booleanValue":true},"isActive":{"booleanValue":true}}}'
seed_doc "places" "cafe_celine" '{"fields":{"nameAr":{"stringValue":"كافيه سيلين"},"nameEn":{"stringValue":"Cafe Celine"},"description":{"stringValue":"كافيه بإطلالة على البحر"},"categoryId":{"stringValue":"cafes"},"ownerId":{"stringValue":"seed"},"location":{"geoPointValue":{"latitude":27.2579,"longitude":33.8116}},"address":{"stringValue":"ممشى السياحة، الغردقة"},"city":{"stringValue":"الغردقة"},"governorate":{"stringValue":"البحر الأحمر"},"phone":{"stringValue":"+20 100 000 0003"},"whatsapp":{"stringValue":""},"imageUrls":{"arrayValue":{"values":[]}},"tags":{"arrayValue":{"values":[]}},"averageRating":{"doubleValue":4.6},"reviewCount":{"integerValue":"95"},"priceLevel":{"integerValue":"2"},"isApproved":{"booleanValue":true},"isActive":{"booleanValue":true}}}'
seed_doc "places" "beit_elqahwa" '{"fields":{"nameAr":{"stringValue":"بيت القهوة"},"nameEn":{"stringValue":"Beit El Qahwa"},"description":{"stringValue":"قهوة مختصة في وسط البلد"},"categoryId":{"stringValue":"cafes"},"ownerId":{"stringValue":"seed"},"location":{"geoPointValue":{"latitude":30.0459,"longitude":31.2621}},"address":{"stringValue":"شارع المعز"},"city":{"stringValue":"القاهرة"},"governorate":{"stringValue":"القاهرة"},"phone":{"stringValue":"+20 100 000 0004"},"whatsapp":{"stringValue":""},"imageUrls":{"arrayValue":{"values":[]}},"tags":{"arrayValue":{"values":[]}},"averageRating":{"doubleValue":4.8},"reviewCount":{"integerValue":"210"},"priceLevel":{"integerValue":"1"},"isApproved":{"booleanValue":true},"isActive":{"booleanValue":true}}}'
seed_doc "places" "marriott_beach" '{"fields":{"nameAr":{"stringValue":"شاطئ ماريوت"},"nameEn":{"stringValue":"Marriott Beach"},"description":{"stringValue":"شاطئ رملي خاص بالمنتجع"},"categoryId":{"stringValue":"beaches"},"ownerId":{"stringValue":"seed"},"location":{"geoPointValue":{"latitude":27.2311,"longitude":33.8399}},"address":{"stringValue":"الغردقة"},"city":{"stringValue":"الغردقة"},"governorate":{"stringValue":"البحر الأحمر"},"phone":{"stringValue":"+20 100 000 0005"},"whatsapp":{"stringValue":""},"imageUrls":{"arrayValue":{"values":[]}},"tags":{"arrayValue":{"values":[]}},"averageRating":{"doubleValue":4.9},"reviewCount":{"integerValue":"420"},"priceLevel":{"integerValue":"4"},"isApproved":{"booleanValue":true},"isActive":{"booleanValue":true}}}'
seed_doc "places" "san_stefano_beach" '{"fields":{"nameAr":{"stringValue":"شاطئ سان ستيفانو"},"nameEn":{"stringValue":"San Stefano Beach"},"description":{"stringValue":"شاطئ عائلي على الكورنيش"},"categoryId":{"stringValue":"beaches"},"ownerId":{"stringValue":"seed"},"location":{"geoPointValue":{"latitude":31.2411,"longitude":29.9621}},"address":{"stringValue":"سان ستيفانو"},"city":{"stringValue":"الإسكندرية"},"governorate":{"stringValue":"الإسكندرية"},"phone":{"stringValue":"+20 100 000 0006"},"whatsapp":{"stringValue":""},"imageUrls":{"arrayValue":{"values":[]}},"tags":{"arrayValue":{"values":[]}},"averageRating":{"doubleValue":4.3},"reviewCount":{"integerValue":"165"},"priceLevel":{"integerValue":"1"},"isApproved":{"booleanValue":true},"isActive":{"booleanValue":true}}}'
seed_doc "places" "hilton_plaza" '{"fields":{"nameAr":{"stringValue":"فندق هيلتون بلازا"},"nameEn":{"stringValue":"Hilton Plaza Hotel"},"description":{"stringValue":"فندق 5 نجوم في وسط القاهرة"},"categoryId":{"stringValue":"hotels"},"ownerId":{"stringValue":"seed"},"location":{"geoPointValue":{"latitude":30.0561,"longitude":31.2262}},"address":{"stringValue":"ميدان التحرير"},"city":{"stringValue":"القاهرة"},"governorate":{"stringValue":"القاهرة"},"phone":{"stringValue":"+20 100 000 0007"},"whatsapp":{"stringValue":""},"imageUrls":{"arrayValue":{"values":[]}},"tags":{"arrayValue":{"values":[]}},"averageRating":{"doubleValue":4.6},"reviewCount":{"integerValue":"530"},"priceLevel":{"integerValue":"4"},"isApproved":{"booleanValue":true},"isActive":{"booleanValue":true}}}'
seed_doc "places" "rixos_sharm" '{"fields":{"nameAr":{"stringValue":"فندق ريكسوس شرم"},"nameEn":{"stringValue":"Rixos Sharm"},"description":{"stringValue":"منتجع فاخر على البحر الأحمر"},"categoryId":{"stringValue":"hotels"},"ownerId":{"stringValue":"seed"},"location":{"geoPointValue":{"latitude":27.9158,"longitude":34.3299}},"address":{"stringValue":"خليج نبق"},"city":{"stringValue":"شرم الشيخ"},"governorate":{"stringValue":"جنوب سيناء"},"phone":{"stringValue":"+20 100 000 0008"},"whatsapp":{"stringValue":""},"imageUrls":{"arrayValue":{"values":[]}},"tags":{"arrayValue":{"values":[]}},"averageRating":{"doubleValue":4.8},"reviewCount":{"integerValue":"780"},"priceLevel":{"integerValue":"4"},"isApproved":{"booleanValue":true},"isActive":{"booleanValue":true}}}'
seed_doc "places" "dream_park" '{"fields":{"nameAr":{"stringValue":"دريم بارك"},"nameEn":{"stringValue":"Dream Park"},"description":{"stringValue":"مدينة ملاهي للأسر والأطفال"},"categoryId":{"stringValue":"family"},"ownerId":{"stringValue":"seed"},"location":{"geoPointValue":{"latitude":30.0331,"longitude":31.0171}},"address":{"stringValue":"6 أكتوبر"},"city":{"stringValue":"الجيزة"},"governorate":{"stringValue":"الجيزة"},"phone":{"stringValue":"+20 100 000 0009"},"whatsapp":{"stringValue":""},"imageUrls":{"arrayValue":{"values":[]}},"tags":{"arrayValue":{"values":[]}},"averageRating":{"doubleValue":4.4},"reviewCount":{"integerValue":"620"},"priceLevel":{"integerValue":"2"},"isApproved":{"booleanValue":true},"isActive":{"booleanValue":true}}}'
seed_doc "places" "kidzania" '{"fields":{"nameAr":{"stringValue":"كيدزانيا"},"nameEn":{"stringValue":"KidZania"},"description":{"stringValue":"مدينة تعليمية ترفيهية للأطفال"},"categoryId":{"stringValue":"family"},"ownerId":{"stringValue":"seed"},"location":{"geoPointValue":{"latitude":30.0263,"longitude":31.4925}},"address":{"stringValue":"كايرو فيستيفال سيتي"},"city":{"stringValue":"القاهرة"},"governorate":{"stringValue":"القاهرة"},"phone":{"stringValue":"+20 100 000 0010"},"whatsapp":{"stringValue":""},"imageUrls":{"arrayValue":{"values":[]}},"tags":{"arrayValue":{"values":[]}},"averageRating":{"doubleValue":4.5},"reviewCount":{"integerValue":"290"},"priceLevel":{"integerValue":"3"},"isApproved":{"booleanValue":true},"isActive":{"booleanValue":true}}}'
seed_doc "places" "giza_pyramids" '{"fields":{"nameAr":{"stringValue":"أهرامات الجيزة"},"nameEn":{"stringValue":"Giza Pyramids"},"description":{"stringValue":"أعظم معالم مصر التاريخية"},"categoryId":{"stringValue":"landmarks"},"ownerId":{"stringValue":"seed"},"location":{"geoPointValue":{"latitude":29.9792,"longitude":31.1342}},"address":{"stringValue":"الهرم"},"city":{"stringValue":"الجيزة"},"governorate":{"stringValue":"الجيزة"},"phone":{"stringValue":"+20 100 000 0011"},"whatsapp":{"stringValue":""},"imageUrls":{"arrayValue":{"values":[]}},"tags":{"arrayValue":{"values":[]}},"averageRating":{"doubleValue":4.9},"reviewCount":{"integerValue":"1540"},"priceLevel":{"integerValue":"2"},"isApproved":{"booleanValue":true},"isActive":{"booleanValue":true}}}'
seed_doc "places" "city_stars" '{"fields":{"nameAr":{"stringValue":"سيتي ستارز مول"},"nameEn":{"stringValue":"City Stars Mall"},"description":{"stringValue":"أكبر مول تجاري في مصر"},"categoryId":{"stringValue":"shopping"},"ownerId":{"stringValue":"seed"},"location":{"geoPointValue":{"latitude":30.0729,"longitude":31.3456}},"address":{"stringValue":"مدينة نصر"},"city":{"stringValue":"القاهرة"},"governorate":{"stringValue":"القاهرة"},"phone":{"stringValue":"+20 100 000 0012"},"whatsapp":{"stringValue":""},"imageUrls":{"arrayValue":{"values":[]}},"tags":{"arrayValue":{"values":[]}},"averageRating":{"doubleValue":4.6},"reviewCount":{"integerValue":"890"},"priceLevel":{"integerValue":"3"},"isApproved":{"booleanValue":true},"isActive":{"booleanValue":true}}}'

echo ""
echo "════════════════════════════════"
echo "🎉 Done: ${SUCCESS} success, ${FAILED} failed"
echo "════════════════════════════════"

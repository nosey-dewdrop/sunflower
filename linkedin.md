# linkedin.md — sunflower essay stoğu
> Format (Damla): numaralı inşa zinciri, karar-karar. Her essay 300-500+ kelime, TR, dürüst. Ne yaptım + NEDEN + hangi kararı verdim. Yazı Damla'nın; bunlar iskelet ve gerçek tarihçeden çıkıyor. Reels için devlog.md, projeye bağsız kişisel konular için ~/damla_projects_2026/damla-icerik.md.

---

## DAMLA-ESSAY 1 — bir günde bütün uygulamayı kurdum, sonra yarısını söktüm

sunflower'ı bir günde yazdım. 23 mart. sabah swiftdata modelleri, pomodoro döngüsü, timer, özet, istatistik, ayarlar. akşam olduğunda çalışan bir pomodoro uygulaması vardı. o gün attığım commit'lere baktığımda gördüğüm şey bir yazılımcının değil, bir kararsızın günlüğü.

çünkü kurduğum şeyin yarısını aynı gün söktüm.

önce pomodoro döngüsünü ekledim: odaklan, mola, odaklan, mola. klasik. sonra sildim. "remove breaks and pomodoro cycle, simple timer only" yazıyor commit'te. neden? çünkü mola bir zorlama. insan molayı kendi verir, uygulama araya girip "şimdi dur" demesin. odak ekranı tek bir işi yapmalı: sen odaklanırken önünden çekilmeli.

sonra bir market sistemi ekledim. coin kazan, bahçeye eşya sürükle, dükkandan ağaç çiçek dekor al. tam bir oyunlaştırma paketi. commit'i attıktan birkaç saat sonra market'i ayarların içine gizledim, sonra timer ekranına taşıdım, sonra swipe hareketine bağladım, en sonunda temmuzda tamamen sildim: "remove market and coin system."

o gün öğrendiğim şey şu: özellik eklemek kolay, hangi özelliğin ürünü zayıflattığını görmek zor. market para kazandırabilirdi ama uygulamanın ruhunu bozuyordu. sunflower "odaklanınca çiçek açar" diyor; araya coin, dükkan, sürükle-bırak girince mesaj bulanıklaşıyor. odak uygulamasının içine dükkan koyarsan artık odak uygulaması değil, oyun.

navigasyonda da aynı kararsızlık: market'e nasıl gidilecek? önce ikon koydum, sonra "ikon yok ipucu yok" dedim, swipe up market, swipe down özet, sonra sayfa sayfa kaydırma, sonra snap ile bölümlere yapışma. bir günde beş farklı navigasyon denedim. hepsi commit'lerde duruyor.

biri bu tarihçeye bakıp "ne kadar dağınık" diyebilir. ben tam tersini görüyorum. bir günde çalışan bir şey kurup, aynı gün onu acımasızca eleştirip fazlalıkları sökebilmek, benim en hızlı öğrendiğim döngü. bitir, göster, ölç, at. market'i silmeseydim bugün sunflower bir başka jenerik oyunlaştırma uygulaması olurdu. sildim, çünkü sildiğimde geriye tek ve net bir söz kaldı: odaklan, çiçek aç. gerisi gürültüydü.

---

## DAMLA-ESSAY 2 — çiçeği öldürmekten çiçeği solmaya: bir odak uygulamasının ahlakı

ilk sürümde sunflower zalimdi. "forest mode" diye bir şey vardı: odak sırasında uygulamadan çıkarsan çiçek ölür, oturum iptal. Forest uygulamasının klasik mekaniği — telefonu bırakırsan ağacın yaşar, dokunursan ölür. ceza ile motivasyon.

temmuzda bunu tamamen değiştirdim ve bu değişiklik ürünün karakterini belirledi.

sorun şuydu: ceza mekaniği insanı odak sırasında bile suçlu hissettiriyor. telefonu kilitlemek çiçeği öldürür mü? bir telefon geldi, açtın, çiçek gitti mi? forest mantığında bunların hepsi risk. ama gerçek hayatta insan telefonunu kilitler, arama gelir, çocuğu seslenir. odak dediğin şey steril bir laboratuvar değil. bir uygulama seni odaklanman için cezalandırıyorsa, o uygulama senin tarafında değil.

yeni mekanik: "gentle wilt." erken çıkarsan çiçek ölmez, filiz yavaşça solup toprağa geri döner. bir grace period var — birkaç saniye tolerans, kaza dokunuşu oturumu bitirmesin diye. duvar saati mantığıyla çalışıyor, arka planda kaldığın süreyi gerçek zamanla ölçüyor. ve en önemlisi: bahçe her sabah sıfırlanır. dün soldursan bugün taze toprak. streak devam eder ama suçluluk devam etmez.

App Store açıklamasına yazdığım cümle bu felsefeyi özetliyor: "telefonu kilitlemek ya da bir arama almak çiçeğine asla zarar vermez. biz odağı cezalandırmıyoruz." ve: "yarın taze bir toprak parçası."

bu küçük bir kod değişikliği değildi, bir değer kararıydı. ceza veren bir odak uygulaması kısa vadede işe yarar — korku motive eder. ama korku ile kurulan alışkanlık kırılgandır. bir kere çiçeğini öldürünce uygulamayı silersin, çünkü artık sana kötü hissettiren bir şey o. solma mekaniği ise affediyor. affeden bir ürüne geri dönersin.

sunflower'ın rakiplerinden ayrıldığı yer teknoloji değil, ahlak. aynı timer, aynı bahçe, ama bir tanesi "başaramazsan öldürürüm" diyor, diğeri "bugün olmadıysa yarın var" diyor. hangisiyle üç ay sonra hâlâ odaklanıyorsun? benim cevabım solmaydı.

---

## DAMLA-ESSAY 3 — paywall'u iki kez taşıdım çünkü yanlış şeyi satıyordum

sunflower'da para kararı üç aşamada oturdu ve her aşama bana ürün fiyatlaması hakkında bir şey öğretti.

ilk paywall (2 temmuz): StoreKit 2 ile "sunflower pro" kurdum. serbest oturum süresi (5-120 dk) Pro'ydu. yani ücretsiz kullanıcı sadece sabit sürelerle çalışabilecekti, "istediğim kadar odaklanmak" para arkasındaydı.

bir haftada bunun yanlış olduğunu gördüm. commit: "make custom session length free." süreyi seçmek temel bir hak, onu duvarın arkasına koymak cimrilik gibi hissettiriyor. birine "istediğin kadar odaklanmak için para ver" diyorsun. odak uygulamasında odağın süresini satmak, ürünün özünü fidyeye almak demek.

o zaman Pro ne satacak? kararı FocusPomo modelinden aldım: Pro güç satmalı, çiçek değil. commit'te yazdığım cümle bu — "pro sells power not flowers." çiçekleri, bahçeyi, streak'i, widget'ları asla satmam; bunlar ürünün kalbi, herkese ücretsiz. Pro iki gerçek güç veriyor: Focus Shield (odaktayken dikkat dağıtan uygulamaları FamilyControls ile engelleme) ve derin istatistikler.

ama burada da dürüst olmam gerekti. "derin istatistik" diye para istiyorsan, gerçekten derin bir istatistik ekranı olmalı. yoksa boş bir vaat satarsın. o yüzden Stats ekranını baştan kurdum: Gün/Hafta/Ay, Swift Charts ile bar grafik, takvim heatmap'i, etiket donut'u, trend rozeti, sayıların sayarak artması, dönemler arası kaydırma, haptic. Gün ücretsiz — herkes bugününü görsün. Hafta, Ay ve heatmap Pro'nun arkasında. böylece paywall'un "derin istatistik" sözü yalan değil, ekranda karşılığı var.

öğrendiğim ilke: neyi sattığın, ürünün ne olduğunu söyler. süreyi satarsan "cimri odak uygulaması"sın. çiçekleri satarsan "duygularını fidyeye alan uygulama"sın. gücü ve derinliği satarsan — engelleme, analiz — o zaman temel deneyim herkese açık kalır, para veren insan gerçekten fazladan bir şey alır. paywall'u iki kez taşıdım çünkü ilk iki yerde yanlış şeyi satıyordum. üçüncüde ürünün kalbini ücretsiz bırakıp, sadece "daha fazla güç"ü sattım. bir odak uygulaması insana odağını değil, odaklanma gücünü satmalı.

---

## DAMLA-ESSAY 4 — çizemediğim için Midjourney'e gittim, ve stil beni aylarca reddetti

sunflower'ın bütün ruhu el çizimi doodle'larda: eğri büğrü petalli çiçekler, mum boya dokusu, çocuk çizimi gibi naif şekiller. sorun şu ki ben bu asset'leri çizemiyorum. profesyonel illüstratör değilim ve uygulamanın onlarca çiçek/dekor/böcek sprite'ına ihtiyacı var.

karar: asset üretimini Midjourney'e taşıdım. tam bir prompt paketi yazdım (docs/mj-asset-prompts.md) — her slot için birebir isim, paylaşılan stil son eki, üç stil çapası olarak mevcut placeholder'ları --sref ile referans veriyorum. Damla MJ'de üretir, ham PNG'leri bırakır, ben chroma-key ile şeffaflaştırıp, halo temizleyip, 1:1 yerine oturturum. iş bölümü net.

ama asıl ders stildeydi ve stil beni tur tur reddetti.

önce mum boya reçetesi: "taranmış bir mum boya çizimi gibi görünüyor," reddedildi. sonra fotoğraf sticker görünümü: reddedildi. ince fineliner: reddedildi. kalın maskot outline'ı: reddedildi. dört farklı stil ailesi, dört ret. bu noktada kendime bir kural koydum çünkü kör iterasyon token da yakıyor, motivasyon da: DUR. Damla'dan somut bir referans al, körlemesine tur atma. şu an canlı aday "çocuksu şekiller + storybook painterly render" ama onu bile somut referans gelmeden basmıyorum.

zemin kararı ayrı bir öğrenmeydi. önce yoğun bir çim dokusu istedim — tam ekran çim. sonra fark ettim: 25 dakika bakılan bir odak ekranında yoğun doku gözü yorar. karar: zemin sade ve sakin yeşil kalsın; çim canlılığı statik dokudan değil, DİNAMİK sprite katmanından gelsin. ~50 tek tek çim teli/tutamı, MJ asset sheet'lerinden kesilmiş, SwiftUI'da rüzgarda sallanan ve parmağa tepki veren (Canvas + TimelineView + yay fiziği). uğur böceği parmaktan kaçıyor. ama v1'de doku-warp shader YOK — su dalgalanması hissi vermesinden korktum, shader'ı ileri cila olarak rafa kaldırdım.

buradan çıkardığım şey: yapamadığın işi doğru araca devretmek zayıflık değil, mimari. ben çizemiyorum ama iyi prompt yazabiliyorum, kesim-yerleştirme pipeline'ı kurabiliyorum, ve en önemlisi neyin "AI kokmadığını" ayırt edebiliyorum. dört ret bir başarısızlık değil, bir tanım süreci. her ret "bu değil"i netleştiriyor. ve kör tur atmayı bırakıp referans istemek, hem tokeni hem ruhu koruyor. üretici model elimde, ama zevk ve kural bende.

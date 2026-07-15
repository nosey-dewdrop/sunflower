# devlog.md — instagram build-in-public reels kuyruğu
> Format (Damla): minik parçalar, her ünite 30-60 sn'lik hook'lu reels (post/carousel de olur). Anlatım: "bugün şunu değiştirdim arkadaşlar, çünkü şöyle bir sorun vardı" + numaralı neden/karar. Bunlar iskelet, Damla kendi ağzıyla anlatır. Her satır gerçek; sayılar/kararlar commit tarihçesinden. LinkedIn essay'leri linkedin.md'de, projeye bağsız kişisel konular ~/damla_projects_2026/damla-icerik.md'de.
> görsel notları: [sim] = simülatör ekran kaydı, [garden] = bahçe ekranı, [stats] = istatistik ekranı, [asset] = MJ ham + kesilmiş PNG yan yana, [commit] = git log ekranı, [landing] = landing page.

## seri A — ürün ve karakter

A1 · HOOK: "odaklanınca ekranda bir çiçek açıyor. yarım bırakınca çiçek ÖLMÜYOR."
**Anlatı (~40 sn):** bir pomodoro uygulaması yaptım ama en önemli kararı çiçeği öldürmemek oldu. bir odak bitirirsen bahçende çiçek açıyor. erken çıkarsan filiz yavaşça soluyor ve toprağa dönüyor — ölmüyor, suçlamıyor. yarın taze toprak. çünkü seni odaklanman için cezalandıran bir uygulama senin tarafında değildir.
**EN (text-on-video):** "finish a focus, a flower blooms. quit early, it gently wilts — no dead flowers, no guilt. tomorrow is fresh soil." [garden]
**Format:** reel

A2 · HOOK: "uygulamayı bir GÜNDE yazdım. sonra yarısını aynı gün SÖKTÜM."
**Anlatı (~45 sn):** 23 mart. sabah kurdum: timer, bahçe, istatistik. akşam yarısını sildim. pomodoro molasını ekledim, sildim — mola bir zorlama, insan molayı kendi verir. market sistemi ekledim, coin, dükkan — sildim, çünkü odak uygulamasının içine dükkan koyarsan artık odak uygulaması değil oyun olur. bir günde beş farklı navigasyon denedim, hepsi commit'lerde duruyor. dağınık değil bu — hızlı öğrenmek.
**EN (text-on-video):** "built the whole app in one day. deleted half of it the same day. adding features is easy. seeing which one weakens the product is hard." [commit]
**Format:** reel

A3 · HOOK: "bu uygulamada para kazanan özelliği İKİ KEZ taşıdım."
**Anlatı (~45 sn):** ilk sürümde 'istediğin kadar odaklanmak' paralıydı. bir haftada gördüm ki yanlış: odak uygulamasında odağın süresini satmak, ürünün özünü fidyeye almak. ücretsiz yaptım. sonra kural koydum: Pro güç satar, çiçek satmaz. çiçekler, bahçe, streak, widget herkese ücretsiz. Pro sadece iki gerçek güç veriyor — dikkat dağıtan uygulamaları engelleme ve derin istatistik. neyi sattığın, ürünün ne olduğunu söyler.
**EN (text-on-video):** "what you sell tells people what your product is. sell the timer's length and you're a stingy focus app. sell power, and the heart stays free." [stats]
**Format:** reel

A4 · HOOK: "'derin istatistik' diye para istiyorsan, gerçekten derin bir ekran olmalı."
**Anlatı (~40 sn):** paywall 'derin istatistik' vaat ediyorsa yalan olmasın diye Stats ekranını baştan kurdum: Gün/Hafta/Ay, Swift Charts bar grafik, takvim heatmap'i, etiket donut'u, trend rozeti, sayarak artan sayılar, dönemler arası kaydırma, haptic. Gün ücretsiz — herkes bugününü görür. Hafta ve Ay Pro. böylece paywall'un sözünün ekranda karşılığı var. boş vaat satmam.
**EN (text-on-video):** "if you charge for 'deep stats', the stats better be deep. day is free. week + month behind pro. the promise has to be real on screen." [stats]
**Format:** reel

## seri B — tasarım ve asset savaşı

B1 · HOOK: "çizemediğim için Midjourney'e gittim. stil beni DÖRT KEZ reddetti."
**Anlatı (~50 sn):** uygulamanın bütün ruhu el çizimi doodle'larda ama ben illüstratör değilim. asset üretimini MJ'e taşıdım, tam bir prompt paketi yazdım. ama stil beni tur tur reddetti: mum boya — 'taranmış çizim gibi', ret. fotoğraf sticker — ret. ince fineliner — ret. kalın maskot outline — ret. dört stil, dört ret. sonra kural koydum: DUR, kör tur atma, somut referans al. her ret bir başarısızlık değil, 'bu değil'i netleştiren bir tanım.
**EN (text-on-video):** "i can't draw, so i went to midjourney. the style rejected me four times. every rejection isn't failure — it defines what 'not this' means." [asset]
**Format:** reel

B2 · HOOK: "25 dakika bakılan bir ekranda YOĞUN çim gözü yorar. bug değil, dikkat."
**Anlatı (~40 sn):** önce tam ekran yoğun bir çim dokusu istedim. sonra fark ettim: odak ekranı 25 dakika bakılıyor, yoğun doku yorar. karar: zemin sade sakin yeşil kalsın, çim canlılığı statik dokudan değil DİNAMİK bir sprite katmanından gelsin — ~50 tek tek çim teli, rüzgarda sallanan, parmağa tepki veren. uğur böceği parmaktan kaçıyor. hareketi doku değil, fizik veriyor.
**EN (text-on-video):** "a screen you stare at for 25 minutes shouldn't tire your eyes. plain calm ground + a living grass layer that reacts to your finger. motion from physics, not texture." [garden]
**Format:** reel

B3 · HOOK: "v1'e su dalgası shader'ı KOYMADIM. güzeldi ama yanlış histi."
**Anlatı (~35 sn):** çimi rüzgarda dalgalandırmak için bir texture-warp shader denemek istedim. ama fark ettim: warp efekti su dalgalanması hissi veriyor, odak ekranında huzursuz. shader'ı rafa kaldırdım, ileri cila olarak parkta duruyor. bunun yerine SwiftUI Canvas + TimelineView + yay fiziğiyle her çim telini tek tek salladım. bazen doğru karar, güzel olanı ertelemektir.
**EN (text-on-video):** "cut the water-ripple shader from v1. it looked cool but felt wrong on a focus screen. sometimes the right call is postponing the pretty thing." [garden]
**Format:** reel

## seri C — teknik günlük

C1 · HOOK: "uygulamayı arka plana atınca timer'ın DEVAM etmesini nasıl sağladım."
**Anlatı (~40 sn):** timer'ı basit bir sayaç yaparsan telefonu kilitleyince durur. odak uygulaması bunu yapamaz. duvar saati mantığına geçtim: başlangıç zamanını kaydediyorum, ekran her uyandığında gerçek geçen süreyi hesaplıyorum. arka plana atma, kilit, gelen arama — timer gerçek zamanla ilerliyor, scene phase'i dinleyip solma toleransını da buradan yönetiyorum.
**EN (text-on-video):** "a focus timer can't stop when you lock the phone. wall-clock time, not a naive counter. lock it, take a call — the timer keeps real time." [sim]
**Format:** reel

C2 · HOOK: "gece 3'te ModelContainer crash. sabah düzeltmesi bir mimari dersti."
**Anlatı (~40 sn):** SwiftData ModelContainer başlatması patlıyordu. düzelttim, sonra derin bir runtime optimizasyonu yaptım: hesaplanan istatistikleri cache'ledim, saat gruplarını önceden hesapladım, formatter'ları static yaptım. bir odak uygulaması takılırsa insanı odaktan çıkarır — akıcılık burada özellik değil, zorunluluk. crash'i önlemek kadar 'her karede yeniden hesaplama' tuzağından kaçmak da işin parçası.
**EN (text-on-video):** "3am ModelContainer crash. the fix was an architecture lesson: cache computed stats, precompute hour groups, static formatters. a laggy focus app breaks focus." [sim]
**Format:** reel

C3 · HOOK: "gün yarısında sıfırlanan bir bahçeyi doğru yapmak sandığından zor."
**Anlatı (~35 sn):** bahçe her sabah sıfırlanmalı, streak devam etmeli. gece yarısı geçişi bir sürü ince hata doğuruyor — bahçe dönüyor mu, istatistik doğru güne mi düşüyor, gün ortası açılan uygulama dünü mü gösteriyor. midnight rollover'ı ayrı ele aldım, özet tarih tipini düzelttim. 'sıfırla ama unutturma' — affeden ürünün mekaniği tam da burada.
**EN (text-on-video):** "a garden that resets every morning but keeps your streak. midnight rollover breeds subtle bugs. 'reset without forgetting' is the whole mechanic." [garden]
**Format:** reel

C4 · HOOK: "Focus Shield'i simülatörde test EDEMİYORUM. gerçek telefon şart."
**Anlatı (~40 sn):** Pro'nun app engelleme özelliği FamilyControls ile çalışıyor. iki gerçek engel var: bir, entitlement için Apple'a başvurup günlerce onay beklemek. iki, Screen Time izinleri simülatörde tam çalışmıyor, gerçek cihazda test etmek zorundasın. bu yüzden v1'i shield olmadan çıkarıp sonra güncelleme olarak eklemeyi de seçenek olarak tutuyorum. bazı özellikler kod bitince bitmiyor, platform seni bekletiyor.
**EN (text-on-video):** "can't test Focus Shield in the simulator — Screen Time needs a real device, and the entitlement needs Apple's approval. some features aren't done when the code is." [sim]
**Format:** reel

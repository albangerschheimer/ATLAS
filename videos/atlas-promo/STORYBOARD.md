---
format: 1920x1080
duration: 45s
message: "Je voulais une app simple et complète pour gérer mes séances de musculation : ATLAS est cette app, native, locale et open source."
arc: "Demo Loop — intention → produit → preuves → confiance → open source"
audience: "sportifs, développeurs et recruteurs découvrant le portfolio"
mode: autonomous
music: none
---

## Video direction

- Palette: registre sombre `#000000`, texte `#FFFFFF`, accent unique ATLAS `#5265FF`, surfaces secondaires `#18181A` et hairlines `#262628`; les captures conservent leurs couleurs natives.
- Typographie: display SF Pro Display très large et serrée, corps SF Pro Text, chrome IBM Plex Mono en capitales espacées. Une hiérarchie dominante par plan, jamais deux titres concurrents.
- Mouvement: entrées `fromTo` nettes à longue décélération `power3`; les informations se révèlent séquentiellement sur leurs propres temps de lecture, surtout dans la seconde moitié. Aucun rebond décoratif.
- Rythme: les frames 1–4 développent le récit par étapes ; la frame 5 offre un arrêt de confiance sur « GPT-5.6 Sol » ; la frame 6 tient l’URL finale trois secondes. Pendant les holds : immobilité assumée, sans respiration ni poussée caméra tardive.
- Composition: noir plein, hairlines, grands mots et écrans iPhone comme seuls volumes. Contenu important dans les 83% supérieurs ; la bande basse reste libre.
- Interdits: aucune texture hors marque, aucun dégradé violet/bleu « IA », aucune carte générique arrondie hors du vrai device, aucun mode slideshow (tout d’un coup puis gel), aucun mode screensaver (éléments flottant indépendamment).

## Frame 1 — L’intention

- scene: La phrase personnelle se tape en très grand, puis « mes séances » se remplace par « toute ma progression » avant le cut.
- duration: 5s
- transition_in: cut
- status: animated
- src: compositions/frames/01-intention.html
- type: hook
- persuasion: Pain validation
- beat: curiosity + recognition
- blueprint: typewriter-reveal (Adapt)
- asset_candidates:

narrativeRole: Faire entendre le besoin dans les mots du créateur, avant toute liste de fonctions.
keyMessage: « Je voulais une app qui me permette de gérer mes séances de musculation. »

Adapt: garder la frappe humaine et la réécriture en place ; remplacer le reveal de logo par une reformulation du besoin, pour que l’intention reste le sujet jusqu’au cut.
Scene 1 (0.0–2.6s): sur le registre sombre vide, le caret bleu tape « Je voulais une app qui me permette de gérer mes séances de musculation. » en display blanc, bloc asymétrique 70/30 ancré haut-gauche ; type-on with caret (`discrete-text-sequence`, `context-sensitive-cursor`), aucune autre information visible.
Scene 2 (2.6–4.3s): « mes séances de musculation » se backspace puis se retape en bleu comme « toute ma progression » ; le reste de la phrase reste fixe, backspace-and-retype (`discrete-text-sequence`), hiérarchie 3:1.
Scene 3 (4.3–5.0s): le caret s’éteint et la phrase finale tient immobile, avec un hairline bleu qui se dessine sous « toute ma progression » (`svg-path-draw`) ; lecture nette avant la transition.

## Frame 2 — Voici ATLAS

- scene: L’écran Aujourd’hui apparaît dans un iPhone monumental ; le cadre recule pour révéler le nom ATLAS et la promesse local-first.
- duration: 7s
- transition_in: zoom-through
- status: animated
- src: compositions/frames/02-atlas.html
- type: product_intro
- persuasion: Friction reduction
- beat: relief + control
- blueprint: device-surface-showcase (Adapt)
- asset_candidates: assets/atlas-today.png — écran Aujourd’hui réel, lancement de séance et synthèse sportive
- focal: assets/atlas-today.png
- roles: atlas-today.png = cutout

narrativeRole: Nommer la solution et faire atterrir la promesse au deuxième beat.
keyMessage: ATLAS est une app iPhone native, rapide et locale pour piloter l’entraînement.

Adapt: garder la surface iPhone persistante comme signature ; remplacer le cycle d’écrans par un reveal en trois temps autour de l’unique capture Aujourd’hui.
Scene 1 (0.0–1.5s): le mot « atlas » entre seul en display blanc, géant et bord gauche, tandis qu’un carré bleu plein se déploie derrière les deux dernières lettres ; per-word reveal (`dynamic-content-sequencing`), cadrage full-width strip, caméra verrouillée.
Scene 2 (1.5–4.5s): l’iPhone contenant `assets/atlas-today.png` monte depuis le bas à droite et se stabilise, dominant ~58% de la hauteur ; surface establish via short slide + settle (`spring-pop-entrance` en registre sans rebond), layout asymétrique 40/60 à trois couches.
Scene 3 (4.5–6.2s): à gauche du device, « native. locale. sans compte. » se révèle ligne par ligne en blanc avec les points bleus (`discrete-text-sequence`), chaque ligne sur son propre temps de lecture ; la capture reste totalement lisible.
Scene 4 (6.2–7.0s): label mono « IPHONE · LOCAL-FIRST » et rule bleue complètent le cadre ; hold statique sur le device et la promesse, sans drift.

## Frame 3 — La séance, sans friction

- scene: L’écran Séance reste héros pendant que trois repères se révèlent au rythme du parcours : séance libre, programmes, bibliothèque de 214 exercices.
- duration: 9s
- transition_in: push-slide LEFT
- status: animated
- src: compositions/frames/03-seance.html
- type: feature_showcase
- persuasion: Show-don’t-tell proof
- beat: ease + power
- blueprint: device-surface-showcase (Reproduce · static-tour)
- asset_candidates: assets/atlas-training.png — écran Séance réel avec CTA, bibliothèque, programmes et historique
- focal: assets/atlas-training.png
- roles: atlas-training.png = cutout

narrativeRole: Prouver que la préparation et l’exécution d’une séance vivent dans une même surface.
keyMessage: Préparer, lancer et retrouver ses séances ne demande que quelques gestes.

Scene 1 (0.0–2.1s): `assets/atlas-training.png` glisse et se cale à gauche dans un iPhone plein cadre, ~62% de la hauteur ; le kicker « LA SÉANCE, SANS FRICTION » entre à droite, surface establish (`spring-pop-entrance` sans overshoot), asymétrique 55/45 à trois couches.
Scene 2 (2.1–4.0s): le premier repère bleu s’aligne sur le CTA visible et le titre latéral devient « séance libre » ; side-headline swap (`discrete-text-sequence`) et rule draw (`svg-path-draw`), aucun faux curseur.
Scene 3 (4.0–6.0s): le repère descend vers « Programmes » et le titre latéral devient « programmes sur mesure » ; même ancre, même vitesse, reveal séquentiel au milieu du plan.
Scene 4 (6.0–7.7s): le repère remonte vers « Bibliothèque d’exercices » ; « 214 exercices » arrive comme grand chiffre bleu avec son label mono, count-up court (`counting-dynamic-scale`) depuis 0 jusqu’à 214.
Scene 5 (7.7–9.0s): les trois bénéfices restent visibles sous forme de trois hairlines plutôt que de cartes ; hold fixe sur l’écran réel, sans poussée caméra tardive.

## Frame 4 — Tout le sport, au même endroit

- scene: L’écran Progrès entre à droite ; à gauche, les preuves s’assemblent en liste : records et 1RM, calendrier sportif, Apple Santé et nutrition.
- duration: 8s
- transition_in: push-slide LEFT
- status: animated
- src: compositions/frames/04-progression.html
- type: benefit_highlight
- persuasion: Feature-to-benefit translation
- beat: clarity + confidence
- blueprint: grid-card-assemble (Adapt)
- asset_candidates: assets/atlas-progress.png — écran Progrès réel avec vue d’ensemble, volume et records
- focal: assets/atlas-progress.png
- roles: atlas-progress.png = cutout

narrativeRole: Élargir la valeur de la simple saisie vers une vision cohérente de la progression et de la récupération.
keyMessage: ATLAS relie entraînement, progression, santé, calendrier et nutrition sans quitter l’iPhone.

Adapt: garder l’accumulation verticale séquentielle ; remplacer les cartes par des lignes éditoriales et tenir la vraie capture Progrès à droite.
Scene 1 (0.0–1.6s): `assets/atlas-progress.png` arrive à droite dans un iPhone recadré, ~58% de la hauteur ; à gauche, « tout le sport » se révèle en display blanc, layout 50/50 à trois couches, short-path assemble (`center-outward-expansion`).
Scene 2 (1.6–3.0s): première ligne éditoriale : « records + 1RM estimé » avec slash bleu ; list-line assemble direct-to-slot (`center-outward-expansion`), capture toujours nette.
Scene 3 (3.0–4.4s): deuxième ligne : « calendrier multisport » ; la ligne précédente reste co-résidente, hairline supérieur se dessine (`svg-path-draw`).
Scene 4 (4.4–5.8s): troisième ligne : « Apple Santé » ; révélation dans le même rythme, aucun dégradé ni icône inventée.
Scene 5 (5.8–7.1s): quatrième ligne : « nutrition » ; le stack complet forme une colonne dense mais hiérarchisée, dernier item en bleu.
Scene 6 (7.1–8.0s): payoff « au même endroit. sur l’iPhone. » remplace le kicker au-dessus de la liste (`discrete-text-sequence`) ; hold statique, sans respiration.

## Frame 5 — Fabriqué avec transparence

- scene: Sur fond noir, les mots « IA utilisée » frappent l’écran, puis « GPT-5.6 Sol » prend toute la largeur ; le sceau « Open source · MIT » verrouille le cadre.
- duration: 7s
- transition_in: zoom-through
- status: animated
- src: compositions/frames/05-transparence.html
- type: branding
- persuasion: Trust through transparency
- beat: trust + confidence
- blueprint: kinetic-type-beats (Reproduce · multi-beat statement)
- asset_candidates:

narrativeRole: Donner le crédit demandé à l’IA et préciser clairement la licence du projet.
keyMessage: ATLAS et cette vidéo ont été réalisés avec l’aide de GPT-5.6 Sol ; le projet est open source sous licence MIT.

Scene 1 (0.0–1.5s): « IA utilisée » frappe au centre en display blanc avec un kicker mono « TRANSPARENCE » bleu ; kinetic beat-slam (`kinetic-beat-slam`) sur registre sombre, composition centrée occupant ~70% de la largeur.
Scene 2 (1.5–4.7s): « GPT-5.6 SOL » remplace la phrase par hard-cut et remplit presque toute la largeur ; « 5.6 SOL » devient bleu sur son propre beat, puis tient immobile pour la lecture.
Scene 3 (4.7–5.9s): une rule bleue traverse le tiers inférieur et le label « AIDE À LA RÉALISATION DU PROJET + DE CETTE VIDÉO » se révèle en mono, sans suggérer une fonction IA dans l’app.
Scene 4 (5.9–7.0s): « OPEN SOURCE · MIT » arrive sous la rule en blanc et verrouille le cadre ; hold net, aucune animation de sortie interne.

## Frame 6 — Un portfolio ouvert

- scene: ATLAS reste l’ancre ; Predictions-Foot et Lower-Back-Pain-Prediction s’assemblent comme deux projets satellites, chacun marqué « GPT-5.5 utilisé », puis l’URL GitHub conclut.
- duration: 9s
- transition_in: crossfade
- status: animated
- src: compositions/frames/06-portfolio.html
- type: cta
- persuasion: Authority by demonstrated breadth
- beat: confidence + invitation
- blueprint: grid-card-assemble (Adapt · field-to-payoff)
- asset_candidates:

narrativeRole: Relier ATLAS aux autres projets demandés et inviter à explorer le code source.
keyMessage: Le portfolio est public sur github.com/albangerschheimer ; Predictions-Foot et Lower-Back-Pain-Prediction ont utilisé GPT-5.5.

Adapt: garder l’assemblage de projets puis le clear-to-payoff ; utiliser deux panneaux rectilignes à hairline, sans logos redessinés.
Scene 1 (0.0–1.5s): « un portfolio ouvert » entre en display blanc, ancré haut-gauche ; le label mono « ATLAS · OPEN SOURCE » se place au-dessus, line-by-line headline fill (`discrete-text-sequence`).
Scene 2 (1.5–3.7s): panneau gauche Predictions-Foot s’assemble directement dans son slot, avec URL courte et badge typographique bleu « GPT-5.5 UTILISÉ » ; direct-to-slot assemble (`center-outward-expansion`), split-screen sans arrondis.
Scene 3 (3.7–5.8s): panneau droit Lower-Back-Pain-Prediction s’assemble en miroir avec le même badge « GPT-5.5 UTILISÉ » ; la paire tient sous le titre, hairline central comme seul séparateur.
Scene 4 (5.8–6.6s): les deux panneaux glissent vers le haut et s’effacent en cut-the-curve, laissant le champ noir ; le titre se réduit vers son kicker, seam interne velocity-matched (`cut-catalog.md`).
Scene 5 (6.6–9.0s): `github.com/albangerschheimer` se révèle de gauche à droite en display blanc, « explore le code » en bleu au-dessus ; l’URL est le plus long hold du plan, sans drift ni fade final.

# ATLAS Design System

## Direction

ATLAS est une interface d’entraînement calme, précise et native iOS. La structure reste monochrome afin que les chiffres et les actions soient lisibles pendant l’effort. L’indigo ATLAS identifie les actions principales. Les couleurs de muscles et de sports portent uniquement une signification, jamais une décoration.

## Hiérarchie

- Une action d’entraînement principale maximum par écran.
- Aucune phrase d’ambiance : un écran n’explique que ce qui change la prochaine action.
- Une carte qui mène ailleurs est elle-même le lien; on n’ajoute pas de phrase indiquant où aller.
- Les grands titres donnent le contexte; les petites capitales identifient la section ATLAS.
- Les cartes regroupent une seule idée. Elles utilisent une surface système, un contour léger et aucun effet « gaming ».
- Les informations secondaires restent en `secondary`; les erreurs importantes utilisent la couleur danger.
- Une absence de donnée explique la prochaine action possible sans afficher un score artificiel.

## Tokens

- `AtlasTheme.canvas`: arrière-plan général adaptatif clair/sombre.
- `AtlasTheme.surface`: surface des cartes et métriques.
- `AtlasTheme.elevatedSurface`: contenu mis au premier plan.
- `AtlasTheme.accent`: action ATLAS.
- `success`, `warning`, `danger`: états sémantiques.
- `screenPadding`, `sectionSpacing`, `cardCornerRadius`, `compactCornerRadius`: rythme commun.

Les composants partagés sont `AtlasCard`, `MetricTile`, `AtlasSectionHeader`, `AtlasIconBadge`, `AtlasStatusPill` et `AtlasPrimaryButtonStyle`. Les états vides utilisent directement `ContentUnavailableView`, sans surcouche ATLAS.

## Couleurs musculaires

`MuscleGroup.atlasColor` est l’unique source de vérité. Une zone conserve sa couleur dans la bibliothèque, la fiche exercice, les graphiques, le calendrier, la fatigue et le volume hebdomadaire. Un muscle secondaire utilise la même couleur avec une opacité plus faible.

## États et accessibilité

- Light Mode et Dark Mode utilisent les couleurs système; aucune couleur de texte n’est codée en noir ou blanc hors boutons contrastés.
- Dynamic Type doit pouvoir agrandir les libellés sans masquer l’action principale.
- Les éléments colorés conservent un libellé, une icône ou une valeur afin que la couleur ne soit jamais le seul signal.
- Les animations sont brèves et décoratives. `Reduce Motion` doit supprimer les transitions non indispensables.
- En séance, les contrôles de saisie, le timer et la validation restent prioritaires sur la navigation.

## Écrans principaux

- **Jour** : action de séance, connexion Santé si absente, récupération (disponibilité et signaux dans une seule carte), semaine, coach et nutrition.
- **Séance** : démarrer/reprendre, bibliothèque, programmes et historique.
- **Calendrier** : semaine, répartition musculaire et activités ATLAS/Santé dédupliquées.
- **Progrès** : vue d’ensemble, mesures corporelles, records et tendances.
- **Profil** : données locales, nutrition, intégrations, confidentialité et version.


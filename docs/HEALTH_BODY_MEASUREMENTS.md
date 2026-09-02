# Apple Health body-measurement synchronization

Reviewed 1 September 2026.

ATLAS requests read access to four discrete HealthKit quantity types used by common connected scales: body mass, body-fat percentage, lean body mass and body-mass index. It imports the full readable history into Progress → Measurements, keeps the HealthKit sample date and source name, and prevents duplicate metric/date/value rows.

HealthKit stores percentages between 0 and 1, so ATLAS multiplies body-fat values by 100 for display. Proprietary metrics such as metabolic age, visceral-fat score, Boditrax score, protein score or cellular integrity have no standard HealthKit counterpart and therefore remain manual unless Apple or the scale vendor later exposes a documented type.

Apple deliberately prevents apps from distinguishing a denied read permission from an empty dataset. Therefore “no compatible measurement accessible” can mean the scale has not written the type, the user granted only limited history, synchronization has not completed, or read access is disabled. The UI points to Santé → Partage → Apps → ATLAS instead of claiming a permission was denied.

Primary references:

- [Apple: Body mass index and related body measurements](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/bodymassindex)
- [Apple: Body-fat percentage](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/bodyfatpercentage)
- [Apple: Reading data from HealthKit](https://developer.apple.com/documentation/healthkit/reading-data-from-healthkit)
- [Apple: Authorizing access to health data](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)

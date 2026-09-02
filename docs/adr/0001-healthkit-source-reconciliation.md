# Reconcile health sources without direct Foodvisor or Strava accounts

ATLAS reads Foodvisor and Strava data through Apple Health instead of adding vendor accounts, then reconciles equivalent source activities into one canonical activity. This preserves the local-first permission boundary and avoids double-counting while retaining every contributing source; a direct vendor integration remains possible later behind `HealthDataProvider` if HealthKit omits data that produces visible user value.

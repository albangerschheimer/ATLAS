# ATLAS Sports OS

ATLAS unifies training, recovery and nutrition without confusing a real-world event with the records produced by external applications.

## Activity

**Source activity**:
An activity record supplied by Apple Health, Strava, Mi Fitness or ATLAS.
_Avoid_: Imported workout, raw workout

**Canonical activity**:
The single real-world effort shown and counted by ATLAS after equivalent source activities have been reconciled.
_Avoid_: Workout when the distinction from a source activity matters

**Duplicate activity**:
A source activity representing the same real-world effort as another source activity, based on sport, time, duration and available distance.
_Avoid_: Identical activity

## Nutrition

**Nutrition entry**:
A local ATLAS record of food and its consumed energy and macronutrients at a given time.
_Avoid_: Meal when one entry may represent only part of a meal

**Nutrition sample**:
A nutrition value supplied by Apple Health, potentially written by Foodvisor or another source.
_Avoid_: Foodvisor entry

**Nutrition goal**:
The user’s configurable daily target for energy or a macronutrient.
_Avoid_: Limit, prescription

## Recovery

**Readiness score**:
An estimate built from the recovery signals currently available to ATLAS. Resting heart rate and its baseline are required; sleep is an optional signal that can refine the score, while confidence communicates signal coverage.
_Avoid_: Medical diagnosis, sleep score

## Body measurements

**Body measurement**:
A dated value for one body or body-composition metric, entered by the user or supplied by a named source. Measurements from different dates form an evolution series.
_Avoid_: Scale profile, current body state

## Exercise media

**Exercise media**:
An optional, sourced visual demonstration associated with an exercise through a provider. It is not part of the exercise’s core identity and may be absent offline.
_Avoid_: Exercise video when the media can be a GIF or image

**Personal record**:
The best deterministic performance ATLAS derives from completed working sets for one exercise, such as heaviest load, best repetitions or estimated one-repetition maximum.
_Avoid_: Achievement

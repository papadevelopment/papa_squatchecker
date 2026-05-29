
# 🚗 PAPA DEVELOPMENT 🚗

### papa_squatchecker

A FiveM vehicle suspension measuring script using **ox_lib**, **ox_target**, and **okokNotify**.

=

---

## 📌 Description

`papa_squatchecker` is a FiveM resource that allows authorized players to measure a vehicle’s front and rear suspension stance.

When a player targets a vehicle using **ox_target**, they will see an option called:

Measure suspension

The script plays a measuring animation, calculates the front and rear suspension height difference in inches, and warns the user if the vehicle exceeds the allowed squat limit.

---

## ⚠️ Warning System

If the front and rear suspension difference is more than the configured amount, the player will receive this warning using **okokNotify**:

WARNING: Illigial squat (exceeds 4inch difference)

---

## ✅ Features

- Works on all vehicles
- Uses ox_target vehicle targeting
- Uses ox_lib progress circle and animation
- Uses okokNotify notifications
- Configurable job restrictions
- Supports multiple allowed jobs
- Configurable legal squat limit
- Clean and simple resource structure

---

## 📁 Resource Name

papa_squatchecker

---

## 📦 Dependencies

Make sure these resources are installed and started before this script:

```cfg
ensure ox_lib
ensure ox_target
ensure okokNotify
ensure papa_squatchecker

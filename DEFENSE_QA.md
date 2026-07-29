# 🎓 FoodGapp Capstone Defense: Q&A Strategy Guide

This document prepares the proponents for technical and functional questioning by the panel. It bridges the gap between the initial capstone paper and the current "Gold Master" state of the application.

---

## 🏛️ Tier 1: Architecture & Reliability

**Q: Your paper mentions a "3-Layer Architecture." How is this implemented in the code?**
> [!NOTE]
> **Answer**: We strictly follow the **Presentation**, **Application Logic**, and **Data** layers.
> 1. **Presentation**: Built with Flutter, using a "Liquid Glass" design system for high-density information display.
> 2. **Logic**: Services like `MealGenerationService` and `ShoppingListService` act as the brain, orchestrating data between the UI and APIs.
> 3. **Data**: We use a **v25 Self-Healing SQLite schema**. This layer is unique because it combines a massive 50,000-item local library (Titan Engine) with cloud-based caching.

**Q: What do you mean by a "Self-Healing Database"?**
> [!IMPORTANT]
> **Answer**: During development, we identified that mobile databases can sometimes suffer from schema corruption or missing tables during updates. We implemented an **Aggressive Structural Audit** in our `DatabaseHelper`. On every startup, the app scans its own internal tables. If a critical table (like `shopping_list`) is missing, the app **automatically recreates it** in milliseconds, ensuring 100% operational uptime without user intervention.

**Q: Why did you choose SQLite over a Cloud Database like Firestore for user data?**
> [!TIP]
> **Answer**: Privacy and Speed. By using an **Offline-First SQLite** approach, we ensure that sensitive user health data never leaves the device unless necessary for AI processing. This also allows for **Sub-10ms search speeds** through our 50,000-item local library, which would be impossible with cloud-only storage.

---

## 🧠 Tier 2: FoodGapp AI & Accuracy

**Q: How is "FoodGapp AI" different from just a simple chat interface?**
> [!NOTE]
> **Answer**: FoodGapp AI is an **Orchestrator**, not just a chatbot. It follows a **Strict JSON Protocol**. Instead of free-form text, we force the AI to return structured data that our app can parse into mathematical macros. We also implemented a **Mathematical Self-Audit**: when the AI generates a plan, our system verifies that the 3 meals hit the calorie target exactly and follow the **25/35/40 clinical split** (Breakfast/Lunch/Dinner).

**Q: How do you handle AI "hallucinations" or formatting errors?**
> [!CAUTION]
> **Answer**: We implemented a multi-layered defense:
> 1. **Prompt Hardening**: We use "CRITICAL JSON RULES" in our AI instructions to forbid illegal characters.
> 2. **Sanitization Layer**: Our `_sanitizeJson` method uses Regular Expressions to clean the AI's response before the app attempts to read it.
> 3. **Clinical Fallback**: If the AI fails, our **5-Layer Gateway** automatically falls back to verified clinical databases like Spoonacular or the local Titan library.

**Q: How does the app stay relevant to the Philippine context?**
> [!NOTE]
> **Answer**: We integrated the official **PhilFCT (Philippine Food Composition Tables)** by **DOST-FNRI** into our local Titan library. This means that when a user logs a local staple like *Adobo* or *Sinigang*, they are getting laboratory-verified data specific to Filipino ingredients, rather than Western estimates.

---

## 🇵🇭 Tier 3: Scientific Foundation (DOST-FNRI)

**Q: How are the DOST-FNRI guidelines integrated into your calculations?**
> [!IMPORTANT]
> **Answer**: Our **`NutritionFeedbackService`** is built directly on the **2015 PDRI (Philippine Dietary Reference Intakes)**. We use the **Mifflin-St Jeor equation** adjusted by FNRI-specific **Physical Activity Level (PAL)** factors (1.2 for Sedentary to 1.9 for Extra Active). This ensures that every recommendation is scientifically tailored to the user's specific physiology.

**Q: You mention "RENI" in your paper. How is it displayed in the app?**
> [!NOTE]
> **Answer**: In the **Nutrition Dashboard**, we compare the user's actual intake against their calculated targets. We use the **Pinggang Pinoy** philosophy—visualizing the balance between "Go, Grow, and Glow" foods via our macro progress rings and real-time feedback messages.

---

## 📱 Tier 4: Cross-Platform & DevOps

**Q: How did you manage to build and test an iOS version without owning a Mac?**
> [!TIP]
> **Answer**: We implemented a professional **DevOps CI/CD pipeline** using **GitHub Actions**. By utilizing cloud-based macOS virtual machines, we compiled a native iOS binary (`.ipa`) directly from our repository. We used **GitHub Secrets** to securely inject our API keys during the build, ensuring a production-grade deployment without needing physical hardware.

**Q: How do you ensure the app looks professional on different screen sizes?**
> [!NOTE]
> **Answer**: We adopted a **High-Density Compact Layout** standard. We minimized vertical margins and optimized font scales to ensure that complex data—like a 7-day meal plan or a 50-item search result—remains legible and "one-thumb reachable" on both standard Android phones and high-end devices like the iPhone 16e.

---

## 🚀 Tier 5: The "Titan" Engine

**Q: 50,000 items is a lot for a mobile app. Doesn't that make it slow?**
> [!IMPORTANT]
> **Answer**: No, because we use **Binary Database Bundling**. We pre-index the entire encyclopedia into a optimized SQLite binary. On first launch, the app performs a high-speed copy of this binary. Searches use **Keyword Intersection logic**, which allows us to find complex items (like *"Mang Inasal PM2"*) in less than 10 milliseconds entirely offline.

---
*FoodGapp Final Capstone Defense — Prepared by the Proponents*

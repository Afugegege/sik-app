# 식 (sik)

a korean minimalist cooking app and kitchen intelligence engine built with flutter.

designed for people who care about how their everyday tools look and feel. soft warm tones, calm layouts, and zero visual noise. it turns whatever is sitting in your fridge into dinner, modifies recipes on the fly, and stays out of your way while you cook.

---

### why

most cooking apps feel like recipe blogs from 2011 wrapped in banner ads, stock photos, and ten paragraphs of backstory before you even see the ingredients.

sik is built around a simpler premise: you already have ingredients in your fridge, you have specific appliances, and you just want to know what you can make right now without an extra grocery trip.

### what's inside

- discovery feed: visual recipe feed filtered by kitchen match percentage, prep time, and appliances (air fryer, stovetop, oven, microwave, no-cook).
- fridge & pantry inventory: track ingredients, approximate quantities, and expiry status with dynamic matching against recipes.
- ai recipe modification: swap missing ingredients, simplify steps, adjust servings, or convert cooking methods on the fly.
- cook mode: clean step-by-step cooking view with integrated timers to keep you focused.
- want list: automatically collects missing items from recipes you plan to make.

### stack

- framework: flutter (dart 3)
- state: provider
- typography & design: google fonts (plus jakarta sans), custom ceramic theme
- storage: shared preferences
- ai: openai api

### run locally

prerequisites: flutter sdk (3.10+) and dart.

1. clone the repo:
```bash
git clone https://github.com/Afugegege/sik-app.git
cd sik-app
```

2. install dependencies:
```bash
flutter pub get
```

3. configure environment:
copy `.env.example` to `.env` and add your api key:
```env
OPENAI_API_KEY=your_openai_api_key
```

4. launch:
```bash
flutter run
```

---

license: mit

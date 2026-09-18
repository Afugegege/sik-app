# sik (식)

a quiet kitchen companion built with flutter.

made because i wanted an app for cooking that feels calm, looks good, and actually uses what's already sitting in my fridge. no walls of blog text or popups — just ingredients, match percentages, and simple recipe tweaks.

---

### features

- **fridge matching**: track what you have and see recipes you can make right now
- **recipe tweaks**: adjust servings, swap ingredients you don't have, or convert cooking methods
- **cook mode**: clean step-by-step view with built-in timers
- **shopping list**: quick capture for missing ingredients

### stack

- flutter & dart
- provider for state
- openai api for recipe adjustments
- shared_preferences for local storage

### setup

prerequisites: flutter sdk (3.10+)

1. clone the repo
```bash
git clone https://github.com/Afugegege/sik-app.git
cd sik-app
```

2. get dependencies
```bash
flutter pub get
```

3. configure api key
copy `.env.example` to `.env`:
```env
OPENAI_API_KEY=your_openai_api_key
```

4. run
```bash
flutter run
```

---

license: mit

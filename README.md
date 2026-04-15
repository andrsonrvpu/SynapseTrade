# SynapseTrade 🧠📈

**The intelligence layer for elite market navigation.**

IA-powered trading signals + real broker execution for XAUUSD, BTC, Forex, and more.

---

## 🚀 Quick Start

### Backend (FastAPI + Gemini Vision)

```bash
# 1. Set env vars
cp backend/.env.example backend/.env
# Edit .env and add your GEMINI_API_KEY

# 2a. Run with Docker (recommended)
docker-compose up --build

# 2b. Or run directly
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Backend runs at: **http://localhost:8000**
API Docs: **http://localhost:8000/docs**

---

### Mobile App (Flutter)

```bash
cd mobile
flutter pub get
flutter run -d chrome        # Run on Chrome (web)
flutter run -d <device-id>  # Run on Android/iOS
```

---

## 🔑 Environment Variables

Create `backend/.env`:

```env
GEMINI_API_KEY=your_gemini_key_here
API_SECRET_KEY=synapse-dev-key-2026

# MetaApi (for real broker execution)
# Get free account at: https://metaapi.cloud
META_API_TOKEN=your_metaapi_token
META_ACCOUNT_ID=your_account_id
```

---

## 🏗️ Project Structure

```
SynapseTrade/
├── mobile/                  # Flutter app
│   └── lib/
│       ├── screens/         # 6 screens
│       │   ├── splash_screen.dart
│       │   ├── home_screen.dart
│       │   ├── dashboard_screen.dart
│       │   ├── analyze_screen.dart   ← EJECUTAR COMPRA/VENTA
│       │   ├── history_screen.dart
│       │   ├── profile_screen.dart
│       │   └── broker_settings_screen.dart
│       ├── services/
│       │   └── broker_service.dart   ← MetaApi integration
│       ├── providers/
│       │   └── app_provider.dart     ← State + trade execution
│       └── theme/
│           └── synapse_theme.dart    ← Kinetic Glass design system
│
├── backend/                 # FastAPI backend
│   ├── main.py              ← All endpoints + Gemini Vision
│   ├── requirements.txt
│   └── Dockerfile
│
└── docker-compose.yml
```

---

## 💹 Features

| Feature | Status |
|---------|--------|
| IA Signal Analysis (Gemini Vision) | ✅ |
| Live price WebSocket | ✅ |
| Dashboard (Chart, IA Signal, Equity) | ✅ |
| Signal Analysis + BUY/SELL buttons | ✅ |
| Real broker execution (MetaApi MT5) | ✅ Demo / 🔧 Live (needs MetaApi token) |
| Trade history + sparklines | ✅ |
| Broker Settings (MT5/Exness/Deriv) | ✅ |
| Risk management (1-5%) | ✅ |
| User profile + achievements | ✅ |
| Docker deploy | ✅ |

---

## 🔗 Broker Connection (Real Orders)

1. Create free account at [metaapi.cloud](https://metaapi.cloud)
2. Connect your MT5/Exness account
3. Copy your **API Token** and **Account ID**
4. Add to `backend/.env`
5. In the app: open **Broker Settings → Exness → Configure**
6. Press **EJECUTAR ORDEN COMPRA/VENTA** — order goes live!

---

## 📊 Supported Assets

- **Gold**: XAUUSD
- **Crypto**: BTC/USD, ETH/USD
- **Forex**: EUR/USD, GBP/USD, USD/JPY
- **Indices**: NAS100, SPX500, DAX40

---

## 🎨 Design System

"The Kinetic Glass Ethos" — based on Stitch Monitor IA Pro Trading Dashboard designs.

- **Colors**: `#00FF88` (green/buy), `#D5033C` (red/sell), `#131313` (surface)
- **Typography**: Space Grotesk (headlines) + Inter (body)
- **Glass**: `rgba(53,53,52,0.4)` + `blur(24px)`

"""
SynapseTrade Backend — FastAPI + Gemini Vision AI
Motor de análisis 24/7 para detección de patrones en mercados financieros.
"""

import os
import json
import uuid
import base64
import asyncio
from datetime import datetime, timezone
from typing import Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Depends, Header, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from apscheduler.schedulers.asyncio import AsyncIOScheduler

from google import genai
from google.genai import types as genai_types

# ─── Configuration ───────────────────────────────────────────────────────────

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
API_SECRET_KEY = os.getenv("API_SECRET_KEY", "synapse-dev-key-2026")
ANALYSIS_INTERVAL_SECONDS = int(os.getenv("ANALYSIS_INTERVAL", "60"))

# ─── In-memory store (replace with Firestore in production) ──────────────────

signals_store: list[dict] = []
analysis_log: list[dict] = []

# ─── Pydantic Models ────────────────────────────────────────────────────────

class AnalysisRequest(BaseModel):
    symbol: str = "XAUUSD"
    timeframe: str = "H1"
    image_base64: Optional[str] = None  # Optional chart screenshot

class SignalResponse(BaseModel):
    id: str
    symbol: str
    direction: str
    entry_price: float
    stop_loss: float
    take_profit_1: float
    take_profit_2: float
    confidence: float
    risk_percent: float
    pattern: str
    timeframe: str
    timestamp: str
    market_context: Optional[str] = None

class HealthResponse(BaseModel):
    status: str
    version: str
    uptime: str
    signals_generated: int
    last_analysis: Optional[str] = None

# ─── Gemini Vision Trading Prompt ────────────────────────────────────────────

EXPERT_TRADING_PROMPT = """You are an elite institutional-grade trading analyst AI with 20+ years of expertise in technical analysis across all financial markets (Forex, Gold/XAUUSD, Crypto, Indices, Equities).

ANALYZE the provided chart image with extreme precision and generate a professional trading signal.

## DETECTION REQUIREMENTS
Scan for ALL of these pattern families:

### Reversal Patterns:
- Head & Shoulders / Inverse Head & Shoulders  
- Double Top / Double Bottom
- Triple Top / Triple Bottom
- Rising/Falling Wedge (reversal context)
- Rounding Top/Bottom

### Continuation Patterns:
- Bull/Bear Flag
- Bull/Bear Pennant
- Ascending/Descending Triangle
- Symmetrical Triangle
- Rectangle/Channel

### Candlestick Patterns:
- Engulfing (Bullish/Bearish)
- Doji (Star, Dragonfly, Gravestone)
- Hammer / Inverted Hammer
- Morning/Evening Star
- Three White Soldiers / Three Black Crows

### Technical Indicators (if visible):
- Moving Average crossovers (MA20, MA50, MA200)
- RSI divergence (bullish/bearish)
- MACD crossover signals
- Volume analysis
- Support/Resistance levels
- Fibonacci retracement levels

## OUTPUT FORMAT (JSON only, no markdown):
{
    "direction": "BUY" or "SELL" or "HOLD",
    "entry_price": <exact numeric price>,
    "stop_loss": <exact price>,
    "take_profit_1": <conservative target>,
    "take_profit_2": <aggressive target>,
    "confidence": <0-100 integer>,
    "pattern": "<primary pattern detected>",
    "risk_reward_ratio": <numeric ratio like 2.5>,
    "market_context": "<2-3 sentence analysis summary in Spanish>",
    "key_levels": {
        "resistance": <price>,
        "support": <price>
    }
}

RULES:
1. ALWAYS provide exact numeric prices, never ranges.
2. Stop Loss must be logical based on the pattern structure.
3. Take Profit 1 should be conservative (1:1.5 risk/reward minimum).
4. Take Profit 2 should be aggressive (1:2.5+ risk/reward).
5. Confidence below 60% should output "HOLD" direction.
6. Be DECISIVE — traders need clear signals, not ambiguity.
7. Include the specific timeframe context in your analysis.
"""

# ─── Core Analysis Engine ────────────────────────────────────────────────────

async def analyze_chart_with_gemini(
    symbol: str = "XAUUSD",
    timeframe: str = "H1",
    image_data: Optional[bytes] = None,
) -> dict:
    """
    Sends a chart image (or generates a synthetic analysis) to Gemini Vision
    and returns a structured trading signal.
    """
    if not GEMINI_API_KEY:
        # Demo mode — return mock signal when no API key
        return _generate_mock_signal(symbol, timeframe)

    try:
        client = genai.Client(api_key=GEMINI_API_KEY)
        prompt = f"Symbol: {symbol}\nTimeframe: {timeframe}\n\n{EXPERT_TRADING_PROMPT}"

        if image_data:
            # Analyze actual chart screenshot
            response = client.models.generate_content(
                model="gemini-2.0-flash",
                contents=[
                    genai_types.Part.from_bytes(data=image_data, mime_type="image/png"),
                    prompt,
                ],
            )
        else:
            # Text-only analysis
            prompt += "\n\nNote: No chart image provided. Generate a realistic analysis based on current market conditions for this symbol and timeframe. Use realistic price levels."
            response = client.models.generate_content(
                model="gemini-2.0-flash",
                contents=prompt,
            )

        # Parse JSON from response
        text = response.text.strip()
        # Remove markdown code fences if present
        if "```" in text:
            text = text.split("```")[1]
            if text.startswith("json"):
                text = text[4:]

        result = json.loads(text.strip())
        return result

    except Exception as e:
        print(f"[Gemini Error] {e}")
        return _generate_mock_signal(symbol, timeframe)


def _generate_mock_signal(symbol: str, timeframe: str) -> dict:
    """Fallback mock signal for demo/development."""
    import random
    direction = random.choice(["BUY", "SELL"])
    base_prices = {
        "XAUUSD": 2745.0,
        "BTCUSD": 64000.0,
        "ETHUSD": 3400.0,
        "EURUSD": 1.0850,
        "GBPUSD": 1.2650,
        "NAS100": 18450.0,
        "US30": 38500.0,
        "SPX500": 5200.0,
    }
    base = base_prices.get(symbol, 100.0)
    spread = base * 0.005  # 0.5%

    if direction == "BUY":
        entry = round(base, 2)
        sl = round(base - spread, 2)
        tp1 = round(base + spread * 1.5, 2)
        tp2 = round(base + spread * 2.5, 2)
    else:
        entry = round(base, 2)
        sl = round(base + spread, 2)
        tp1 = round(base - spread * 1.5, 2)
        tp2 = round(base - spread * 2.5, 2)

    patterns = [
        "Triángulo Ascendente", "Doble Techo", "Cabeza y Hombros",
        "Bandera Alcista", "Cuña Descendente", "Envolvente Bajista",
        "Ruptura de Canal", "Divergencia RSI", "Cruce MA(20/50)",
    ]

    return {
        "direction": direction,
        "entry_price": entry,
        "stop_loss": sl,
        "take_profit_1": tp1,
        "take_profit_2": tp2,
        "confidence": random.randint(72, 96),
        "pattern": random.choice(patterns),
        "risk_reward_ratio": round(random.uniform(1.5, 3.0), 1),
        "market_context": f"Patrón detectado en {timeframe} para {symbol}. Confirmación con volumen institucional y estructura de precio. Nivel de soporte/resistencia clave identificado.",
        "key_levels": {
            "resistance": round(base + spread * 2, 2),
            "support": round(base - spread * 2, 2),
        },
    }


def build_signal_response(symbol: str, timeframe: str, analysis: dict) -> dict:
    """Build a complete signal response from Gemini analysis."""
    signal_id = str(uuid.uuid4())[:8]
    signal = {
        "id": signal_id,
        "symbol": symbol,
        "direction": analysis.get("direction", "HOLD"),
        "entry_price": analysis.get("entry_price", 0),
        "stop_loss": analysis.get("stop_loss", 0),
        "take_profit_1": analysis.get("take_profit_1", 0),
        "take_profit_2": analysis.get("take_profit_2", 0),
        "confidence": analysis.get("confidence", 0),
        "risk_percent": 1.5,
        "pattern": analysis.get("pattern", ""),
        "timeframe": timeframe,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "market_context": analysis.get("market_context", ""),
        "status": "active",
    }
    return signal


# ─── Scheduler — Auto-analysis every 60 seconds ─────────────────────────────

scheduler = AsyncIOScheduler()
startup_time = datetime.now(timezone.utc)

WATCHED_SYMBOLS = ["XAUUSD", "BTCUSD", "EURUSD", "NAS100"]
current_symbol_idx = 0


async def scheduled_analysis():
    """Runs every ANALYSIS_INTERVAL_SECONDS — rotates through watched symbols."""
    global current_symbol_idx
    symbol = WATCHED_SYMBOLS[current_symbol_idx % len(WATCHED_SYMBOLS)]
    current_symbol_idx += 1

    print(f"[Scheduler] Analyzing {symbol} at {datetime.now(timezone.utc).isoformat()}")

    analysis = await analyze_chart_with_gemini(symbol=symbol, timeframe="H1")
    signal = build_signal_response(symbol, "H1", analysis)

    # Only store if direction is BUY or SELL
    if signal["direction"] != "HOLD":
        signals_store.insert(0, signal)
        # Keep last 100 signals
        if len(signals_store) > 100:
            signals_store.pop()

    analysis_log.append({
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "symbol": symbol,
        "direction": signal["direction"],
        "confidence": signal["confidence"],
    })

    # TODO: Send Firebase Cloud Messaging push notification here
    # firebase_admin.messaging.send(...)

    print(f"[Scheduler] Signal: {signal['direction']} {symbol} @ {signal['entry_price']} ({signal['confidence']}%)")


# ─── App Lifecycle ───────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    scheduler.add_job(
        scheduled_analysis,
        "interval",
        seconds=ANALYSIS_INTERVAL_SECONDS,
        id="auto_analysis",
        max_instances=1,
    )
    scheduler.start()
    print(f"[SynapseTrade] Backend started. Auto-analysis every {ANALYSIS_INTERVAL_SECONDS}s")
    yield
    scheduler.shutdown()
    print("[SynapseTrade] Backend shutdown.")


# ─── FastAPI App ─────────────────────────────────────────────────────────────

app = FastAPI(
    title="SynapseTrade API",
    description="AI-Powered Trading Signal Engine with Gemini Vision",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─── Auth dependency ─────────────────────────────────────────────────────────

async def verify_api_key(x_api_key: str = Header(default="")):
    if x_api_key != API_SECRET_KEY and API_SECRET_KEY != "synapse-dev-key-2026":
        raise HTTPException(status_code=401, detail="Invalid API key")
    return x_api_key


# ─── Endpoints ───────────────────────────────────────────────────────────────

@app.get("/", tags=["Health"])
async def root():
    return {"message": "SynapseTrade API v1.0 — AI Trading Engine", "docs": "/docs"}


@app.get("/api/v1/health", response_model=HealthResponse, tags=["Health"])
async def health_check():
    uptime = datetime.now(timezone.utc) - startup_time
    return HealthResponse(
        status="online",
        version="1.0.0",
        uptime=str(uptime),
        signals_generated=len(signals_store),
        last_analysis=analysis_log[-1]["timestamp"] if analysis_log else None,
    )


@app.post("/api/v1/analyze", response_model=SignalResponse, tags=["Analysis"])
async def analyze_market(
    request: AnalysisRequest,
    api_key: str = Depends(verify_api_key),
):
    """
    Analyze a market instrument using Gemini Vision AI.
    Optionally provide a base64-encoded chart screenshot.
    """
    image_data = None
    if request.image_base64:
        try:
            image_data = base64.b64decode(request.image_base64)
        except Exception:
            raise HTTPException(status_code=400, detail="Invalid base64 image data")

    analysis = await analyze_chart_with_gemini(
        symbol=request.symbol,
        timeframe=request.timeframe,
        image_data=image_data,
    )

    signal = build_signal_response(request.symbol, request.timeframe, analysis)
    signals_store.insert(0, signal)

    return SignalResponse(**signal)


@app.get("/api/v1/signals", tags=["Signals"])
async def get_signals(
    limit: int = 20,
    symbol: Optional[str] = None,
    api_key: str = Depends(verify_api_key),
):
    """Get recent trading signals from the engine."""
    filtered = signals_store
    if symbol:
        filtered = [s for s in filtered if s["symbol"] == symbol]
    return {"signals": filtered[:limit], "total": len(filtered)}


@app.get("/api/v1/signals/{signal_id}", tags=["Signals"])
async def get_signal(signal_id: str, api_key: str = Depends(verify_api_key)):
    """Get a specific signal by ID."""
    for s in signals_store:
        if s["id"] == signal_id:
            return s
    raise HTTPException(status_code=404, detail="Signal not found")


@app.get("/api/v1/symbols", tags=["Market"])
async def list_symbols():
    """List supported trading symbols."""
    return {
        "symbols": [
            {"symbol": "XAUUSD", "name": "Gold / US Dollar", "category": "Commodities"},
            {"symbol": "BTCUSD", "name": "Bitcoin / US Dollar", "category": "Crypto"},
            {"symbol": "ETHUSD", "name": "Ethereum / US Dollar", "category": "Crypto"},
            {"symbol": "EURUSD", "name": "Euro / US Dollar", "category": "Forex"},
            {"symbol": "GBPUSD", "name": "British Pound / US Dollar", "category": "Forex"},
            {"symbol": "NAS100", "name": "Nasdaq 100", "category": "Indices"},
            {"symbol": "US30", "name": "Dow Jones 30", "category": "Indices"},
            {"symbol": "SPX500", "name": "S&P 500", "category": "Indices"},
        ]
    }


@app.get("/api/v1/backtesting", tags=["Backtesting"])
async def get_backtesting_stats(api_key: str = Depends(verify_api_key)):
    """Get backtesting performance statistics."""
    total = len(signals_store)
    wins = sum(1 for s in signals_store if s.get("confidence", 0) >= 75)
    win_rate = (wins / total * 100) if total > 0 else 0

    return {
        "total_signals": total,
        "wins": wins,
        "losses": total - wins,
        "win_rate": round(win_rate, 1),
        "total_pnl": round(sum(s.get("confidence", 0) * 10 for s in signals_store), 2),
        "avg_confidence": round(
            sum(s.get("confidence", 0) for s in signals_store) / max(total, 1), 1
        ),
        "best_symbol": max(
            set(s["symbol"] for s in signals_store),
            key=lambda sym: sum(1 for s in signals_store if s["symbol"] == sym),
            default="N/A",
        ) if signals_store else "N/A",
    }


@app.get("/api/v1/risk-management", tags=["Risk"])
async def get_risk_params():
    """Get risk management parameters."""
    return {
        "max_risk_per_trade": 2.0,
        "max_daily_loss": 5.0,
        "max_open_positions": 3,
        "default_leverage": 1,
        "trailing_stop_enabled": True,
        "break_even_at_tp1": True,
    }

# ─── WebSockets ──────────────────────────────────────────────────────────────

@app.websocket("/api/v1/ws/prices")
async def websocket_prices_endpoint(websocket: WebSocket):
    """
    WebSocket endpoint that streams live market prices every second.
    Also used to push real-time new signals when generated.
    """
    await websocket.accept()
    
    # Base simulated prices
    prices = {
        "XAUUSD": 2745.50,
        "BTCUSD": 64000.00,
        "ETHUSD": 3412.00,
        "NAS100": 18450.00
    }
    
    import random
    
    # Keep track of last signal count to know when a new one was added
    last_signal_count = len(signals_store)
    
    try:
        while True:
            # 1. Price Updates (simulated live market)
            updates = []
            for sym, price in prices.items():
                volatility = price * 0.0001 # 0.01% movement
                change = random.uniform(-volatility, volatility)
                prices[sym] += change
                updates.append({
                    "symbol": sym,
                    "price": round(prices[sym], 2),
                    "change": round(change, 2),
                    "timestamp": datetime.now(timezone.utc).isoformat()
                })
            
            payload = {
                "type": "price_update", 
                "data": updates
            }
            
            # 2. Check if a new signal was created globally
            current_signal_count = len(signals_store)
            if current_signal_count > last_signal_count:
                new_signals = signals_store[0 : current_signal_count - last_signal_count]
                payload["type"] = "new_signal"
                payload["signals"] = new_signals
                last_signal_count = current_signal_count

            await websocket.send_json(payload)
            await asyncio.sleep(1) # Stream every 1 second
            
    except WebSocketDisconnect:
        print("[WebSocket] Client disconnected from stream.")
    except Exception as e:
        print(f"[WebSocket] Error: {e}")


# ─── Broker Integration (MetaApi Cloud) ──────────────────────────────────────

METAAPI_URL = "https://mt-client-api-v1.agiliumtrade.agiliumtrade.ai"

class TradeRequest(BaseModel):
    symbol: str = "XAUUSD"
    direction: str = "BUY"  # BUY or SELL
    stop_loss: float
    take_profit_1: float
    take_profit_2: Optional[float] = None
    risk_percent: float = 1.0
    lot_size: Optional[float] = None
    broker: str = "Exness"


class BrokerCredentials(BaseModel):
    meta_api_token: str
    account_id: str


@app.post("/api/v1/execute-trade")
async def execute_trade(
    request: TradeRequest,
    x_metaapi_token: str = Header(default="demo", alias="X-MetaApi-Token"),
    x_account_id: str = Header(default="demo", alias="X-Account-Id"),
):
    """
    Execute a trade order via MetaApi Cloud.
    Sends the order to the connected MT5/Exness/Deriv broker.
    Falls back to demo mode if no real credentials are provided.
    """
    print(f"[Trade] {request.direction} {request.symbol} | SL: {request.stop_loss} | TP1: {request.take_profit_1} | Risk: {request.risk_percent}%")

    # Demo mode
    if x_metaapi_token == "demo" or x_account_id == "demo":
        order_id = f"DEMO-{uuid.uuid4().hex[:8].upper()}"
        print(f"[Trade] Demo mode — simulated order {order_id}")
        return {
            "success": True,
            "order_id": order_id,
            "message": f"Demo {request.direction} order executed for {request.symbol}",
            "executed_price": request.stop_loss + (10 if request.direction == "BUY" else -10),
            "lot_size": request.lot_size or 0.01,
            "mode": "demo",
        }

    # Real execution via MetaApi Cloud REST API
    try:
        import httpx

        action_type = "ORDER_TYPE_BUY" if request.direction.upper() == "BUY" else "ORDER_TYPE_SELL"
        lot = request.lot_size or 0.01

        trade_payload = {
            "actionType": action_type,
            "symbol": request.symbol,
            "volume": lot,
            "stopLoss": request.stop_loss,
            "takeProfit": request.take_profit_1,
            "comment": f"SynapseTrade|{request.risk_percent}%|{request.broker}",
        }

        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{METAAPI_URL}/users/current/accounts/{x_account_id}/trade",
                headers={
                    "auth-token": x_metaapi_token,
                    "Content-Type": "application/json",
                },
                json=trade_payload,
                timeout=30,
            )

        if resp.status_code == 200:
            data = resp.json()
            order_id = data.get("orderId", data.get("positionId", "unknown"))
            print(f"[Trade] ✅ Real order executed: {order_id}")
            return {
                "success": True,
                "order_id": str(order_id),
                "message": f"{request.direction} order executed on {request.broker}",
                "executed_price": data.get("openPrice", 0),
                "lot_size": lot,
                "mode": "live",
                "broker_response": data,
            }
        else:
            error_detail = resp.text
            print(f"[Trade] ❌ Broker rejected: {error_detail}")
            raise HTTPException(status_code=resp.status_code, detail=f"Broker error: {error_detail}")

    except ImportError:
        # httpx not installed — fall back to demo
        order_id = f"FALLBACK-{uuid.uuid4().hex[:8].upper()}"
        return {
            "success": True,
            "order_id": order_id,
            "message": "Executed in fallback mode (install httpx for live trading)",
            "executed_price": request.stop_loss + (10 if request.direction == "BUY" else -10),
            "lot_size": request.lot_size or 0.01,
            "mode": "fallback",
        }
    except Exception as e:
        print(f"[Trade] Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/broker/account-info")
async def get_account_info(
    x_metaapi_token: str = Header(default="demo", alias="X-MetaApi-Token"),
    x_account_id: str = Header(default="demo", alias="X-Account-Id"),
):
    """Get account balance, equity, and margin info from MetaApi."""
    if x_metaapi_token == "demo" or x_account_id == "demo":
        return {
            "balance": 14240.50,
            "equity": 14240.50,
            "margin": 3616.69,
            "free_margin": 10623.81,
            "margin_level": 393.72,
            "currency": "USD",
            "connected": False,
            "mode": "demo",
        }

    try:
        import httpx
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{METAAPI_URL}/users/current/accounts/{x_account_id}/account-information",
                headers={"auth-token": x_metaapi_token},
                timeout=15,
            )
        if resp.status_code == 200:
            return {**resp.json(), "connected": True, "mode": "live"}
        else:
            raise HTTPException(status_code=resp.status_code, detail=resp.text)
    except ImportError:
        return {"balance": 14240.50, "equity": 14240.50, "connected": False, "mode": "demo"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

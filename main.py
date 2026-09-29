from fastapi import FastAPI, Response
from fastapi.middleware.cors import CORSMiddleware
from concurrent.futures import ThreadPoolExecutor
import threading
import json
import urllib.request
import ssl
import time
import pandas as pd
import numpy as np

app = FastAPI(title="NSE Stock Screener API")

# Enable CORS for all origins, methods, and headers
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

LATEST_STOCK_DATA = []
IS_INITIALIZED = False

# Stock List
NSE_TICKERS = [
    "63MOONS.NS", "AAATECH.NS", "ABCAPITAL.NS", "ABINFRA.NS", "ADANIPORTS.NS", "ADANIPOWER.NS", 
    "ANANTRAJ.NS", "APARINDS.NS", "APLAPOLLO.NS", "APOLLO.NS", "AQYLON.NS", "ARIHANT.NS", 
    "ARVEE.NS", "ASAHIINDIA.NS", "ASHOKLEY.NS", "ASTERDM.NS", "ASTRAMICRO.NS", "BANARBEADS.NS", 
    "BANCOINDIA.NS", "BANKBARODA.NS", "BBOX.NS", "BDL.NS", "BEL.NS", "BHAGYANGR.NS", 
    "BHARATFORG.NS", "BHARTIARTL.NS", "BHEL.NS", "BOSCHLTD.NS", "CANBK.NS", "CAPLIPOINT.NS", 
    "CASTROLIND.NS", "CCL.NS", "CEATLTD.NS", "CEMPRO.NS", "CENTUM.NS", "CGPOWER.NS", 
    "COALINDIA.NS", "COCHINSHIP.NS", "CUBEXTUB.NS", "CUMMINSIND.NS", "CUPID.NS", "DIAMONDYD.NS", 
    "DYNAMATECH.NS", "EASTSILK.NS", "EICHERMOT.NS", "ESABINDIA.NS", "ESCORTS.NS", "FEDERALBNK.NS", 
    "FIEMIND.NS", "FOSECOIND.NS", "GABRIEL.NS", "GALLANTT.NS", "GESHIP.NS", "GFSTEELS.NS", 
    "GODFRYPHLP.NS", "GOKULAGRO.NS", "GOODLUCK.NS", "GPPL.NS", "GRASIM.NS", "GRSE.NS", 
    "GVT&D.NS", "HAL.NS", "HBLENGINE.NS", "HCG.NS", "HDFCBANK.NS", "HECPROJECT.NS", 
    "HINDZINC.NS", "HIRECT.NS", "HSCL.NS", "HUDCO.NS", "ICICIBANK.NS", "IDBI.NS", 
    "IMFA.NS", "INDIACEM.NS", "INDIANB.NS", "INDNIPPON.NS", "INDOTECH.NS", "INDSWFTLAB.NS", 
    "IOC.NS", "IZMO.NS", "JAYNECOIND.NS", "JINDALPHOT.NS", "JINDALSTEL.NS", "JPOLYINVST.NS", 
    "JSL.NS", "JSWHL.NS", "JSWSTEEL.NS", "KARURVYSYA.NS", "KDDL.NS", "KEI.NS", 
    "KERNEX.NS", "KEYFINSERV.NS", "KHAITANLTD.NS", "KINGFA.NS", "KIRLOSBROS.NS", "KIRLOSENG.NS", 
    "KOVAI.NS", "LEMONTREE.NS", "LGBBROSLTD.NS", "LLOYDSENGG.NS", "LT.NS", "LTFOODS.NS", 
    "LUMAXTECH.NS", "M&M.NS", "MAHABANK.NS", "MAHSCOOTER.NS", "MANAKCOAT.NS", "MANAKSTEEL.NS", 
    "MANINDS.NS", "MARICO.NS", "MAZDOCK.NS", "MBAPL.NS", "MCX.NS", "MINDACORP.NS", 
    "MPSLTD.NS", "MRPL.NS", "NAVA.NS", "NDRAUTO.NS", "NESCO.NS", "NEULANDLAB.NS", 
    "NH.NS", "NHPC.NS", "NORBTEAEXP.NS", "NTPC.NS", "OIL.NS", "ONGC.NS", 
    "PASHUPATI.NS", "PENIND.NS", "PFOCUS.NS", "PGEL.NS", "PGIL.NS", "PHOENIXLTD.NS", 
    "PIDILITIND.NS", "PNB.NS", "PNBHOUSING.NS", "POCL.NS", "POLYCAB.NS", "POWERINDIA.NS", 
    "PRECWIRE.NS", "PREMEXPLN.NS", "PREMIERPOL.NS", "PRICOLLTD.NS", "PVP.NS", "RADICO.NS", 
    "REDINGTON.NS", "REFEX.NS", "ROHLTD.NS", "RPGLIFE.NS", "SALSTEEL.NS", "SARDAEN.NS", 
    "SBIN.NS", "SCHAEFFLER.NS", "SCI.NS", "SHAKTIPUMP.NS", "SHRIPISTON.NS", "SHRIRAMFIN.NS", 
    "SIGMAADV.NS", "SMLMAH.NS", "SOLARINDS.NS", "SOMATEX.NS", "STEL.NS", "STLTECH.NS", 
    "SUNDARMFIN.NS", "SUNFLAG.NS", "SUVEN.NS", "SVLL.NS", "SWARAJENG.NS", "TALBROAUTO.NS", 
    "TARACHAND.NS", "TARIL.NS", "TATAINVEST.NS", "TATASTEEL.NS", "TBZ.NS", "TDPOWERSYS.NS", 
    "TEAMGTY.NS", "TFCILTD.NS", "THANGAMAYL.NS", "THOMASCOTT.NS", "TI.NS", "TIPSMUSIC.NS", 
    "TSFINV.NS", "TVSHLTD.NS", "TVSMOTOR.NS", "UNIONBANK.NS", "UNIVCABLES.NS", "UNOMINDA.NS", 
    "USHAMART.NS", "V2RETAIL.NS", "VADILALIND.NS", "VEDL.NS", "VENUSREM.NS", "VIMTALABS.NS", 
    "VISHNU.NS", "VOLTAMP.NS", "VSSL.NS", "WEBELSOLAR.NS", "WELCORP.NS", "WELENT.NS", 
    "WELINV.NS", "ZENTEC.NS", "ZUARI.NS", "ZUARIIND.NS"
]


def fetch_stock_data(ticker, period_years=2):
    end_time = int(pd.Timestamp.now().timestamp())
    start_time = int((pd.Timestamp.now() - pd.Timedelta(days=period_years * 365)).timestamp())
    
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{ticker}?period1={start_time}&period2={end_time}&interval=1d"
    headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36'}
    
    try:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, context=ctx, timeout=8) as response:
            data = json.loads(response.read().decode('utf-8'))
            
        result = data['chart']['result'][0]
        timestamps = result['timestamp']
        indicators = result['indicators']['quote'][0]
        
        df = pd.DataFrame({
            'High': indicators.get('high'),
            'Low': indicators.get('low'),
            'Close': indicators.get('close'),
            'Volume': indicators.get('volume')
        }, index=pd.to_datetime(timestamps, unit='s'))
        
        df.dropna(subset=['Close'], inplace=True)
        df['Date'] = df.index.date
        df.drop_duplicates(subset=['Date'], keep='last', inplace=True)
        
        return df
    except Exception:
        return None


def fetch_hourly_rsi(ticker, days=60):
    end_time = int(pd.Timestamp.now().timestamp())
    start_time = int((pd.Timestamp.now() - pd.Timedelta(days=days)).timestamp())
    
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{ticker}?period1={start_time}&period2={end_time}&interval=1h"
    headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36'}
    
    try:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, context=ctx, timeout=8) as response:
            data = json.loads(response.read().decode('utf-8'))
            
        result = data['chart']['result'][0]
        timestamps = result['timestamp']
        indicators = result['indicators']['quote'][0]
        
        df_1h = pd.DataFrame({
            'Close': indicators.get('close')
        }, index=pd.to_datetime(timestamps, unit='s'))
        
        df_1h.dropna(subset=['Close'], inplace=True)
        if len(df_1h) < 15:
            return 0.0

        delta = df_1h['Close'].diff()
        gain = delta.clip(lower=0)
        loss = -delta.clip(upper=0)

        # Wilder's RMA RSI formula
        avg_gain = gain.ewm(alpha=1/14, min_periods=14, adjust=False).mean()
        avg_loss = loss.ewm(alpha=1/14, min_periods=14, adjust=False).mean()

        rs = avg_gain / avg_loss.replace(0, np.nan)
        rsi = 100 - (100 / (1 + rs))

        latest_rsi = rsi.iloc[-1]
        return round(latest_rsi, 2) if not pd.isna(latest_rsi) else 0.0
    except Exception:
        return 0.0


def calculate_trendlines(df, lookback=60):
    recent_df = df.tail(lookback)
    x = np.arange(len(recent_df))
    
    low_slope, low_intercept = np.polyfit(x, recent_df['Low'].values, 1)
    high_slope, high_intercept = np.polyfit(x, recent_df['High'].values, 1)

    support_tl = low_slope * x[-1] + low_intercept
    resistance_tl = high_slope * x[-1] + high_intercept

    if low_slope > 0.05 and high_slope > 0.05:
        pattern = "ASCENDING"
    elif low_slope < -0.05 and high_slope < -0.05:
        pattern = "DESCENDING"
    else:
        pattern = "SIDEWAYS"

    return round(support_tl, 2), round(resistance_tl, 2), pattern


def analyze_single_stock(ticker):
    df = fetch_stock_data(ticker)
    if df is None or len(df) < 100:
        return None

    today_close = round(df['Close'].iloc[-1], 2)
    yesterday_close = round(df['Close'].iloc[-2], 2)
    
    price_change_inr = round(today_close - yesterday_close, 2)
    daily_change_pct = round(((today_close - yesterday_close) / yesterday_close) * 100, 2)

    df['EMA_20'] = df['Close'].ewm(span=20, adjust=False).mean()
    df['EMA_50'] = df['Close'].ewm(span=50, adjust=False).mean()

    df_weekly = df['Close'].resample('W-FRI').last().to_frame()
    df_weekly['EMA_30W'] = df_weekly['Close'].ewm(span=30, adjust=False).mean()
    df = pd.merge_asof(df.sort_index(), df_weekly[['EMA_30W']].sort_index(), left_index=True, right_index=True, direction='backward')
    df['EMA_30W'] = df['EMA_30W'].ffill()

    rsi_1h = fetch_hourly_rsi(ticker)

    df['EMA_12'] = df['Close'].ewm(span=12, adjust=False).mean()
    df['EMA_26'] = df['Close'].ewm(span=26, adjust=False).mean()
    df['MACD'] = df['EMA_12'] - df['EMA_26']
    df['MACD_Signal'] = df['MACD'].ewm(span=9, adjust=False).mean()

    supp_tl, res_tl, channel_pattern = calculate_trendlines(df)

    latest = df.iloc[-1]

    ath_idx = df['High'].idxmax()
    ath_val = round(df['High'].max(), 2)
    ath_date_str = ath_idx.strftime('%Y-%m-%d') if pd.notnull(ath_idx) else "N/A"
    down_from_ath_pct = round(((ath_val - today_close) / ath_val) * 100, 2)

    ema_30w = round(latest['EMA_30W'], 2) if not pd.isna(latest['EMA_30W']) else 0.0

    score = 0
    macro_trend = "BULLISH" if today_close > ema_30w else "BEARISH"
    
    if today_close > ema_30w: score += 2
    else: score -= 2
    
    if latest['EMA_20'] > latest['EMA_50']: score += 1
    else: score -= 1
    
    if latest['MACD'] > latest['MACD_Signal']: score += 1
    else: score -= 1

    if today_close > res_tl: score += 2
    elif today_close < supp_tl: score -= 2

    if score >= 3: verdict = "STRONG BUY"
    elif 1 <= score <= 2: verdict = "BUY"
    elif score == 0: verdict = "HOLD"
    else: verdict = "AVOID"

    return {
        "Ticker": ticker.replace(".NS", ""),
        "Yesterday Close (INR)": yesterday_close,
        "Today Close (INR)": today_close,
        "Price Change (INR)": price_change_inr,
        "Daily Change %": daily_change_pct,
        "ATH Price": ath_val,
        "ATH Value": ath_val,
        "ATH Date": ath_date_str,
        "Down % from ATH": down_from_ath_pct,
        "30W Macro EMA": ema_30w,
        "Macro Trend": macro_trend,
        "1 HOUR RSI": rsi_1h,
        "Short Trend (EMA 20/50)": "BULLISH" if latest['EMA_20'] > latest['EMA_50'] else "BEARISH",
        "MACD Status": "BULLISH" if latest['MACD'] > latest['MACD_Signal'] else "BEARISH",
        "Channel Pattern": channel_pattern,
        "TL Support": supp_tl,
        "TL Resistance": res_tl,
        "Overall Score": score,
        "Signal Verdict": verdict,
        "Target Price": round(max(today_close * 1.10, res_tl * 1.05), 2),
        "Stop Loss": round(min(today_close * 0.95, supp_tl * 0.98), 2)
    }


def run_full_scan():
    global LATEST_STOCK_DATA, IS_INITIALIZED
    print("Starting background stock scan...")
    try:
        with ThreadPoolExecutor(max_workers=10) as executor:
            results = list(executor.map(analyze_single_stock, NSE_TICKERS))
        
        cleaned = [r for r in results if r is not None]
        if cleaned:
            cleaned.sort(key=lambda x: x["Overall Score"], reverse=True)
            LATEST_STOCK_DATA = cleaned
            IS_INITIALIZED = True
            print(f"Scan complete! {len(cleaned)} stocks updated.")
    except Exception as e:
        print(f"Scan error encountered: {e}")


def background_loop():
    while True:
        run_full_scan()
        time.sleep(180)


# Start background scanner thread immediately upon app launch
threading.Thread(target=background_loop, daemon=True).start()


# FastAPI Endpoints
@app.get("/api/scan-all")
def scan_all_stocks(response: Response):
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Access-Control-Allow-Origin"] = "*"
    
    # Non-blocking return: serves available cached data instantly without hitting HTTP timeout
    return {
        "status": "success", 
        "data": LATEST_STOCK_DATA,
        "is_ready": IS_INITIALIZED
    }


@app.get("/api/stock/{ticker}")
def scan_single(ticker: str):
    data = analyze_single_stock(f"{ticker.upper()}.NS")
    if data:
        return {"status": "success", "data": data}
    return {"status": "error", "message": "Stock data unavailable"}